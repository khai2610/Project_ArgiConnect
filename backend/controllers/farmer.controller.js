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

exports.getFarmers = async (req, res) => {
  try {
    const { keyword = '', isActive } = req.query;

    const filter = { role: 'farmer' };
    if (keyword) {
      filter.name = { $regex: keyword, $options: 'i' };
    }
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const users = await User.find(filter).select('-passwordHash');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi lấy danh sách', error: err.message });
  }
};
