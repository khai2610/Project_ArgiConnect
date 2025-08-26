const Invoice = require('../../models/Invoice');
const ServiceRequest = require('../../models/ServiceRequest');
const Provider = require('../../models/Provider');

// POST /api/provider/invoices
exports.createInvoice = async (req, res) => {
  try {
    const providerId = req.user.id;
    const { request_id, note } = req.body;

    const request = await ServiceRequest.findById(request_id);
    if (!request) return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });

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
      const matched = provider.services.find(s => s.name === request.service_type);
      if (matched && matched.price) {
        total_amount = matched.price * request.area_ha;
      }
    }

    if (total_amount === 0) {
      return res.status(400).json({ message: 'Không xác định được đơn giá dịch vụ để lập hóa đơn' });
    }

    const invoice = await Invoice.create({
      service_request_id: request._id,
      provider_id: providerId,
      farmer_id: request.farmer_id,
      total_amount,
      note,
      status: 'UNPAID'
    });

    request.payment_status = 'UNPAID';
    await request.save();

    // ✅ Populate để response có đủ avatar nông dân & thông tin yêu cầu
    const populated = await Invoice.findById(invoice._id)
      .populate({ path: 'farmer_id', select: 'name email phone avatar' })
      .populate({ path: 'service_request_id', select: 'service_type status preferred_date result' });

    res.status(201).json({ message: 'Lập hóa đơn thành công', invoice: populated });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// GET /api/provider/invoices
exports.getProviderInvoices = async (req, res) => {
  try {
    const providerId = req.user.id;

    const invoices = await Invoice.find({ provider_id: providerId })
      // 👇 THÊM avatar vào select
      .populate({ path: 'farmer_id', select: 'name email phone avatar' })
      .populate({ path: 'service_request_id', select: 'service_type status preferred_date result' })
      .sort({ createdAt: -1 });

    res.json(invoices);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.updateInvoice = async (req, res) => {
  try {
    const providerId = req.user.id;
    const { id } = req.params;
    const { status } = req.body; // FE đang gửi { status: 'PAID' }

    const invoice = await Invoice.findById(id);
    if (!invoice) return res.status(404).json({ message: 'Không tìm thấy hóa đơn' });

    if (invoice.provider_id.toString() !== providerId) {
      return res.status(403).json({ message: 'Không có quyền cập nhật hóa đơn này' });
    }

    // chỉ cho phép PAID/UNPAID
    if (status && !['PAID', 'UNPAID'].includes(status)) {
      return res.status(400).json({ message: 'Trạng thái không hợp lệ' });
    }

    // cập nhật
    if (status) {
      invoice.status = status;
      invoice.paidAt = (status === 'PAID') ? new Date() : null;
    }

    await invoice.save();

    // đồng bộ về ServiceRequest.payment_status nếu có
    const reqDoc = await ServiceRequest.findById(invoice.service_request_id);
    if (reqDoc) {
      reqDoc.payment_status = (invoice.status === 'PAID') ? 'PAID' : 'UNPAID';
      await reqDoc.save();
    }

    const populated = await Invoice.findById(invoice._id)
      .populate({ path: 'farmer_id', select: 'name email phone avatar' })
      .populate({ path: 'service_request_id', select: 'service_type status preferred_date result' });

    res.json({ message: 'Cập nhật hóa đơn thành công', invoice: populated });
  } catch (err) {
    console.error('updateInvoice error:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
