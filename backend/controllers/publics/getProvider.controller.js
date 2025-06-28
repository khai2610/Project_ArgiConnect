const Provider = require('../../models/Provider'); // đường dẫn có thể cần chỉnh tùy cấu trúc thư mục

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
