// controllers/chat.controller.js
const mongoose = require('mongoose');
const Message = require('../models/Message');
const ServiceRequest = require('../models/ServiceRequest');
const Provider = require('../models/Provider');
const Farmer = require('../models/Farmer');

exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const role = req.role;

    // Tìm các request mà user có tham gia (farmer hoặc provider)
    const matchField = role === 'farmer' ? 'farmer_id' : 'provider_id';
    const requests = await ServiceRequest.find({ [matchField]: userId });

    const requestIds = requests.map(r => r._id.toString());

    // Lấy tin nhắn mới nhất cho mỗi request_id
    const latestMessages = await Message.aggregate([
      { $match: { request_id: { $in: requestIds.map(id => new mongoose.Types.ObjectId(id)) } } },
      {
        $sort: { createdAt: -1 }
      },
      {
        $group: {
          _id: "$request_id",
          last_message: { $first: "$content" },
          updated_at: { $first: "$createdAt" }
        }
      }
    ]);

    // Lấy thêm thông tin người đối thoại
    const result = await Promise.all(latestMessages.map(async (item) => {
      const request = requests.find(r => r._id.toString() === item._id.toString());
      let partner = null;
      let partnerName = '';

      if (role === 'farmer') {
        partner = await Provider.findById(request.provider_id).select('company_name');
        partnerName = partner?.company_name || 'Nhà cung cấp';
      } else {
        partner = await Farmer.findById(request.farmer_id).select('name');
        partnerName = partner?.name || 'Nông dân';
      }

      return {
        request_id: item._id,
        partner_name: partnerName,
        last_message: item.last_message,
        updated_at: item.updated_at
      };
    }));

    res.json(result);
  } catch (err) {
    console.error('Lỗi getConversations:', err);
    res.status(500).json({ message: 'Lỗi lấy hội thoại', error: err.message });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { receiver_id, receiver_role, request_id, content } = req.body;
    const sender_id = req.user.id;
    const sender_role = req.role;

    const message = new Message({
      sender_id,
      sender_role,
      receiver_id,
      receiver_role,
      request_id,
      content
    });

    await message.save();
    res.status(201).json({ message: 'Gửi tin nhắn thành công', data: message });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi gửi tin nhắn', error: err.message });
  }
};

exports.getMessages = async (req, res) => {
  try {
    const { request_id } = req.params;

    const messages = await Message.find({ request_id })
      .sort({ createdAt: 1 });

    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi lấy tin nhắn', error: err.message });
  }
};

exports.getMessagesBetweenUsers = async (req, res) => {
  try {
    const { farmerId, providerId } = req.params;

    const messages = await Message.find({
      $or: [
        {
          sender_id: new mongoose.Types.ObjectId(farmerId),
          receiver_id: new mongoose.Types.ObjectId(providerId),
        },
        {
          sender_id: new mongoose.Types.ObjectId(providerId),
          receiver_id: new mongoose.Types.ObjectId(farmerId),
        },
      ]
    }).sort({ createdAt: 1 });

    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi lấy hội thoại', error: err.message });
  }
};

