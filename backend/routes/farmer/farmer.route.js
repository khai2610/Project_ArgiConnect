const express = require('express');
const router = express.Router();
const controller = require('../../controllers/farmer/farmer.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/profile', verifyToken('farmer'), controller.getProfile);
router.patch('/profile', verifyToken('farmer'), controller.updateProfile);

module.exports = router;
