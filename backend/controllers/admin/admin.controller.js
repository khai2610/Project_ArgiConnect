const Provider = require('../../models/Provider');
const Farmer = require('../../models/Farmer');
const Invoice = require('../../models/Invoice');
const ServiceRequest = require('../../models/ServiceRequest');

// ✅ Lấy danh sách provider chờ duyệt
exports.getPendingProviders = async (req, res) => {
  try {
    const providers = await Provider.find({ status: 'PENDING' }).select('-password');
    res.json(providers);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Duyệt provider
exports.approveProvider = async (req, res) => {
  try {
    const provider = await Provider.findByIdAndUpdate(
      req.params.id,
      { status: 'APPROVED' },
      { new: true }
    ).select('-password');

    if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });

    res.json({ message: 'Duyệt thành công', provider });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Từ chối provider
exports.rejectProvider = async (req, res) => {
  try {
    const provider = await Provider.findByIdAndUpdate(
      req.params.id,
      { status: 'REJECTED' },
      { new: true }
    ).select('-password');

    if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });

    res.json({ message: 'Từ chối thành công', provider });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Lấy danh sách tất cả nông dân
exports.getAllFarmers = async (req, res) => {
  try {
    const farmers = await Farmer.find().select('-password');
    res.json(farmers);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Lấy danh sách tất cả provider
exports.getAllProviders = async (req, res) => {
  try {
    const providers = await Provider.find().select('-password');
    res.json(providers);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Lấy danh sách yêu cầu
exports.getAllRequests = async (req, res) => {
  try {
    const requests = await ServiceRequest.find()
      .populate('farmer_id', 'name email phone')
      .populate('provider_id', 'company_name email phone')
      .sort({ createdAt: -1 });

    res.json(requests);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Lấy danh sách hóa đơn
exports.getAllInvoices = async (req, res) => {
  try {
    const invoices = await Invoice.find()
      .populate('farmer_id', 'name email phone')
      .populate('provider_id', 'company_name email phone')
      .populate('service_request_id', 'service_type preferred_date status');

    res.json(invoices);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
