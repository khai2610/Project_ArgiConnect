const User = require('../models/User');

exports.getProfile = (req, res) => {
  res.json(req.user);
};

exports.updateProfile = async (req, res) => {
  try {
    const updated = await User.findByIdAndUpdate(req.user._id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi cập nhật', error: err.message });
  }
};

exports.getProviderByEmail = async (req, res) => {
    try {
      const { email } = req.query;
  
      if (!email) {
        return res.status(400).json({ message: 'Thiếu email' });
      }
  
      const provider = await User.findOne({ email, role: 'provider' }).select('-passwordHash');
  
      if (!provider) {
        return res.status(404).json({ message: 'Không tìm thấy provider' });
      }
  
      res.status(200).json(provider);
    } catch (err) {
      res.status(500).json({ message: 'Lỗi khi tìm provider', error: err.message });
    }
  };

exports.getProviders = async (req, res) => {
  try {
    const providers = await User.find({ role: 'provider', isActive: true }).select('-passwordHash');
    res.json(providers);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi tải danh sách', error: err.message });
  }
};
