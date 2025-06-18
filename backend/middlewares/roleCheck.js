module.exports = function checkRole(requiredRole) {
    return (req, res, next) => {
      if (!req.user || req.user.role !== requiredRole) {
        return res.status(403).json({ message: 'Không có quyền truy cập' });
      }
      next();
    };
  };
  