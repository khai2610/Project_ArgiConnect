const express = require('express');
const router = express.Router();
const controller = require('../../controllers/farmer/request.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.post('/', verifyToken('farmer'), controller.createRequest);
router.get('/', verifyToken('farmer'), controller.getMyRequests);
router.patch('/:id', verifyToken('farmer'), controller.updateRequest);   // chỉnh sửa yêu cầu
router.delete('/:id', verifyToken('farmer'), controller.cancelRequest);  // huỷ yêu cầu
router.post('/:id/pay', verifyToken('farmer'), controller.payRequest);
router.post('/:id/rate', verifyToken('farmer'), controller.rateRequest);
router.patch('/:id/resend', verifyToken('farmer'), controller.resendRequest); // 👈 Gửi lại yêu cầu bị từ chối

module.exports = router;
