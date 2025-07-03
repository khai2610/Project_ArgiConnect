const mongoose = require('mongoose');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
dotenv.config();

const User = require('../models/User');

async function seedAdmin() {
  await mongoose.connect(process.env.MONGO_URI);

  const email = 'admin@example.com';
  const plainPassword = '123456';

  const existing = await User.findOne({ email });
  if (existing) {
    console.log('⚠️ Admin đã tồn tại');
    return process.exit(0);
  }

  const hashed = await bcrypt.hash(plainPassword, 10);
  const admin = new User({
    email,
    password: hashed,
    role: 'admin',
    name: 'Admin Master'
  });

  await admin.save();

  const token = jwt.sign({ id: admin._id, role: 'admin' }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });

  console.log('✅ Đã tạo admin:');
  console.log('Email:', email);
  console.log('Password:', plainPassword);
  console.log('Token:', token);

  process.exit(0);
}

seedAdmin();
