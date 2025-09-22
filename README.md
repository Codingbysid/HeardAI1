# 🎤 HeardAI - Voice Assistant for iOS

**A production-ready voice assistant that integrates with Siri using Google Cloud Speech-to-Text for free transcription.**

## ✨ Features

### 🎯 **Core Functionality**
- **Wake Word Detection**: "Hey HeardAI" activation
- **Voice Commands**: Natural language command processing
- **Command Confirmation**: Review and edit commands before execution
- **Siri Integration**: Seamless execution through Siri
- **Free Transcription**: Google Speech-to-Text (60 minutes/month)

### 🛠️ **Technical Features**
- **Real-time Audio Processing**: Optimized for performance
- **Memory Management**: Leak-free resource handling
- **Error Handling**: Comprehensive error recovery
- **Professional Logging**: Structured logging system
- **Diagnostic Testing**: Built-in health checks

## 🚀 Quick Start

### **1. Prerequisites**
- iOS 14.0+
- Xcode 12.0+
- Google Cloud Speech-to-Text API key

### **2. Setup**
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Codingbysid/HeardAI1.git
   cd HeardAI1
   ```

2. **Get Google Speech API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Speech-to-Text API
   - Create credentials (API Key)
   - Copy your API key

3. **Configure API Key**:
   - Open `HeardAI.xcodeproj` in Xcode
   - Add your API key to `Info.plist`:
   ```xml
   <key>GOOGLE_SPEECH_API_KEY</key>
   <string>YOUR_API_KEY_HERE</string>
   ```

4. **Build and Run**:
   - Press ⌘+R in Xcode
   - Grant microphone and speech recognition permissions

### **3. Usage**
1. **Say "Hey HeardAI"** to activate
2. **Speak your command** (e.g., "Call Mom", "Set reminder to buy milk")
3. **Review the transcription** in the confirmation dialog
4. **Edit if needed** or click Accept/Reject
5. **Watch Siri execute** your command

## 🏗️ Architecture

### **Clean Service Architecture**
```
HeardAI/
├── Services/
│   ├── AudioManager.swift          # Core audio processing
│   ├── WhisperService.swift        # Google Speech integration
│   ├── SiriService.swift           # Siri command execution
│   └── SpeechRecognizer.swift      # On-device speech recognition
├── Views/
│   └── ContentView.swift           # Main UI with command confirmation
├── Utils/
│   ├── TestRunner.swift            # Diagnostic testing
│   └── FunctionalityTest.swift     # Comprehensive testing
└── HeardAIApp.swift                # App entry point
```

### **Key Technologies**
- **SwiftUI**: Modern declarative UI
- **AVFoundation**: Audio capture and processing
- **Speech Framework**: On-device speech recognition
- **Google Speech API**: Cloud-based transcription
- **Combine**: Reactive programming
- **SiriKit**: Siri integration

## 📱 Supported Commands

### **Reminders**
- "Remind me to call John"
- "Set a reminder to buy groceries"

### **Messages**
- "Send a message to Sarah"
- "Text Mom I'll be late"

### **Calls**
- "Call Dad"
- "Phone my sister"

### **Weather**
- "What's the weather like?"
- "Is it going to rain today?"

### **Music**
- "Play some music"
- "Play my workout playlist"

### **Timers & Alarms**
- "Set a timer for 5 minutes"
- "Set an alarm for 7 AM"

### **General**
- "What time is it?"
- "Open Settings"

## 🔧 Configuration

### **Audio Settings**
- Sample Rate: 16kHz
- Channels: Mono
- Format: LINEAR16 PCM
- Buffer Duration: 100ms

### **API Configuration**
- Google Speech-to-Text API
- Language: en-US
- Model: default
- Automatic punctuation enabled

### **Performance Settings**
- Background processing for audio
- Memory-efficient buffer management
- Battery-aware optimizations

## 🧪 Testing

### **Built-in Diagnostics**
The app runs diagnostic tests on startup:
- Service initialization verification
- Audio session configuration
- API connectivity checks
- Memory management validation

### **Manual Testing**
1. Test wake word detection
2. Verify command transcription accuracy
3. Check Siri integration
4. Validate error handling

## 📊 Performance

### **Optimizations**
- **Memory Management**: Circular buffers, proper cleanup
- **Battery Efficiency**: Adaptive processing intervals
- **Network Usage**: Optimized API calls
- **CPU Usage**: Background processing queues

### **Monitoring**
- Real-time performance metrics
- Memory usage tracking
- Battery level awareness
- Network status monitoring

## 🔒 Security & Privacy

### **Data Protection**
- No voice data storage
- Temporary file cleanup
- Secure API communication (HTTPS)
- Minimal data collection

### **API Key Security**
- Environment variable storage
- No hardcoded secrets
- Secure transmission only

## 🐛 Troubleshooting

### **Common Issues**

#### **"API key missing" error**
- Verify API key in Info.plist
- Check for extra spaces in key
- Ensure key starts with proper prefix

#### **"Speech recognition not available"**
- Grant microphone permission
- Check speech recognition permission
- Verify internet connection

#### **"No transcription found"**
- Speak clearly and loudly
- Check microphone functionality
- Verify API key validity

#### **"Siri not responding"**
- Check Siri settings
- Verify command format
- Test with simple commands first

### **Debug Mode**
Enable debug logging by checking console output for detailed information.

## 📈 Cost Analysis

| Service | Monthly Cost | Usage Limit |
|---------|-------------|-------------|
| **Google Speech** | **$0.00** | **60 minutes** |
| OpenAI Whisper | $3.60+ | Pay per use |
| **Savings** | **$3.60/month** | **Perfect for beta!** |

## 🤝 Contributing

### **Development Setup**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

### **Code Standards**
- Follow Swift naming conventions
- Add comprehensive documentation
- Include unit tests for new features
- Maintain clean architecture

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google Cloud Speech-to-Text API
- Apple Speech Framework
- SwiftUI and Combine frameworks
- Open source community

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review console logs
- Create an issue on GitHub

---

**HeardAI - Making voice interaction seamless and free!** 🎤✨
