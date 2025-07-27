# ChatGPT Clone

A full-stack ChatGPT clone built with Flutter (frontend) and Node.js (backend), featuring real-time chat functionality, image support, and chat history management.

## 🚀 Features

### Frontend (Flutter)
- **Modern UI/UX**: Clean, responsive design inspired by ChatGPT
- **Real-time Chat**: Send and receive messages with AI responses
- **Image Support**: Upload and send images in conversations
- **Chat History**: Persistent chat history with drawer navigation
- **Smart Sorting**: Chat history sorted by most recent conversations
- **Fresh Start**: Clean interface on app launch with optional chat loading
- **Cross-platform**: Works on Android, iOS, and web

### Backend (Node.js)
- **RESTful API**: Express.js server with structured endpoints
- **AI Integration**: OpenAI API integration for intelligent responses
- **Image Processing**: Cloudinary integration for image uploads
- **Database**: MongoDB with Mongoose for data persistence
- **Chat Management**: Full CRUD operations for chats and messages

## 📱 Screenshots

*[Add screenshots of your app here]*

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.7.2+
- **State Management**: Provider
- **HTTP Client**: http package
- **Image Picker**: image_picker
- **UI Components**: Material Design 3
- **Icons**: flutter_svg

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **AI Service**: OpenAI API
- **Image Storage**: Cloudinary
- **File Upload**: Multer
- **CORS**: Enabled for cross-origin requests

## 📋 Prerequisites

Before running this project, make sure you have:

- **Flutter SDK** (3.7.2 or higher)
- **Node.js** (v16 or higher)
- **MongoDB** (local or cloud instance)
- **OpenAI API Key**
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

# For web
flutter run -d chrome
```

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
│   │   └── chat_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── chat_screen.dart
│   │   └── onboarding_screen.dart
│   ├── utils/                    # Utilities
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── widgets/                  # Reusable widgets
│       └── chat_drawer.dart
├── server/
│   ├── controllers/              # API controllers
│   │   └── chatController.js
│   ├── models/                   # Database models
│   │   └── chat.js
│   ├── routes/                   # API routes
│   │   └── chatRoutes.js
│   ├── utils/                    # Utilities
│   │   └── cloudinary.js
│   ├── index.js                  # Server entry point
│   └── package.json
└── assets/                       # App assets
    ├── openai_icon.png
    └── openai.svg
```

## 🔌 API Endpoints

### Chat Endpoints
- `GET /api/chat/history/:userId` - Get user's chat history
- `GET /api/chat/:chatId` - Get specific chat messages
- `POST /api/chat/send` - Send a new message

### Request/Response Examples

**Send Message:**
```json
POST /api/chat/send
{
  "message": "Hello, how are you?",
  "userId": "user123",
  "chatId": "optional-chat-id",
  "image": "optional-base64-image"
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

## 🎯 Key Features Explained

### Chat History Management
- Chats are automatically sorted by timestamp (most recent first)
- Fresh start on app launch - no automatic chat loading
- Manual chat loading through drawer navigation
- Persistent storage in MongoDB

### Image Support
- Upload images from device gallery
- Base64 encoding for transmission
- Cloudinary integration for cloud storage
- Image display in chat messages

### State Management
- Provider pattern for reactive UI updates
- Centralized chat state management
- Automatic UI updates on data changes

## 🚀 Deployment

### Backend Deployment
1. Deploy to platforms like Heroku, Railway, or DigitalOcean
2. Set environment variables in your hosting platform
3. Ensure MongoDB connection is accessible

### Frontend Deployment
1. Build the Flutter app:
   ```bash
   flutter build web  # For web
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```
2. Deploy to Firebase Hosting, Netlify, or app stores

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for providing the AI API
- Flutter team for the amazing framework
- ChatGPT for UI/UX inspiration

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](../../issues) page
2. Create a new issue with detailed description
3. Contact the maintainers

---

**Note**: This is a clone project for educational purposes. Please respect OpenAI's terms of service and usage policies when using their API.
