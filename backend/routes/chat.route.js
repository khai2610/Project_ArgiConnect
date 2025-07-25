const express = require('express');
const router = express.Router();
const controller = require('../controllers/chat.controller');
const { verifyToken } = require('../middlewares/auth.middleware');

console.log('typeof verifyToken:', typeof verifyToken);                      // function
console.log('typeof verifyToken(...):', typeof verifyToken(['farmer']));    // function
console.log('verifyToken(...):', verifyToken(['farmer']));                  // xem kết quả
console.log('typeof controller:', typeof controller); // phải là 'object'
console.log('typeof controller.sendMessage:', typeof controller.sendMessage); // phải là 'function'

router.get('/', verifyToken(['farmer', 'provider']), controller.getConversations);
router.get('/between/:farmerId/:providerId', verifyToken(['farmer', 'provider']), controller.getMessagesBetweenUsers);
router.post('/between/:farmerId/:providerId', verifyToken(['farmer', 'provider']), controller.sendMessageBetweenUsers);

module.exports = router;
