const express = require('express');
const router = express.Router();
const controller = require('../../controllers/provider/provider.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/profile', verifyToken('provider'), controller.getProfile);
router.patch('/profile', verifyToken('provider'), controller.updateProfile);

module.exports = router;
