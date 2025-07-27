# ChatGPT Clone

A full-stack ChatGPT clone built with Flutter (frontend) and Node.js (backend), featuring real-time chat functionality, AI model selection, image support with compression, and comprehensive chat history management.

## 🚀 Features

### Frontend (Flutter)
- **Modern UI/UX**: Clean, responsive design inspired by ChatGPT with Material Design 3
- **Real-time Chat**: Send and receive messages with AI responses
- **AI Model Selection**: Dynamic model switching with visual selection dialog
- **Image Support**: Upload, compress, and send images in conversations
- **Chat History**: Persistent chat history with drawer navigation
- **Smart Sorting**: Chat history sorted by most recent conversations
- **Fresh Start**: Clean interface on app launch with optional chat loading
- **Cross-platform**: Works on Android and iOS
- **Typing Indicators**: Visual feedback during AI response generation

### Backend (Node.js)
- **RESTful API**: Express.js server with structured endpoints
- **AI Integration**: OpenAI API integration with multiple model support
- **Image Processing**: Cloudinary integration with automatic image optimization
- **Database**: MongoDB with Mongoose for data persistence
- **Chat Management**: Full CRUD operations for chats and messages
- **Model Management**: Dynamic model switching and availability checking
- **File Upload**: Multer with Cloudinary storage for image handling


## 📋 Prerequisites

Before running this project, make sure you have:

- **Flutter SDK** (3.7.2 or higher)
- **Node.js** (v16 or higher)
- **MongoDB** (local or cloud instance)
- **OpenAI API Key** (with access to desired models)
- **Cloudinary Account** (for image uploads)

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone <your-repository-url>
cd chatgpt_clone
```

### 2. Backend Setup

Navigate to the server directory:
```bash
cd server
```

Install dependencies:
```bash
npm install
```

Create a `.env` file in the server directory:
```env
PORT=5000
MONGODB_URI=your_mongodb_connection_string
OPENAI_API_KEY=your_openai_api_key
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

Start the server:
```bash
# Development mode
npm run dev

# Production mode
npm start
```

### 3. Frontend Setup

Navigate back to the project root:
```bash
cd ..
```

Install Flutter dependencies:
```bash
flutter pub get
```

Update the backend URL in `lib/provider/chat_provider.dart`:
```dart
final String _baseUrl = 'http://your-server-ip:5000/api/chat';
```

Run the app:
```bash
# For Android
flutter run

# For iOS
flutter run -d ios


## 📁 Project Structure

```
chatgpt_clone/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── chat_history_model.dart
│   │   ├── chat_message_model.dart
│   │   └── message_model.dart
│   ├── provider/                 # State management
│   │   └── chat_provider.dart    # Main chat logic and API calls
│   ├── screens/                  # UI screens
│   │   ├── chat_screen.dart
│   │   └── onboarding_screen.dart
│   ├── utils/                    # Utilities
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── widgets/                  # Reusable widgets
│       ├── chat_drawer.dart
│       └── model_selection_dialog.dart
├── server/
│   ├── controllers/              # API controllers
│   │   └── chatController.js
│   ├── models/                   # Database models
│   │   └── chat.js
│   ├── routes/                   # API routes
│   │   └── chatRoutes.js
│   ├── utils/                    # Utilities
│   │   └── cloudinary.js
│   ├── uploads/                  # Temporary upload directory
│   ├── index.js                  # Server entry point
│   └── package.json
├── assets/                       # App assets
│   ├── openai_icon.png
│   └── openai.svg
└── test/                         # Test files
    ├── test_model_responses.js
    ├── test_models.js
    └── test_upload.js
```

## 🔌 API Endpoints

### Chat Endpoints
- `GET /api/chat/history/:userId` - Get user's chat history
- `GET /api/chat/:chatId` - Get specific chat messages
- `POST /api/chat/send` - Send a new message
- `POST /api/chat/upload` - Upload image to Cloudinary
- `GET /api/chat/models` - Get available AI models
- `POST /api/chat/set-model` - Set current AI model

### Request/Response Examples

**Send Message:**
```json
POST /api/chat/send
{
  "message": "Hello, how are you?",
  "userId": "user123",
  "chatId": "optional-chat-id",
  "image": "optional-cloudinary-url"
}
```

**Response:**
```json
{
  "success": true,
  "chatId": "generated-chat-id",
  "aiMessage": "Hello! I'm doing well, thank you for asking..."
}
```

**Get Available Models:**
```json
GET /api/chat/models
```

**Response:**
```json
{
  "success": true,
  "currentModel": "gpt-3.5-turbo",
  "models": [
    {
      "id": "gpt-3.5-turbo",
      "name": "GPT-3.5 Turbo",
      "description": "Most capable GPT-3.5 model",
      "type": "chat"
    },
    {
      "id": "gpt-4",
      "name": "GPT-4",
      "description": "Most capable GPT-4 model",
      "type": "chat"
    }
  ]
}
```

## 🎯 Key Features Explained

### AI Model Selection
- Dynamic model fetching from OpenAI API
- Visual model selection dialog with descriptions
- Real-time model switching without app restart
- Automatic model availability checking

### Chat History Management
- Chats are automatically sorted by timestamp (most recent first)
- Fresh start on app launch - no automatic chat loading
- Manual chat loading through drawer navigation
- Persistent storage in MongoDB with proper indexing

### Image Support & Compression
- Upload images from device gallery or camera
- Automatic image compression for better performance
- Cloudinary integration for cloud storage
- Base64 encoding for transmission
- Image display in chat messages with proper sizing

### State Management
- Provider pattern for reactive UI updates
- Centralized chat state management
- Automatic UI updates on data changes
- Loading states and error handling

### Error Handling
- Comprehensive error handling for network issues
- User-friendly error messages
- Image size validation and compression
- API error responses with detailed information


## 🔧 Configuration

### Environment Variables
- `PORT`: Server port (default: 5000)
- `MONGODB_URI`: MongoDB connection string
- `OPENAI_API_KEY`: Your OpenAI API key
- `CLOUDINARY_CLOUD_NAME`: Cloudinary cloud name
- `CLOUDINARY_API_KEY`: Cloudinary API key
- `CLOUDINARY_API_SECRET`: Cloudinary API secret



## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


**Note**: This is a clone project for educational purposes. Please respect OpenAI's terms of service and usage policies when using their API. Ensure you have proper API access and rate limits configured for production use.
