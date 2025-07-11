const mongoose = require('mongoose');
const ServiceRequest = require('../../models/ServiceRequest');
const Invoice = require('../../models/Invoice');

exports.getProviderStats = async (req, res) => {
  try {
    const range = req.query.range || 'month';
    const now = new Date();

    // Tính thời gian bắt đầu
    let start;
    if (range === 'week') {
      const day = now.getDay();
      start = new Date(now);
      start.setDate(now.getDate() - day);
    } else if (range === 'month') {
      start = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (range === 'year') {
      start = new Date(now.getFullYear(), 0, 1);
    }

    // Đảm bảo ObjectId
    const providerObjectId = new mongoose.Types.ObjectId(req.user.id);

    const aggregateByDate = async (Model, extraMatch = {}) => {
      return await Model.aggregate([
        {
          $match: {
            ...extraMatch,
            provider_id: providerObjectId,
            createdAt: { $gte: start, $lte: now }
          }
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format:
                  range === 'week' ? '%w' :
                  range === 'month' ? '%d' :
                  '%m',
                date: '$createdAt'
              }
            },
            count: { $sum: 1 }
          }
        }
      ]);
    };

    const [reqAgg, invAgg, paidAgg] = await Promise.all([
      aggregateByDate(ServiceRequest),
      aggregateByDate(Invoice),
      aggregateByDate(Invoice, { status: 'PAID' })
    ]);

    // Tạo nhãn
    let labels = [];
    if (range === 'week') {
      labels = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    } else if (range === 'month') {
      const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
      labels = Array.from({ length: days }, (_, i) => `${i + 1}`);
    } else if (range === 'year') {
      labels = Array.from({ length: 12 }, (_, i) => `Tháng ${i + 1}`);
    }

    // Mapping dữ liệu theo index
    const mapToDataset = (agg, range) => {
      const map = {};
      agg.forEach(item => {
        let i = parseInt(item._id, 10);
        if (range === 'week') i = i % 7;
        else if (range === 'month' || range === 'year') i = i - 1;

        if (!isNaN(i) && i >= 0 && i < labels.length) {
          map[i] = item.count;
        }
      });

      return Array.from({ length: labels.length }, (_, i) => map[i] || 0);
    };

    // Đếm tổng
    const [requests, invoices, paidInvoices] = await Promise.all([
      ServiceRequest.countDocuments({ provider_id: providerObjectId, createdAt: { $gte: start, $lte: now } }),
      Invoice.countDocuments({ provider_id: providerObjectId, createdAt: { $gte: start, $lte: now } }),
      Invoice.countDocuments({ provider_id: providerObjectId, status: 'PAID', createdAt: { $gte: start, $lte: now } })
    ]);

    // Kết quả biểu đồ
    const chart = {
      labels,
      datasets: [
        {
          label: 'Yêu cầu',
          data: mapToDataset(reqAgg, range),
          backgroundColor: '#38bdf8'
        },
        {
          label: 'Hóa đơn',
          data: mapToDataset(invAgg, range),
          backgroundColor: '#4ade80'
        },
        {
          label: 'Thanh toán',
          data: mapToDataset(paidAgg, range),
          backgroundColor: '#facc15'
        }
      ]
    };

    res.json({
      summary: { requests, invoices, paidInvoices },
      chart
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
