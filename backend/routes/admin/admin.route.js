// routes/admin.route.js
const express = require('express');
const router = express.Router();
const controller = require('../../controllers/admin/admin.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/providers/pending', verifyToken('admin'), controller.getPendingProviders);
router.patch('/providers/:id/approve', verifyToken('admin'), controller.approveProvider);
router.patch('/providers/:id/reject', verifyToken('admin'), controller.rejectProvider);

router.get('/farmers', verifyToken('admin'), controller.getAllFarmers);
router.get('/providers', verifyToken('admin'), controller.getAllProviders);
router.get('/requests', verifyToken('admin'), controller.getAllRequests);
router.get('/invoices', verifyToken('admin'), controller.getAllInvoices);

module.exports = router;
