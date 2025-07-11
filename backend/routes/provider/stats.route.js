const router = require('express').Router();
const { getProviderStats } = require('../../controllers/provider/stats.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/', verifyToken('provider'), getProviderStats);

module.exports = router;
