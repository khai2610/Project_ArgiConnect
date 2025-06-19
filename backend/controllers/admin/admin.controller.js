const User = require('../models/User');

// Lấy danh sách theo vai trò
exports.getUsersByRole = async (req, res) => {
  try {
    const { role } = req.params;
    const { keyword = '', isActive } = req.query;

    const filter = { role };
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

// Lấy chi tiết user theo ID
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id).select('-passwordHash');
    if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });

    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi truy vấn', error: err.message });
  }
};

// Cập nhật user
exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updated = await User.findByIdAndUpdate(id, req.body, { new: true }).select('-passwordHash');
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi cập nhật', error: err.message });
  }
};

// Xoá (soft delete hoặc hard delete)
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    // Cách 1: Hard delete
    await User.findByIdAndDelete(id);

    // Cách 2: Soft delete (nếu muốn dùng)
    // await User.findByIdAndUpdate(id, { isActive: false });

    res.json({ message: 'Xoá thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi xoá', error: err.message });
  }
};
