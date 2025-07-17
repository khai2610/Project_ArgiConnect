const express = require('express');
const router = express.Router();
const controller = require('../../controllers/provider/provider.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const upload = require('../../middlewares/upload.middleware'); // đường dẫn có thể cần chỉnh

router.get('/profile', verifyToken('provider'), controller.getProfile);
router.patch('/profile', verifyToken('provider'), controller.updateProfile);
router.patch('/avatar', verifyToken('provider'), controller.updateAvatar);
router.post('/avatar/upload', verifyToken('provider'), upload.single('avatar'), controller.uploadAvatar);
module.exports = router;
