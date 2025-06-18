const express = require('express');
const router = express.Router();
const adminCtrl = require('../controllers/admin.controller');
const auth = require('../middlewares/auth');
const checkRole = require('../middlewares/roleCheck');

// Middleware admin
const adminOnly = [auth, checkRole('admin')];

// Lấy danh sách provider hoặc farmer
router.get('/users/:role',  adminCtrl.getUsersByRole);

// Lấy chi tiết user
router.get('/user/:id', adminOnly, adminCtrl.getUserById);

// Cập nhật user
router.put('/user/:id', adminOnly, adminCtrl.updateUser);

// Xoá user
router.delete('/user/:id', adminOnly, adminCtrl.deleteUser);

module.exports = router;
