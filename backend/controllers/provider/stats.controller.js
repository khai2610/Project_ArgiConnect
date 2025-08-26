const mongoose = require('mongoose');
const ServiceRequest = require('../../models/ServiceRequest');
const Invoice = require('../../models/Invoice');

exports.getProviderStats = async (req, res) => {
  try {
    const range = req.query.range || 'month';
    const now = new Date();

    // Thời điểm bắt đầu theo khoảng
    let start;
    if (range === 'week') {
      const day = now.getDay();              // 0..6 (CN..T7)
      start = new Date(now);
      start.setHours(0, 0, 0, 0);
      start.setDate(now.getDate() - day);    // đầu tuần (CN)
    } else if (range === 'month') {
      start = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (range === 'year') {
      start = new Date(now.getFullYear(), 0, 1);
    } else {
      // fallback
      start = new Date(now.getFullYear(), now.getMonth(), 1);
    }

    const providerObjectId = new mongoose.Types.ObjectId(req.user.id);

    // Helper: gom theo ngày/tháng để vẽ chart
    const aggregateByDate = async (Model, extraMatch = {}) => {
      return await Model.aggregate([
        {
          $match: {
            provider_id: providerObjectId,
            createdAt: { $gte: start, $lte: now },
            ...extraMatch
          }
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format:
                  range === 'week'  ? '%w' :   // 0..6
                  range === 'month' ? '%d' :   // 01..31
                                      '%m',    // 01..12
                date: '$createdAt'
              }
            },
            count: { $sum: 1 }
          }
        }
      ]);
    };

    // Lấy dữ liệu song song
    const [reqAgg, invAgg, paidAgg] = await Promise.all([
      aggregateByDate(ServiceRequest),
      aggregateByDate(Invoice),
      aggregateByDate(Invoice, { status: 'PAID' })
    ]);

    // Nhãn trục X
    let labels = [];
    if (range === 'week') {
      labels = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    } else if (range === 'month') {
      const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
      labels = Array.from({ length: days }, (_, i) => `${i + 1}`);
    } else {
      labels = Array.from({ length: 12 }, (_, i) => `Tháng ${i + 1}`);
    }

    // Map dữ liệu aggregate -> mảng theo labels
    const mapToDataset = (agg) => {
      const map = {};
      agg.forEach(item => {
        let idx = parseInt(item._id, 10);
        if (range === 'week') idx = idx % 7;         // 0..6
        else idx = idx - 1;                          // 01->0
        if (!isNaN(idx) && idx >= 0 && idx < labels.length) {
          map[idx] = item.count;
        }
      });
      return Array.from({ length: labels.length }, (_, i) => map[i] || 0);
    };

    // Đếm tổng + tính doanh thu
    const [requests, invoicesTotal, paidInvoices, revenueAgg] = await Promise.all([
      ServiceRequest.countDocuments({
        provider_id: providerObjectId,
        createdAt: { $gte: start, $lte: now }
      }),
      Invoice.countDocuments({
        provider_id: providerObjectId,
        createdAt: { $gte: start, $lte: now }
      }),
      Invoice.countDocuments({
        provider_id: providerObjectId,
        status: 'PAID',
        createdAt: { $gte: start, $lte: now }
      }),
      Invoice.aggregate([
        {
          $match: {
            provider_id: providerObjectId,
            status: 'PAID',
            createdAt: { $gte: start, $lte: now }
          }
        },
        { $group: { _id: null, total: { $sum: '$total_amount' } } }
      ])
    ]);

    const unpaidInvoices = Math.max(invoicesTotal - paidInvoices, 0);
    const revenue = revenueAgg.length ? revenueAgg[0].total : 0;

    // Dữ liệu biểu đồ
    const chart = {
      labels,
      datasets: [
        {
          label: 'Yêu cầu',
          data: mapToDataset(reqAgg),
          backgroundColor: '#38bdf8'
        },
        {
          label: 'Hóa đơn',
          data: mapToDataset(invAgg),
          backgroundColor: '#4ade80'
        },
        {
          label: 'Thanh toán',
          data: mapToDataset(paidAgg),
          backgroundColor: '#facc15'
        }
      ]
    };

    // Trả kết quả
    res.json({
      summary: {
        requests,
        invoices: {
          total: invoicesTotal,
          paid: paidInvoices,
          unpaid: unpaidInvoices
        },
        revenue
      },
      chart
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
