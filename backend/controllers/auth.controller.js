const Farmer = require('../models/Farmer');
const Provider = require('../models/Provider');
const User = require('../models/User');

const { hashPassword, comparePassword } = require('../middlewares/shared/hashPassword');
const { generateToken } = require('../middlewares/shared/generateToken');

// ✅ Đăng ký cho farmer hoặc provider
exports.register = async (req, res) => {
  try {
    const { role, email, password } = req.body;

    if (!['farmer', 'provider'].includes(role)) {
      return res.status(400).json({ message: 'Role không hợp lệ (chỉ cho farmer/provider)' });
    }

    const existing = await (role === 'farmer' ? Farmer : Provider).findOne({ email });
    if (existing) return res.status(400).json({ message: 'Email đã được sử dụng' });

    const hashed = await hashPassword(password);

    if (role === 'farmer') {
      const { name, phone, location } = req.body;

      const farmer = new Farmer({
        name,
        email,
        phone,
        password: hashed,
        location,
        role: 'farmer'
      });

      await farmer.save();
      return res.status(201).json({ message: 'Đăng ký farmer thành công' });
    }

    if (role === 'provider') {
      const { company_name, phone, address } = req.body;

      const provider = new Provider({
        company_name,
        email,
        phone,
        password: hashed,
        address,
        services: [],
        role: 'provider'
      });

      await provider.save();
      return res.status(201).json({ message: 'Đăng ký provider thành công, chờ admin duyệt' });
    }

  } catch (err) {
    return res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

// ✅ Đăng nhập cho tất cả các loại tài khoản
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!['farmer', 'provider', 'admin'].includes(role)) {
      return res.status(400).json({ message: 'Role không hợp lệ' });
    }

    // ✅ Admin login
    if (role === 'admin') {
      const user = await User.findOne({ email });
      if (!user) return res.status(404).json({ message: 'Tài khoản admin không tồn tại' });

      const isMatch = await comparePassword(password, user.password);
      if (!isMatch) return res.status(401).json({ message: 'Sai mật khẩu' });

      const token = generateToken(user._id, 'admin');
      return res.status(200).json({
        message: 'Đăng nhập admin thành công',
        token,
        role: 'admin',
        user: {
          id: user._id,
          name: user.name,
          email: user.email
        }
      });
    }

    // ✅ Farmer hoặc Provider
    const Model = role === 'farmer' ? Farmer : Provider;
    const user = await Model.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Tài khoản không tồn tại' });

    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Sai mật khẩu' });

    if (role === 'provider' && user.status !== 'APPROVED') {
      return res.status(403).json({ message: 'Tài khoản provider chưa được duyệt' });
    }

    const token = generateToken(user._id, role);
    return res.status(200).json({
      message: 'Đăng nhập thành công',
      token,
      role,
      user: {
        id: user._id,
        name: user.name || user.company_name,
        email: user.email
      }
    });

  } catch (err) {
    return res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
