const ServiceRequest = require('../../models/ServiceRequest');
const Provider = require('../../models/Provider');
const Invoice = require('../../models/Invoice');

exports.createRequest = async (req, res) => {
  try {
    const farmerId = req.user.id;
    const {
      provider_id,
      field_location,
      crop_type,
      area_ha,
      service_type,
      preferred_date
    } = req.body;

    let validProvider = null;

    // Nếu người dùng có chỉ định provider
    if (provider_id) {
      validProvider = await Provider.findOne({ _id: provider_id, status: 'APPROVED' });
      if (!validProvider) {
        return res.status(400).json({ message: 'Nhà cung cấp không hợp lệ hoặc chưa được duyệt' });
      }
    }

    const request = new ServiceRequest({
      farmer_id: farmerId,
      provider_id: validProvider ? validProvider._id : null,
      field_location,
      crop_type,
      area_ha,
      service_type,
      preferred_date
    });

    await request.save();
    res.status(201).json({
      message: validProvider
        ? 'Gửi yêu cầu đến nhà cung cấp thành công'
        : 'Gửi yêu cầu tự do thành công',
      request
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};


exports.getMyRequests = async (req, res) => {
    try {
      const farmerId = req.user.id;
  
      const requests = await ServiceRequest.find({ farmer_id: farmerId })
        .populate('provider_id', 'company_name email phone') // nếu có provider
        .sort({ createdAt: -1 });
  
      res.json(requests);
    } catch (err) {
      res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
  };

  exports.updateRequest = async (req, res) => {
    try {
      const farmerId = req.user.id;
      const requestId = req.params.id;
  
      const request = await ServiceRequest.findOne({ _id: requestId, farmer_id: farmerId });
      if (!request) return res.status(404).json({ message: 'Yêu cầu không tồn tại' });
  
      if (request.status !== 'PENDING') {
        return res.status(400).json({ message: 'Không thể chỉnh sửa yêu cầu đã xử lý' });
      }
  
      const updateFields = req.body; // Ví dụ: { area_ha: 3.0 }
      Object.assign(request, updateFields);
  
      await request.save();
      res.json({ message: 'Cập nhật yêu cầu thành công', request });
    } catch (err) {
      res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
  };
  
  exports.cancelRequest = async (req, res) => {
    try {
      const farmerId = req.user.id;
      const requestId = req.params.id;
  
      const request = await ServiceRequest.findOne({ _id: requestId, farmer_id: farmerId });
      if (!request) return res.status(404).json({ message: 'Yêu cầu không tồn tại' });
  
      if (request.status !== 'PENDING') {
        return res.status(400).json({ message: 'Không thể huỷ yêu cầu đã xử lý' });
      }
  
      await ServiceRequest.findByIdAndDelete(requestId);
      res.json({ message: 'Huỷ yêu cầu thành công' });
    } catch (err) {
      res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
  };

  exports.rateRequest = async (req, res) => {
    try {
      const farmerId = req.user.id;
      const requestId = req.params.id;
      const { rating, comment } = req.body;
  
      const request = await ServiceRequest.findOne({
        _id: requestId,
        farmer_id: farmerId
      });
  
      if (!request) {
        return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
      }
  
      if (request.status !== 'COMPLETED' || request.payment_status !== 'PAID') {
        return res.status(400).json({ message: 'Chỉ được đánh giá sau khi hoàn thành và thanh toán' });
      }
  
      if (request.rating !== null) {
        return res.status(400).json({ message: 'Yêu cầu này đã được đánh giá' });
      }
  
      request.rating = rating;
      request.comment = comment || '';
      await request.save();
  
      res.json({ message: 'Đánh giá thành công', request });
    } catch (err) {
      res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
  };
  
  exports.payRequest = async (req, res) => {
    try {
      const farmerId = req.user.id;
      const requestId = req.params.id;
  
      // Tìm request
      const request = await ServiceRequest.findOne({
        _id: requestId,
        farmer_id: farmerId
      });
  
      if (!request) {
        return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
      }
  
      if (request.status !== 'COMPLETED') {
        return res.status(400).json({ message: 'Chỉ thanh toán được khi yêu cầu đã hoàn thành' });
      }
  
      if (request.payment_status === 'PAID') {
        return res.status(400).json({ message: 'Yêu cầu này đã được thanh toán' });
      }
  
      // Cập nhật trạng thái thanh toán trong request
      request.payment_status = 'PAID';
      await request.save();
  
      // Nếu có hóa đơn tương ứng → cập nhật luôn
      await Invoice.findOneAndUpdate(
        { service_request_id: request._id },
        { status: 'PAID' }
      );
  
      res.json({ message: 'Thanh toán thành công', request });
    } catch (err) {
      res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
  };

  exports.resendRequest = async (req, res) => {
  try {
    const farmerId = req.user.id;
    const requestId = req.params.id;

    const request = await ServiceRequest.findOne({
      _id: requestId,
      farmer_id: farmerId
    });

    if (!request) {
      return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
    }

    if (request.status !== 'REJECTED') {
      return res.status(400).json({ message: 'Chỉ có thể gửi lại yêu cầu đã bị từ chối' });
    }

    request.status = 'PENDING';
    request.provider_id = null; // ✅ mở lại tự do cho tất cả providers (tuỳ chọn)
    await request.save();

    res.json({ message: 'Gửi lại yêu cầu thành công', request });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
