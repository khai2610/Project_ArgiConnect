const express = require('express');
const router = express.Router();
const controller = require('../../controllers/farmer/farmer.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const upload = require('../../middlewares/upload.middleware'); // 👈 middleware multer

router.get('/profile', verifyToken('farmer'), controller.getProfile);
router.patch('/profile', verifyToken('farmer'), controller.updateProfile);
router.post('/avatar', verifyToken('farmer'), controller.updateAvatar);
router.post('/avatar/upload', verifyToken('farmer'), upload.single('avatar'), controller.uploadAvatar);

module.exports = router;

