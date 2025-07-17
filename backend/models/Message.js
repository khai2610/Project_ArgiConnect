const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  sender_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  sender_role: { type: String, enum: ['farmer', 'provider'], required: true },
  receiver_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  receiver_role: { type: String, enum: ['farmer', 'provider'], required: true },

  // 👇 request_id giờ là optional
  request_id: { type: mongoose.Schema.Types.ObjectId, ref: 'ServiceRequest', required: false,default: null },

  content: { type: String, required: true },
  action: { type: Object, default: null },
  read: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Message', MessageSchema);
