const Invoice = require('../../models/Invoice');
const ServiceRequest = require('../../models/ServiceRequest');
const Provider = require('../../models/Provider'); // 👈 Đảm bảo đã import

exports.createInvoice = async (req, res) => {
  try {
    const providerId = req.user.id;
    const { request_id, note } = req.body;

    const request = await ServiceRequest.findById(request_id);
    if (!request) {
      return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
    }

    if (request.provider_id?.toString() !== providerId) {
      return res.status(403).json({ message: 'Không có quyền lập hóa đơn cho yêu cầu này' });
    }

    if (request.status !== 'COMPLETED') {
      return res.status(400).json({ message: 'Yêu cầu chưa hoàn thành' });
    }

    const existing = await Invoice.findOne({ service_request_id: request_id });
    if (existing) {
      return res.status(400).json({ message: 'Yêu cầu này đã có hóa đơn' });
    }

    // 🎯 Tự động tính total_amount
    const provider = await Provider.findById(providerId);
    let total_amount = 0;

    if (provider && Array.isArray(provider.services)) {
      const matched = provider.services.find(
        s => s.name === request.service_type
      );
      if (matched && matched.price) {
        total_amount = matched.price * request.area_ha;
      }
    }

    if (total_amount === 0) {
      return res.status(400).json({ message: 'Không xác định được đơn giá dịch vụ để lập hóa đơn' });
    }

    const invoice = new Invoice({
      service_request_id: request._id,
      provider_id: providerId,
      farmer_id: request.farmer_id,
      total_amount,
      note,
      status: 'UNPAID'
    });

    await invoice.save();

    request.payment_status = 'UNPAID';
    await request.save();

    res.status(201).json({ message: 'Lập hóa đơn thành công', invoice });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};



exports.getProviderInvoices = async (req, res) => {
  try {
    const providerId = req.user.id;

    const invoices = await Invoice.find({ provider_id: providerId })
      .populate('farmer_id', 'name email phone')
      .populate('service_request_id', 'service_type status preferred_date result') // 👈 thêm result
      .sort({ createdAt: -1 }); // bạn có thể sửa `created_at` → `createdAt`

    res.json(invoices);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

