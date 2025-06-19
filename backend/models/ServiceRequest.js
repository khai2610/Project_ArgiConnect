const mongoose = require('mongoose');

const ServiceRequestSchema = new mongoose.Schema({
  farmer_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Farmer' },
  provider_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Provider', default: null },

  field_location: {
    province: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },

  crop_type: String,
  area_ha: Number,

  service_type: { type: String }, // VD: "PHUN_THUOC", "KHẢO_SÁT"
  preferred_date: Date,

  status: {
    type: String,
    enum: ['PENDING', 'ACCEPTED', 'REJECTED', 'COMPLETED'],
    default: 'PENDING'
  },

  payment_status: {
    type: String,
    enum: ['UNPAID', 'PAID'],
    default: 'UNPAID'
  },

  rating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  comment: {
    type: String,
    default: ''
  },
  
  result: {
    description: String,
    attachments: [String] // URL ảnh/video kết quả (nếu có)
  }
}, { timestamps: true });

module.exports = mongoose.model('ServiceRequest', ServiceRequestSchema);
