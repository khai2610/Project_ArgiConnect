const Provider = require('../../models/Provider');

exports.getProfile = async (req, res) => {
  const provider = await Provider.findById(req.user.id).select('-password');
  if (!provider) return res.status(404).json({ message: 'Không tìm thấy tài khoản' });
  res.json(provider);
};

exports.updateProfile = async (req, res) => {
  const { company_name, phone, address, service_types, location } = req.body;

  const updated = await Provider.findByIdAndUpdate(
    req.user.id,
    { company_name, phone, address, service_types, location }, // 👈 thêm location
    { new: true, runValidators: true }
  ).select('-password');

  res.json({ message: 'Cập nhật thành công', provider: updated });
};

exports.updateAvatar = async (req, res) => {
  try {
    const { avatar } = req.body; // avatar có thể là URL hoặc base64 đã upload

    if (!avatar) {
      return res.status(400).json({ message: 'Thiếu thông tin avatar' });
    }

    const updated = await Provider.findByIdAndUpdate(
      req.user.id,
      { avatar },
      { new: true }
    ).select('-password');

    if (!updated) return res.status(404).json({ message: 'Không tìm thấy provider' });

    res.json({ message: 'Cập nhật avatar thành công', provider: updated });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'Không có file được tải lên' });

    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    const updated = await Provider.findByIdAndUpdate(
      req.user.id,
      { avatar: avatarUrl },
      { new: true }
    ).select('-password');

    res.json({ message: 'Tải avatar thành công', avatar: avatarUrl, provider: updated });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
