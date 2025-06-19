const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Kết nối MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB connected'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

// ROUTES

app.use('/api/auth', require('./routes/auth.route'));
app.use('/api/farmer', require('./routes/farmer/farmer.route.js')); 
app.use('/api/provider', require('./routes/provider/auth.route.js'));


module.exports = app;
