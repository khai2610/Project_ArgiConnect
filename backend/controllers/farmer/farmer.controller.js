const Farmer = require('../../models/Farmer');
const fs = require('fs');
const path = require('path');

exports.getProfile = async (req, res) => {
  try {
    const farmer = await Farmer.findById(req.user.id).select('-password');
    if (!farmer) return res.status(404).json({ message: 'Không tìm thấy tài khoản' });

    res.json(farmer);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, location } = req.body;

    const updated = await Farmer.findByIdAndUpdate(
      req.user.id,
      { name, phone, location },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updated) {
      return res.status(404).json({ message: 'Không tìm thấy tài khoản' });
    }

    res.json({
      message: 'Cập nhật thành công',
      farmer: updated
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.updateAvatar = async (req, res) => {
  try {
    const { avatar } = req.body; // avatar có thể là URL đã upload

    if (!avatar) {
      return res.status(400).json({ message: 'Thiếu thông tin avatar' });
    }

    const updated = await Farmer.findByIdAndUpdate(
      req.user.id,
      { avatar },
      { new: true }
    ).select('-password');

    if (!updated) return res.status(404).json({ message: 'Không tìm thấy farmer' });

    res.json({ message: 'Cập nhật avatar thành công', farmer: updated });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'Không có file được tải lên' });

    const avatarUrl = `/uploads/avatars/${req.file.filename}`;

    // Xoá ảnh cũ nếu có
    const farmer = await Farmer.findById(req.user.id);
    if (farmer.avatar && farmer.avatar.startsWith('/uploads/avatars/')) {
      const oldPath = path.join(__dirname, '../../', farmer.avatar);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    const updated = await Farmer.findByIdAndUpdate(
      req.user.id,
      { avatar: avatarUrl },
      { new: true }
    ).select('-password');

    res.json({ message: 'Tải avatar thành công', avatar: avatarUrl, farmer: updated });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
