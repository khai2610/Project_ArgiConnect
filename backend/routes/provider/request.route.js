const express = require('express');
const router = express.Router();
const controller = require('../../controllers/provider/request.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/', verifyToken('provider'), controller.getAllRequests);
router.patch('/:id/accept', verifyToken('provider'), controller.acceptRequest);
router.patch('/:id/complete', verifyToken('provider'), controller.completeRequest);
router.get('/summary', verifyToken('provider'), controller.getProviderSummary);
router.patch('/:id/reject', verifyToken('provider'), controller.rejectRequest);

module.exports = router;
