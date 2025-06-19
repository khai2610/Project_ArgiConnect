const jwt = require('jsonwebtoken');

exports.generateToken = (userId, role) => {
  return jwt.sign({ id: userId, role }, process.env.JWT_SECRET, {
    expiresIn: '7d'
  });
};
