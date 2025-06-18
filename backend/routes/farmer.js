const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth');
const checkRole = require('../middlewares/roleCheck');
const farmerCtrl = require('../controllers/farmer.controller');

router.get('/profile', auth, farmerCtrl.getProfile);
router.put('/profile', auth, checkRole('farmer'), farmerCtrl.updateProfile);
router.get('/farmer', auth, farmerCtrl.getFarmers);

module.exports = router;
