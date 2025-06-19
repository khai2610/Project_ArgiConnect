const express = require('express');
const router = express.Router();
const controller = require('../../controllers/farmer/listService.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/', verifyToken('farmer'), controller.getAllApprovedProviders);

module.exports = router;
