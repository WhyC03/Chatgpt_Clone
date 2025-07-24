// models/chat.js
const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  role: {
    type: String,
    enum: ['user', 'assistant'],
    required: true,
  },
  content: {
    type: String,
    required: false,
  },
  imageUrl: {
    type: String,
    default: null,
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
});

const chatSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    chatId: { type: String, required: true, unique: true },
    model: { type: String, default: 'gpt-3.5-turbo' },
    messages: [messageSchema],
    createdAt: { type: Date, default: Date.now },
  },
  { collection: 'chats' }
);

module.exports = mongoose.model('Chat', chatSchema);
