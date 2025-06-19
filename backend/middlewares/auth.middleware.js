const jwt = require('jsonwebtoken');

/**
 * Middleware xác thực JWT, có thể truyền vào vai trò cần kiểm tra
 * @param {String} requiredRole - (tùy chọn) vai trò yêu cầu: 'farmer' | 'provider' | 'admin'
 */
exports.verifyToken = (requiredRole = null) => {
  return (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token không hợp lệ' });
    }

    const token = authHeader.split(' ')[1];

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      if (requiredRole && decoded.role !== requiredRole) {
        return res.status(403).json({ message: `Không có quyền truy cập (${requiredRole} only)` });
      }

      req.user = decoded; // { id, role }
      next();
    } catch (err) {
      return res.status(401).json({ message: 'Token sai hoặc đã hết hạn' });
    }
  };
};
