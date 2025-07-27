// controllers/chatController.js
require('dotenv').config();
const { OpenAI } = require('openai');
const { v4: uuidv4 } = require('uuid');
const Chat = require('../models/chat');
const cloudinary = require('../utils/cloudinary');
const multer = require('multer');
const fs = require('fs');
const axios = require('axios');


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
    console.log('=== Starting Message Send ===');
    
    const {
      message,
      chatId,
      userId,
      model = process.env.DEFAULT_MODEL || 'gpt-3.5-turbo',
      image, // optional: URL to image
    } = req.body;

    console.log('📨 Request details:');
    console.log('  - Message:', message);
    console.log('  - User ID:', userId);
    console.log('  - Chat ID:', chatId);
    console.log('  - Model:', model);
    console.log('  - Has image:', !!image);
    if (image) {
      console.log('  - Image URL:', image);
    }

    if (!message || !userId) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ error: 'Message and userId are required' });
    }

    const newChatId = chatId || uuidv4();
    console.log('  - New/Existing Chat ID:', newChatId);

    // Find existing chat or start new
    const existingChat = await Chat.findOne({ chatId: newChatId });
    const messages = existingChat?.messages || [];
    console.log('  - Existing messages count:', messages.length);

    // Use the image URL directly (it should already be a Cloudinary URL)
    const imageUrl = image || null;

    // Push user's message
    messages.push({
      role: 'user',
      content: message || '',
      imageUrl: imageUrl || null,
    });

    console.log('✅ User message added to chat');
    if (imageUrl) {
      console.log('  - Image URL included in message');
    }

    // Prepare messages for OpenAI (including images when present)
    const openAiMessages = messages.map((m) => {
      const baseMessage = {
        role: m.role,
        content: m.content,
      };

      // If this message has an image, add it to the content
      if (m.imageUrl && m.role === 'user') {
        baseMessage.content = [
          {
            type: 'text',
            text: m.content || 'Analyze this image'
          },
          {
            type: 'image_url',
            image_url: {
              url: m.imageUrl // This will be converted to base64 later if needed
            }
          }
        ];
      }

      return baseMessage;
    });

    console.log('🤖 Preparing OpenAI request:');
    console.log('  - Messages to send:', openAiMessages.length);
    console.log('  - OpenAI API Key:', process.env.OPENAI_API_KEY ? 'Set' : 'Not set');
    
    // Log the message structure for debugging
    openAiMessages.forEach((msg, index) => {
      console.log(`  - Message ${index + 1}:`, {
        role: msg.role,
        hasImage: Array.isArray(msg.content) && msg.content.some(item => item.type === 'image_url'),
        contentType: Array.isArray(msg.content) ? 'multimodal' : 'text'
      });
    });

    // Call OpenAI (guard if you're out of quota)
    let aiMessage = '[Temporarily mocked due to billing/quota issue]';
    try {
      console.log('🚀 Calling OpenAI API...');
      
      // Check if any message contains an image
      const hasImage = openAiMessages.some(msg => 
        Array.isArray(msg.content) && msg.content.some(item => item.type === 'image_url')
      );
      
      // Determine which model to use
      let modelToUse;
      if (hasImage) {
        // If image is present, use vision model regardless of selected model
        modelToUse = 'gpt-4-vision-preview';
        console.log(`  - Image detected, using vision model: ${modelToUse}`);
        
        // Convert Cloudinary URLs to base64 for vision model
        console.log('🔄 Converting image URLs to base64 for vision model...');
        for (const msg of openAiMessages) {
          if (Array.isArray(msg.content)) {
            for (const item of msg.content) {
              if (item.type === 'image_url' && item.image_url.url) {
                try {
                  const base64Url = await convertUrlToBase64(item.image_url.url);
                  item.image_url.url = base64Url;
                  console.log('✅ Image converted to base64 successfully');
                } catch (conversionError) {
                  console.error('❌ Failed to convert image to base64:', conversionError.message);
                  // Fall back to text-only if image conversion fails
                  msg.content = msg.content.filter(item => item.type === 'text');
                  console.log('⚠️ Falling back to text-only message');
                }
              }
            }
          }
        }
      } else {
        // Use the selected model for text-only conversations
        modelToUse = model;
        console.log(`  - Using selected model: ${modelToUse}`);
      }
      
      console.log(`  - Final model: ${modelToUse} (has image: ${hasImage})`);
      
      // Validate that the model exists in available models
      try {
        const availableModels = await openai.models.list();
        const modelExists = availableModels.data.some(m => m.id === modelToUse);
        
        if (!modelExists) {
          console.log(`  - Warning: Model ${modelToUse} not found, falling back to gpt-3.5-turbo`);
          modelToUse = 'gpt-3.5-turbo';
        }
      } catch (validationError) {
        console.log(`  - Warning: Could not validate model ${modelToUse}, proceeding anyway`);
      }
      
      const completion = await openai.chat.completions.create({
        model: modelToUse,
        messages: openAiMessages,
        max_tokens: hasImage ? 300 : 1000, // Vision model has different token limits
      });
      aiMessage = completion.choices[0].message.content;
      console.log('✅ OpenAI response received');
      console.log('  - Response length:', aiMessage.length);
      console.log('  - Response preview:', aiMessage.substring(0, 100) + '...');
      console.log('  - Model used:', modelToUse);
    } catch (e) {
      console.error('❌ OpenAI error (will return mocked response):', e.message);
      console.error('  - Error details:', {
        code: e.code,
        status: e.status,
        type: e.type
      });
      
      // Provide more specific error messages
      if (e.message.includes('billing')) {
        aiMessage = '[Error: OpenAI billing/quota issue. Please check your account billing status.]';
      } else if (e.message.includes('invalid')) {
        aiMessage = '[Error: Invalid API key or model. Please check your configuration.]';
      } else if (e.message.includes('quota')) {
        aiMessage = '[Error: API quota exceeded. Please check your usage limits.]';
      } else if (e.message.includes('rate')) {
        aiMessage = '[Error: Rate limit exceeded. Please try again in a moment.]';
      } else {
        aiMessage = `[Error: ${e.message}]`;
      }
    }

    // Push assistant message
    messages.push({
      role: 'assistant',
      content: aiMessage,
      imageUrl: null,
    });

    console.log('✅ Assistant message added to chat');

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

    console.log('💾 Chat saved to database');

    res.json({
      success: true,
      chatId: newChatId,
      userMessage: message,
      aiMessage,
      imageUrl,
    });
  } catch (err) {
    console.error('❌ Error in sendMessage:', err);
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
    console.log('=== Starting Cloudinary Upload ===');
    
    if (!req.file) {
      console.log('❌ No image file provided');
      return res.status(400).json({ success: false, error: 'No image file provided' });
    }

    console.log('📁 File details:');
    console.log('  - Original name:', req.file.originalname);
    console.log('  - MIME type:', req.file.mimetype);
    console.log('  - File size:', req.file.size, 'bytes');
    console.log('  - File path:', req.file.path);

    // Check file size
    const fileSizeMB = req.file.size / (1024 * 1024);
    console.log('  - File size (MB):', fileSizeMB.toFixed(2));

    console.log('☁️ Uploading file to Cloudinary...');
    console.log('  - Cloud name:', process.env.CLOUDINARY_CLOUD_NAME);
    console.log('  - API Key:', process.env.CLOUDINARY_API_KEY ? 'Set' : 'Not set');
    console.log('  - API Secret:', process.env.CLOUDINARY_API_SECRET ? 'Set' : 'Not set');

    // Upload the file to Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: 'chat_images',
    });

    console.log('✅ Image uploaded successfully to Cloudinary!');
    console.log('  - Secure URL:', result.secure_url);
    console.log('  - Public ID:', result.public_id);
    console.log('  - Format:', result.format);
    console.log('  - Width:', result.width);
    console.log('  - Height:', result.height);
    console.log('  - Bytes:', result.bytes);

    // Clean up the temporary file
    try {
      fs.unlinkSync(req.file.path);
      console.log('🗑️ Temporary file cleaned up');
    } catch (deleteError) {
      console.error('⚠️ Warning: Could not delete temporary file:', deleteError);
    }

    res.json({
      success: true,
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    console.error('❌ Error uploading image:', err);
    console.error('Error details:', {
      message: err.message,
      stack: err.stack,
      code: err.code,
      http_code: err.http_code
    });
    
    // Clean up the temporary file even if upload fails
    if (req.file && fs.existsSync(req.file.path)) {
      try {
        fs.unlinkSync(req.file.path);
        console.log('🗑️ Temporary file cleaned up after error');
      } catch (deleteError) {
        console.error('⚠️ Warning: Could not delete temporary file:', deleteError);
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

/**
 * GET /api/chat/models
 * Get available OpenAI models for the current API key
 */
exports.getAvailableModels = async (req, res) => {
  try {
    console.log('🔍 Fetching available OpenAI models...');
    
    if (!process.env.OPENAI_API_KEY) {
      return res.status(400).json({ 
        success: false, 
        error: 'OpenAI API key not configured' 
      });
    }

    const models = await openai.models.list();
    
    // Filter for chat completion models
    const chatModels = models.data
      .filter(model => model.id.includes('gpt'))
      .map(model => ({
        id: model.id,
        name: model.id,
        description: getModelDescription(model.id),
        type: getModelType(model.id)
      }))
      .sort((a, b) => {
        // Sort by type (vision first, then 4, then 3.5)
        const typeOrder = { 'vision': 0, 'gpt-4': 1, 'gpt-3.5': 2 };
        return (typeOrder[a.type] || 3) - (typeOrder[b.type] || 3);
      });

    console.log(`✅ Found ${chatModels.length} available models`);
    
    res.json({
      success: true,
      models: chatModels,
      currentModel: process.env.DEFAULT_MODEL || 'gpt-3.5-turbo'
    });
  } catch (error) {
    console.error('❌ Error fetching models:', error.message);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch models',
      details: error.message 
    });
  }
};

/**
 * POST /api/chat/set-model
 * Set the default model for the application
 */
exports.setModel = async (req, res) => {
  try {
    const { model } = req.body;
    
    if (!model) {
      return res.status(400).json({ 
        success: false, 
        error: 'Model parameter is required' 
      });
    }

    console.log(`🔄 Setting default model to: ${model}`);
    
    // Validate the model exists
    try {
      const models = await openai.models.list();
      const modelExists = models.data.some(m => m.id === model);
      
      if (!modelExists) {
        console.log(`❌ Model ${model} not found in available models`);
        return res.status(400).json({ 
          success: false, 
          error: `Model '${model}' is not available with your API key` 
        });
      }
      
      console.log(`✅ Model ${model} validated successfully`);
    } catch (error) {
      console.error('❌ Error validating model:', error.message);
      return res.status(500).json({ 
        success: false, 
        error: 'Failed to validate model. Please check your API key.' 
      });
    }

    // Update environment variable (in production, you'd want to persist this to a database)
    process.env.DEFAULT_MODEL = model;
    
    console.log(`✅ Default model updated to: ${model}`);
    console.log(`  - Environment variable set: ${process.env.DEFAULT_MODEL}`);
    
    res.json({
      success: true,
      message: `Model updated to ${model}`,
      currentModel: model,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error setting model:', error.message);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to set model' 
    });
  }
};

/**
 * Convert a Cloudinary URL to base64 for OpenAI Vision API
 */
async function convertUrlToBase64(imageUrl) {
  try {
    console.log(`🔄 Converting URL to base64: ${imageUrl}`);
    
    // Download the image
    const response = await axios.get(imageUrl, {
      responseType: 'arraybuffer',
      timeout: 10000 // 10 second timeout
    });
    
    // Convert to base64
    const base64 = Buffer.from(response.data, 'binary').toString('base64');
    
    // Determine MIME type from URL or response headers
    let mimeType = 'image/jpeg'; // default
    if (imageUrl.includes('.png')) {
      mimeType = 'image/png';
    } else if (imageUrl.includes('.gif')) {
      mimeType = 'image/gif';
    } else if (imageUrl.includes('.webp')) {
      mimeType = 'image/webp';
    }
    
    const dataUrl = `data:${mimeType};base64,${base64}`;
    console.log(`✅ Converted to base64 (${base64.length} chars, ${mimeType})`);
    
    return dataUrl;
  } catch (error) {
    console.error('❌ Error converting URL to base64:', error.message);
    throw new Error(`Failed to convert image URL to base64: ${error.message}`);
  }
}

// Helper functions
function getModelDescription(modelId) {
  const descriptions = {
    'gpt-4': 'Most capable GPT-4 model',
    'gpt-4-turbo': 'Latest GPT-4 model with improved performance',
    'gpt-4-vision-preview': 'GPT-4 model with vision capabilities',
    'gpt-3.5-turbo': 'Fast and efficient GPT-3.5 model',
    'gpt-3.5-turbo-16k': 'GPT-3.5 with larger context window'
  };
  return descriptions[modelId] || 'OpenAI language model';
}

function getModelType(modelId) {
  if (modelId.includes('vision')) return 'vision';
  if (modelId.includes('gpt-4')) return 'gpt-4';
  if (modelId.includes('gpt-3.5')) return 'gpt-3.5';
  return 'other';
}
