// controllers/chatController.js
const { OpenAI } = require('openai');
const { v4: uuidv4 } = require('uuid');
const Chat = require('../models/chat');
const cloudinary = require('../utils/cloudinary');
require('dotenv').config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

/**
 * POST /api/chat/send
 * Send a message (optionally with an image) and get AI response.
 * If `image` is a base64 string, we upload it to Cloudinary automatically.
 */
exports.sendMessage = async (req, res) => {
  try {
    const {
      message,
      chatId,
      userId,
      model = 'gpt-3.5-turbo',
      image, // optional: base64 or URL
    } = req.body;

    if (!message || !userId) {
      return res.status(400).json({ error: 'Message and userId are required' });
    }

    const newChatId = chatId || uuidv4();

    // Find existing chat or start new
    const existingChat = await Chat.findOne({ chatId: newChatId });
    const messages = existingChat?.messages || [];

    // If image is provided and looks like base64, upload it
    let imageUrl = null;
    if (image && image.startsWith('data:')) {
      const upload = await cloudinary.uploader.upload(image, {
        folder: 'chat_images',
      });
      imageUrl = upload.secure_url;
    } else if (image && image.startsWith('http')) {
      imageUrl = image;
    }

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
 * (Optional) Separate endpoint just to upload an image and get URL back.
 * Use only if you want to upload first and then send the URL in /send.
 */
exports.uploadImage = async (req, res) => {
  try {
    const { image } = req.body;

    if (!image) {
      return res.status(400).json({ success: false, error: 'No image provided' });
    }

    const result = await cloudinary.uploader.upload(image, {
      folder: 'chat_images',
    });

    res.json({
      success: true,
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Upload failed' });
  }
};

/**
 * GET /api/chat/history/:userId
 * Returns list of chat sessions for the user (for your drawer list)
 */
exports.getChatHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    const chats = await Chat.find({ userId })
      .select('chatId model createdAt messages')
      .sort({ createdAt: -1 });

    const formatted = chats.map((c) => ({
      chatId: c.chatId,
      model: c.model,
      createdAt: c.createdAt,
      lastMessage: c.messages?.[c.messages.length - 1]?.content || '',
    }));

    res.json({ success: true, chats: formatted });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch history' });
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
      return res.status(404).json({ success: false, error: 'Chat not found' });
    }

    res.json({ success: true, chat });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch chat' });
  }
};
