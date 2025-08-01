const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');

router.post('/create', paymentController.createPayment);
router.post('/ipn', paymentController.handleIpn);
router.get('/return', paymentController.handleReturn);
router.patch('/:id/mark-paid', paymentController.markInvoicePaid);

module.exports = router;
