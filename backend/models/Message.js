// models/Message.js
const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  sender_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  sender_role: { type: String, enum: ['farmer', 'provider'], required: true },
  receiver_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  receiver_role: { type: String, enum: ['farmer', 'provider'], required: true },

  request_id: { type: mongoose.Schema.Types.ObjectId, ref: 'ServiceRequest' }, // liên kết với yêu cầu

  content: { type: String, required: true },
  read: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Message', MessageSchema);
