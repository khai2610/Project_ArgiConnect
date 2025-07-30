const Provider = require('../../models/Provider'); // đường dẫn có thể cần chỉnh tùy cấu trúc thư mục
const ServiceRequest = require('../../models/ServiceRequest');

// GET /api/public/provider/:id/services
exports.getServicesByProviderId = async (req, res) => {
  try {
    const provider = await Provider.findById(req.params.id).select('services');
    if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });
    res.json(provider.services);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// GET /api/public/provider/:id
exports.getProviderInfoById = async (req, res) => {
  try {
    const provider = await Provider.findById(req.params.id).select('-password');
    if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });
    res.json(provider);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.getProviderRatings = async (req, res) => {
  try {
    const providerId = req.params.id;

    const ratings = await ServiceRequest.find({
      provider_id: providerId,
      status: 'COMPLETED',
      payment_status: 'PAID',
      rating: { $ne: null }
    })
      .sort({ updatedAt: -1 })
      .select('rating comment crop_type preferred_date');

    res.json(ratings);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi khi lấy đánh giá', error: err.message });
  }
};

// GET /api/public/providers → trả về tất cả nhà cung cấp công khai
exports.getAllPublicProviders = async (req, res) => {
  try {
    const providers = await Provider.find({ status: 'APPROVED' }).select('-password');
    res.json(providers);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
