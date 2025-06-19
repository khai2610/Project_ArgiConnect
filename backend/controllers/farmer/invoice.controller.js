const Invoice = require('../../models/Invoice');

exports.getFarmerInvoices = async (req, res) => {
  try {
    const farmerId = req.user.id;

    const invoices = await Invoice.find({ farmer_id: farmerId })
      .populate('provider_id', 'company_name email phone')
      .populate('service_request_id', 'service_type status preferred_date')
      .sort({ created_at: -1 });

    res.json(invoices);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
