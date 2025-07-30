const express = require('express');
const router = express.Router();
const controller = require('../../controllers/publics/getProvider.controller');

router.get('/provider/:id/services', controller.getServicesByProviderId);
router.get('/provider/:id', controller.getProviderInfoById);
router.get('/provider/:id/ratings', controller.getProviderRatings);
router.get('/providers', controller.getAllPublicProviders);

module.exports = router;
