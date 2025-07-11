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

