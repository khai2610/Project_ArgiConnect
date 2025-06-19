const express = require('express');
const router = express.Router();
const controller = require('../../controllers/farmer/invoice.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/', verifyToken('farmer'), controller.getFarmerInvoices);

module.exports = router;
