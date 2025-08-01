const crypto = require('crypto');
const axios = require('axios');
 const momo = require('../configs/momo.config');
const Invoice = require('../models/Invoice');

exports.createPayment = async (req, res) => {
  const { invoiceId } = req.body;
  const requestId = Date.now().toString();

  try {
    const invoice = await Invoice.findById(invoiceId);
    if (!invoice) return res.status(404).json({ message: 'Invoice not found' });

    const orderId = invoice._id.toString();
    const amount = invoice.total_amount.toString();
    const orderInfo = `Thanh toán hóa đơn ${orderId}`;
    const extraData = Buffer.from(JSON.stringify({ farmerId: invoice.farmer_id })).toString('base64');

    const rawSignature = `accessKey=${momo.accessKey}&amount=${amount}&extraData=${extraData}&ipnUrl=${momo.ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${momo.partnerCode}&redirectUrl=${momo.redirectUrl}&requestId=${requestId}&requestType=${momo.requestType}`;
    const signature = crypto.createHmac('sha256', momo.secretKey).update(rawSignature).digest('hex');

    const body = {
      partnerCode: momo.partnerCode,
      accessKey: momo.accessKey,
      requestId,
      amount,
      orderId,
      orderInfo,
      redirectUrl: momo.redirectUrl,
      ipnUrl: momo.ipnUrl,
      extraData,
      requestType: momo.requestType,
      signature,
      lang: 'vi'
    };

    const momoRes = await axios.post(momo.endpoint, body, { headers: { 'Content-Type': 'application/json' }});
    res.json({ payUrl: momoRes.data.payUrl });

    } catch (err) {
    const responseData = err.response?.data;
    console.error('[MoMo] Error:', responseData || err.message);

    res.status(500).json({
      message: 'Tạo thanh toán MoMo thất bại',
      error: responseData || err.message
    });
  }

};

exports.handleIpn = async (req, res) => {
  const { resultCode, orderId } = req.body;
  try {
    if (resultCode === 0) {
      await Invoice.findByIdAndUpdate(orderId, { status: 'PAID' });
    }
    res.status(200).json({ message: 'IPN processed' });
  } catch (err) {
    console.error('[IPN] Error:', err);
    res.status(500).json({ message: 'Lỗi xử lý IPN' });
  }
};

exports.handleReturn = (req, res) => {
  res.send('Cảm ơn bạn đã thanh toán. Giao dịch đang được xử lý.');
};

// PATCH /invoices/:id/mark-paid
exports.markInvoicePaid = async (req, res) => {
  try {
    const invoice = await Invoice.findByIdAndUpdate(
      req.params.id,
      { status: 'PAID',
        paidAt: new Date()
      },
      { new: true }
    );
    if (!invoice) return res.status(404).json({ message: 'Invoice not found' });
    res.json({ message: 'Invoice marked as paid', invoice });
  } catch (err) {
    console.error('[mark-paid] Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
