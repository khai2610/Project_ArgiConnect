const express = require('express');
const router = express.Router();
const controller = require('../../controllers/provider/service.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/', verifyToken('provider'), controller.getServices);
router.post('/', verifyToken('provider'), controller.addService);
router.delete('/:name', verifyToken('provider'), controller.removeService);
router.patch('/:name', verifyToken('provider'), controller.updateService);

module.exports = router;
