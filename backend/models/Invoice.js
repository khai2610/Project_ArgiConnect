const mongoose = require('mongoose');

const InvoiceSchema = new mongoose.Schema({
  service_request_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ServiceRequest',
    required: true,
    unique: true // mỗi request chỉ có 1 hóa đơn
  },
  provider_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Provider',
    required: true
  },
  farmer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Farmer',
    required: true
  },
  total_amount: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    default: 'VND'
  },
  note: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['UNPAID', 'PAID'],
    default: 'UNPAID'
  }
}, {
  timestamps: true // tạo createdAt, updatedAt tự động
});

module.exports = mongoose.model('Invoice', InvoiceSchema);
