// controllers/chatController.js
require('dotenv').config();
const { OpenAI } = require('openai');
const { v4: uuidv4 } = require('uuid');
const Chat = require('../models/chat');
const cloudinary = require('../utils/cloudinary');
const multer = require('multer');
const fs = require('fs');


const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

/**
 * POST /api/chat/send
 * Send a message (optionally with an image URL) and get AI response.
 * This endpoint only accepts JSON data with image URLs (not file uploads).
 */
exports.sendMessage = async (req, res) => {
  try {
    const {
      message,
      chatId,
      userId,
      model = 'gpt-3.5-turbo',
      image, // optional: URL to image
    } = req.body;

    if (!message || !userId) {
      return res.status(400).json({ error: 'Message and userId are required' });
    }

    const newChatId = chatId || uuidv4();

    // Find existing chat or start new
    const existingChat = await Chat.findOne({ chatId: newChatId });
    const messages = existingChat?.messages || [];

    // Use the image URL directly (it should already be a Cloudinary URL)
    const imageUrl = image || null;

    // Push user's message
    messages.push({
      role: 'user',
      content: message || '',
      imageUrl: imageUrl || null,
    });

    // Prepare only text parts for OpenAI
    const openAiMessages = messages
      .filter((m) => m.content && m.content.trim().length > 0)
      .map((m) => ({
        role: m.role,
        content: m.content,
      }));

    // Call OpenAI (guard if you're out of quota)
    let aiMessage = '[Temporarily mocked due to billing/quota issue]';
    try {
      const completion = await openai.chat.completions.create({
        model,
        messages: openAiMessages,
      });
      aiMessage = completion.choices[0].message.content;
    } catch (e) {
      console.error('OpenAI error (will return mocked response):', e.message);
    }

    // Push assistant message
    messages.push({
      role: 'assistant',
      content: aiMessage,
      imageUrl: null,
    });

    // Save chat
    await Chat.findOneAndUpdate(
      { chatId: newChatId },
      {
        userId,
        chatId: newChatId,
        model,
        messages,
      },
      { upsert: true, new: true }
    );

    res.json({
      success: true,
      chatId: newChatId,
      userMessage: message,
      aiMessage,
      imageUrl,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'OpenAI error' });
  }
};

/**
 * POST /api/chat/upload
 * Upload an image file to Cloudinary and return the URL.
 * This endpoint accepts multipart form data with an image file.
 */
exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No image file provided' });
    }

    console.log('Uploading file to Cloudinary:', req.file.originalname);

    // Upload the file to Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: 'chat_images',
    });

    // Clean up the temporary file
    try {
      fs.unlinkSync(req.file.path);
    } catch (deleteError) {
      console.error('Warning: Could not delete temporary file:', deleteError);
    }

    console.log('Image uploaded successfully:', result.secure_url);

    res.json({
      success: true,
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    console.error('Error uploading image:', err);
    
    // Clean up the temporary file even if upload fails
    if (req.file && fs.existsSync(req.file.path)) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (deleteError) {
        console.error('Warning: Could not delete temporary file:', deleteError);
      }
    }
    
    res.status(500).json({ success: false, error: "Upload failed" });
  }
};

/**
 * GET /api/chat/history/:userId
 * Returns list of chat sessions for the user (for your drawer list)
 */
exports.getUserChats = async (req, res) => {
  try {
    const { userId } = req.params;
    const chats = await Chat.find({ userId })
      .select("chatId model createdAt messages")
      .sort({ createdAt: -1 });

    const formatted = chats.map((c) => ({
      chatId: c.chatId,
      model: c.model,
      createdAt: c.createdAt,
      lastMessage: c.messages?.[c.messages.length - 1]?.content || "",
    }));

    res.json({ success: true, chats: formatted });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: "Failed to fetch history" });
  }
};

/**
 * GET /api/chat/:chatId
 * Returns full conversation (messages) for a specific chatId
 */
exports.getChatById = async (req, res) => {
  try {
    const { chatId } = req.params;
    const chat = await Chat.findOne({ chatId });

    if (!chat) {
      return res.status(404).json({ success: false, error: "Chat not found" });
    }

    res.json({ success: true, chat });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: "Failed to fetch chat" });
  }
};
