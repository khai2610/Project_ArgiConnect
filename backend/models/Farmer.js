const mongoose = require('mongoose');

const FarmerSchema = new mongoose.Schema({
  role: { type: String, default: 'farmer' }, // 👈 Thêm dòng này
  name: String,
  email: { type: String, unique: true },
  phone: String,
  password: String,
  location: {
    province: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  }
}, { timestamps: true });

module.exports = mongoose.model('Farmer', FarmerSchema);
