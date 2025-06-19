const bcrypt = require('bcrypt');

exports.hashPassword = async (plain) => {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(plain, salt);
};

exports.comparePassword = async (plain, hashed) => {
  return await bcrypt.compare(plain, hashed);
};
