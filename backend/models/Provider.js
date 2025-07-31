const mongoose = require('mongoose');

const ProviderSchema = new mongoose.Schema(
  {
    role: { type: String, default: 'provider' },
    company_name: String,
    email: { type: String, unique: true },
    phone: String,
    password: String,
    address: String,
    location: {
      province: String,
      coordinates: {
        lat: Number,
        lng: Number,
      },
    },
    services: [
      {
        name: { type: String, required: true },
        description: String,
        price: Number, // 💰 Giá dịch vụ
        unit: { type: String, default: 'VNĐ/ha' }, // 🧮 Đơn vị tính
      },
    ],
    status: {
      type: String,
      enum: ['PENDING', 'APPROVED', 'REJECTED'],
      default: 'PENDING',
    },
    avatar: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Provider', ProviderSchema);
