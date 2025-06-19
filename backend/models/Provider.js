const mongoose = require('mongoose');

const ProviderSchema = new mongoose.Schema({
  role: { type: String, default: 'provider' }, // 👈 Thêm dòng này
  company_name: String,
  email: { type: String, unique: true },
  phone: String,
  password: String,
  address: String,
  service_types: [String],
  status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED'], default: 'PENDING' }
}, { timestamps: true });

module.exports = mongoose.model('Provider', ProviderSchema);
