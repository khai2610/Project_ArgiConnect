const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth');
const checkRole = require('../middlewares/roleCheck');
const providerCtrl = require('../controllers/provider.controller');

router.get('/profile', auth, checkRole('provider'), providerCtrl.getProfile);
router.put('/profile', auth, checkRole('provider'), providerCtrl.updateProfile);
router.get('/providers/by-email', auth, providerCtrl.getProviderByEmail);
module.exports = router;
