const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const path = require('path');

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

app.use('/api/farmer/requests', require('./routes/farmer/request.route'));
app.use('/api/farmer/invoices', require('./routes/farmer/invoice.route'));
app.use('/api/farmer/list-services', require('./routes/farmer/listService.route'));

app.use('/api/provider/requests', require('./routes/provider/request.route'));
app.use('/api/provider/invoices', require('./routes/provider/invoice.route'));
app.use('/api/provider/services', require('./routes/provider/service.route'));
app.use('/api/provider/stats', require('./routes/provider/stats.route'));


app.use('/api/public', require('./routes/public/public.route'));

app.use('/api/admin', require('./routes/admin/admin.route'));

app.use('/api/chat', require('./routes/chat.route'));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/payment', require('./routes/payment.route'));


module.exports = app;
