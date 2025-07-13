// controllers/chat.controller.js
const mongoose = require('mongoose');
const Message = require('../models/Message');
const ServiceRequest = require('../models/ServiceRequest');
const Provider = require('../models/Provider');
const Farmer = require('../models/Farmer');

exports.getConversations = async (req, res) => {
  const { id: userId, role } = req.user;

  const messages = await Message.aggregate([
    {
      $match: {
        $or: [
          { sender_id: new mongoose.Types.ObjectId(userId) },
          { receiver_id: new mongoose.Types.ObjectId(userId) }
        ]
      }
    },
    {
      $sort: { createdAt: -1 }
    },
    {
      $group: {
        _id: {
          $cond: [
            { $eq: ["$sender_id", new mongoose.Types.ObjectId(userId)] },
            "$receiver_id",
            "$sender_id"
          ]
        },
        last_message: { $first: "$content" },
        updated_at: { $first: "$createdAt" }
      }
    }
  ]);

  const result = await Promise.all(messages.map(async (m) => {
    const partner = role === 'farmer'
      ? await Provider.findById(m._id).select('company_name')
      : await Farmer.findById(m._id).select('name');

    return {
      partner_id: m._id,
      partner_name: partner?.company_name || partner?.name || 'Đối tác',
      last_message: m.last_message,
      updated_at: m.updated_at,
      farmerId: role === 'farmer' ? userId : m._id,
      providerId: role === 'provider' ? userId : m._id
    };
  }));

  res.json(result);
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
    const { content } = req.body;

    const senderId = req.user.id;
    const senderRole = req.role;

    const receiverRole = senderRole === 'farmer' ? 'provider' : 'farmer';
    const receiverId = senderRole === 'farmer' ? providerId : farmerId;

    const message = new Message({
      sender_id: senderId,
      sender_role: senderRole,
      receiver_id: receiverId,
      receiver_role: receiverRole,
      content
    });

    await message.save();
    res.status(201).json({ message: 'Gửi tin nhắn thành công', data: message });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi gửi tin nhắn', error: err.message });
  }
};
