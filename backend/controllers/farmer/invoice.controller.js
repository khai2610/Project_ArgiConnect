const Invoice = require('../../models/Invoice');
const ServiceRequest = require('../../models/ServiceRequest');

exports.getFarmerInvoices = async (req, res) => {
  try {
    const farmerId = req.user.id;

    const invoices = await Invoice.find({ farmer_id: farmerId })
      .populate('provider_id', 'company_name email phone')
      .populate('service_request_id', 'service_type status preferred_date')
      .populate('farmer_id', 'name email phone') // ✅ thêm dòng này
      .sort({ createdAt: -1 });

    res.json(invoices);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};


exports.payInvoice = async (req, res) => {
  try {
    const farmerId = req.user.id;
    const invoiceId = req.params.id;

    const invoice = await Invoice.findById(invoiceId);
    if (!invoice) {
      return res.status(404).json({ message: 'Không tìm thấy hóa đơn' });
    }

    if (invoice.farmer_id.toString() !== farmerId) {
      return res.status(403).json({ message: 'Bạn không có quyền thanh toán hóa đơn này' });
    }

    // ✅ Cập nhật trạng thái và thời gian thanh toán
    invoice.status = 'PAID';
    invoice.paidAt = new Date(); // thêm dòng này
    await invoice.save();

    // ✅ Đồng bộ trạng thái thanh toán cho yêu cầu
    const request = await ServiceRequest.findById(invoice.service_request_id);
    if (request) {
      request.payment_status = 'PAID';
      await request.save();
    }

    // ✅ Lấy lại hóa đơn đã populate để trả về
    const updatedInvoice = await Invoice.findById(invoice._id)
      .populate('provider_id', 'company_name email phone')
      .populate('farmer_id', 'name email phone')
      .populate('service_request_id', 'service_type preferred_date status');

    return res.json({
      message: 'Thanh toán thành công',
      invoice: updatedInvoice,
    });
  } catch (err) {
    console.error('Lỗi khi thanh toán:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};


exports.getInvoiceById = async (req, res) => {
  try {
    const farmerId = req.user.id;
    const invoiceId = req.params.id;

    const invoice = await Invoice.findById(invoiceId)
      .populate('provider_id', 'company_name email phone')
      .populate('service_request_id', 'service_type status preferred_date')
      .populate('farmer_id', 'name email phone');

    if (!invoice) {
      return res.status(404).json({ message: 'Không tìm thấy hóa đơn' });
    }

    if (invoice.farmer_id._id.toString() !== farmerId) {
      return res.status(403).json({ message: 'Bạn không có quyền xem hóa đơn này' });
    }

    res.json({ invoice });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};


