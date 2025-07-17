// controllers/chat.controller.js
const mongoose = require('mongoose');
const Message = require('../models/Message');
const ServiceRequest = require('../models/ServiceRequest');
const Provider = require('../models/Provider');
const Farmer = require('../models/Farmer');

exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;

    const messages = await Message.find({
      $or: [
        { sender_id: userId },
        { receiver_id: userId }
      ]
    }).sort({ createdAt: -1 });

    const seen = new Set();
    const result = [];

    for (const msg of messages) {
      const partnerId = msg.sender_id.toString() === userId
        ? msg.receiver_id.toString()
        : msg.sender_id.toString();

      if (seen.has(partnerId)) continue;
      seen.add(partnerId);

      const partner = role === 'provider'
        ? await Farmer.findById(partnerId).select('name')
        : await Provider.findById(partnerId).select('company_name');

      result.push({
        partner_id: partnerId,
        partner_name: partner?.name || partner?.company_name || '---',
        last_message: msg.content,
        updated_at: msg.createdAt,
        farmerId: role === 'provider' ? partnerId : userId,
        providerId: role === 'provider' ? userId : partnerId,
      });
    }

    res.json(result);
  } catch (err) {
    console.error('❌ Lỗi getConversations:', err);
    res.status(500).json({ message: 'Lỗi server' });
  }
};


exports.getMessagesBetweenUsers = async (req, res) => {
  const { farmerId, providerId } = req.params;

  const messages = await Message.find({
    $or: [
      { sender_id: farmerId, receiver_id: providerId },
      { sender_id: providerId, receiver_id: farmerId }
    ]
  }).sort({ createdAt: 1 });

  res.json(messages);
};


exports.sendMessageBetweenUsers = async (req, res) => {
  try {
    const { farmerId, providerId } = req.params;
    const { content, action } = req.body;

    const senderId = req.user.id;
    const senderRole = req.role;

    const receiverRole = senderRole === 'farmer' ? 'provider' : 'farmer';
    const receiverId = senderRole === 'farmer' ? providerId : farmerId;

    const message = new Message({
      sender_id: senderId,
      sender_role: senderRole,
      receiver_id: receiverId,
      receiver_role: receiverRole,
      content,
      action: action || null
    });

    await message.save();
    res.status(201).json({ message: 'Gửi tin nhắn thành công', data: message });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi gửi tin nhắn', error: err.message });
  }
};
