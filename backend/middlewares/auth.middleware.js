const jwt = require('jsonwebtoken');

/**
 * Middleware xác thực JWT, hỗ trợ truyền 1 hoặc nhiều vai trò
 * @param {String|Array} requiredRole - 'farmer' | 'provider' | 'admin' | ['farmer', 'provider']
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

      if (requiredRole) {
        const roles = Array.isArray(requiredRole) ? requiredRole : [requiredRole];
        if (!roles.includes(decoded.role)) {
          return res.status(403).json({ message: `Không có quyền truy cập (${roles.join(', ')} only)` });
        }
      }

      req.user = decoded; // { id, role }
      req.role = decoded.role; // tiện cho xử lý
      next();
    } catch (err) {
      return res.status(401).json({ message: 'Token sai hoặc đã hết hạn' });
    }
  };
};
