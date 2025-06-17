const mongoose = require('mongoose');

const droneServiceSchema = new mongoose.Schema({
  providerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  serviceName: {
    type: String,
    required: true
  },
  description: {
    type: String
  },
  pricePerHa: {
    type: Number,
    required: true
  },
  availableAreas: [
    {
      type: String
    }
  ],
  images: [
    {
      type: String
    }
  ]
}, { timestamps: true });

module.exports = mongoose.model('DroneService', droneServiceSchema);
