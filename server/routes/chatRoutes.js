// routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const { sendMessage, uploadImage, getUserChats, getChatById } = require('../controllers/chatController');

// Import multer configuration for file uploads
const multer = require('multer');
const path = require('path');

const upload = multer({
  dest: 'uploads/',
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Check MIME type first
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      // Fallback: check file extension
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      const fileExtension = path.extname(file.originalname).toLowerCase();
      
      if (allowedExtensions.includes(fileExtension)) {
        cb(null, true);
      } else {
        console.log('File rejected:', {
          originalname: file.originalname,
          mimetype: file.mimetype,
          extension: fileExtension
        });
        cb(new Error('Only image files are allowed'), false);
      }
    }
  },
});

// Send message endpoint (JSON only, no file upload)
router.post('/send', sendMessage);

// Upload image endpoint (multipart form data)
router.post('/upload', upload.single('image'), (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    // Multer error
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ 
        success: false, 
        error: 'File too large. Maximum size is 10MB.' 
      });
    }
    return res.status(400).json({ 
      success: false, 
      error: `Upload error: ${err.message}` 
    });
  } else if (err) {
    // Other errors (like fileFilter errors)
    return res.status(400).json({ 
      success: false, 
      error: err.message 
    });
  }
  // No error, proceed to uploadImage
  next();
}, uploadImage);

router.get('/history/:userId', getUserChats);
router.get('/:chatId', getChatById);

module.exports = router;
