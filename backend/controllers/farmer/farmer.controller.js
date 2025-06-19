const Farmer = require('../../models/Farmer');

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
    const farmerId = req.user.id;
    const { name, phone, location } = req.body;

    const updated = await Farmer.findByIdAndUpdate(
      farmerId,
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
