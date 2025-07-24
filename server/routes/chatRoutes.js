// routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const { sendMessage, uploadImage } = require('../controllers/chatController');
const { getChatHistory } = require('../controllers/chatController');

router.post('/send', sendMessage);
router.post('/upload', uploadImage);
router.get('/history/:userId', getChatHistory);

module.exports = router;
