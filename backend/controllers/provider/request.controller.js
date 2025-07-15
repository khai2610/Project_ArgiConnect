const ServiceRequest = require('../../models/ServiceRequest');
const Invoice = require('../../models/Invoice');
exports.getAllRequests = async (req, res) => {
  try {
    const providerId = req.user.id;

    const requests = await ServiceRequest.find({
      $or: [
        { provider_id: providerId }, // chỉ định trực tiếp
        { provider_id: null }        // tự do
      ]
    })
      .populate('farmer_id', 'name email phone')
      .sort({ createdAt: -1 });

    res.json(requests);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.getProviderSummary = async (req, res) => {
  try {
    const providerId = req.user.id;

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    // ✅ Đếm số yêu cầu đã hoàn thành hôm nay
    const completedToday = await ServiceRequest.countDocuments({
      provider_id: providerId,
      status: 'COMPLETED',
      updatedAt: { $gte: startOfDay, $lte: endOfDay }
    });

    // ✅ Tính tổng doanh thu từ invoice đã thanh toán hôm nay
    const paidInvoices = await Invoice.find({
      provider_id: providerId,
      status: 'PAID',
      updatedAt: { $gte: startOfDay, $lte: endOfDay }
    });

    const revenueToday = paidInvoices.reduce((sum, inv) => sum + (inv.total_amount || 0), 0);

    res.json({
      completedToday,
      revenueToday
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.acceptRequest = async (req, res) => {
  try {
    const providerId = req.user.id;
    const requestId = req.params.id;

    const request = await ServiceRequest.findById(requestId);

    if (!request) {
      return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
    }

    if (request.status !== 'PENDING') {
      return res.status(400).json({ message: 'Yêu cầu đã được xử lý' });
    }

    // Nếu là yêu cầu chỉ định → chỉ provider được chỉ định mới được nhận
    if (request.provider_id && request.provider_id.toString() !== providerId) {
      return res.status(403).json({ message: 'Bạn không có quyền xử lý yêu cầu này' });
    }

    // Nếu là yêu cầu tự do (provider_id == null) → gán provider hiện tại
    if (!request.provider_id) {
      request.provider_id = providerId;
    }

    request.status = 'ACCEPTED';
    await request.save();

    res.json({ message: 'Đã chấp nhận yêu cầu thành công', request });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.completeRequest = async (req, res) => {
    try {
      const providerId = req.user.id;
      const requestId = req.params.id;
      const { description, attachments } = req.body;
  
      const request = await ServiceRequest.findById(requestId);
  
      if (!request) {
        return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
      }
  
      if (request.provider_id?.toString() !== providerId) {
        return res.status(403).json({ message: 'Bạn không có quyền xử lý yêu cầu này' });
      }
  
      if (request.status !== 'ACCEPTED') {
        return res.status(400).json({ message: 'Yêu cầu chưa được chấp nhận hoặc đã xử lý' });
      }
  
      request.status = 'COMPLETED';
      request.result = {
        description: description || '',
        attachments: attachments || []
      };
  
      await request.save();
  
      res.json({ message: 'Hoàn thành yêu cầu thành công', request });
    } catch (err) {
      res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
  };
  