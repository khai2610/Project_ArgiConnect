const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRoutes = require('./middlewares/auth');
const farmerRoutes = require('./routes/farmer');
const providerRoutes = require('./routes/provider');
const adminRoutes = require('./routes/admin.routes');

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB connected'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/farmer', farmerRoutes);
app.use('/api/provider', providerRoutes);
app.use('/api/admin', adminRoutes);

module.exports = app;
