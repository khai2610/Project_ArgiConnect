const express = require('express');
const router = express.Router();
const controller = require('../controllers/auth.controller');
const upload = require('../middlewares/upload.middleware');

router.post('/login', controller.login);
router.post('/register', upload.single('avatar'), controller.register);

module.exports = router;
