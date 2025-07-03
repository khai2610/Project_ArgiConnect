const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  role: {
    type: String,
    enum: ['admin'],
    default: 'admin'
  },
  name: { type: String, default: 'Admin' }
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
