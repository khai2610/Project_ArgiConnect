const express = require('express');
const router = express.Router();
const controller = require('../../controllers/provider/invoice.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.post('/', verifyToken('provider'), controller.createInvoice);
router.get('/', verifyToken('provider'), controller.getProviderInvoices);

module.exports = router;
