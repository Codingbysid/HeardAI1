# HeardAI - Enhanced iOS Voice Assistant

🎤 **Advanced Voice Assistant with Robust Wake Word Detection & Google Speech Integration**

HeardAI is an enhanced iOS voice assistant that provides superior wake word detection, high-accuracy transcription using Google Cloud Speech-to-Text, and seamless Siri integration.

## ✨ Features

### 🎯 **Enhanced Wake Word Detection**
- **Reliable Detection**: "Hey HeardAI" wake word with audio level monitoring
- **Real-time Processing**: Continuous audio monitoring with visual feedback
- **Noise Handling**: Adaptive thresholds for different environments

### 🎵 **Google Speech-to-Text Integration**
- **High Accuracy**: Google Cloud Speech-to-Text API for superior transcription
- **Real-time Processing**: Live audio capture and conversion
- **WAV Format Support**: Proper audio format conversion for API compatibility

### 🤖 **Siri Command Execution**
- **8 Command Types**: Reminders, messages, calls, weather, music, timers, alarms, general
- **Smart Parsing**: Automatic command type detection and parameter extraction
- **Proper Integration**: Uses SiriKit instead of problematic URL schemes

### 📱 **Command Confirmation System**
- **Edit Commands**: Review and modify transcribed commands before execution
- **User Control**: Accept or reject commands with visual feedback
- **Command History**: Track previous commands for reference

## 🚀 Quick Start

### Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- Physical iOS device (audio features don't work in simulator)
- Google Cloud Speech-to-Text API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Codingbysid/HeardAI1.git
   cd HeardAI1
   ```

2. **Open in Xcode**
   ```bash
   open HeardAI.xcodeproj
   ```

3. **Configure API Key**
   - The Google Speech API key is already configured in `Info.plist`
   - Current key: `0ac4a773d6788813e45539a3ee8c4bdf6767faa8`

4. **Build and Run**
   - Select your physical device
   - Build and run the project (⌘+R)

## 📱 Usage

1. **Launch the app** and grant microphone permissions
2. **Say "Hey HeardAI"** to activate the assistant
3. **Speak your command** clearly after the wake word
4. **Review and edit** the transcribed command if needed
5. **Accept or reject** the command for execution

## 🎯 Supported Commands

| Command Type | Examples |
|-------------|----------|
| **Reminders** | "remind me to call mom", "set reminder for meeting" |
| **Messages** | "send message to John", "text Sarah hello" |
| **Calls** | "call dad", "phone mom" |
| **Weather** | "what's the weather", "weather forecast" |
| **Music** | "play music", "play Bohemian Rhapsody by Queen" |
| **Timers** | "set timer for 5 minutes", "timer 10 minutes" |
| **Alarms** | "set alarm for 7 AM", "wake me up at 8" |
| **General** | "what time is it", "open settings" |

## 🛠️ Technical Architecture

### Core Services
- **AudioManager**: Handles wake word detection and audio processing
- **WhisperService**: Google Speech-to-Text integration
- **SiriService**: Command parsing and Siri execution
- **SpeechRecognizer**: On-device speech recognition fallback

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Audio capture and processing
- **Google Cloud Speech-to-Text**: High-accuracy transcription
- **SiriKit**: Proper Siri integration with intents
- **Combine**: Reactive programming for state management

## 🔧 Configuration

### Required Permissions
```xml
<key>NSMicrophoneUsageDescription</key>
<string>HeardAI needs microphone access to listen for voice commands and the wake word "Hey HeardAI".</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>HeardAI uses speech recognition to accurately transcribe your voice commands before sending them to Siri.</string>
```

### Build Settings
- **iOS Deployment Target**: 16.0
- **Swift Language Version**: Swift 5
- **Enable Bitcode**: No

## 🧪 Testing

### Manual Testing
1. Wake word detection in quiet environment
2. Wake word detection in noisy environment
3. Command transcription accuracy
4. Siri command execution
5. Command confirmation flow

### Demo Mode
- Use the "Test Command (Demo)" button to simulate wake word detection
- Test the command confirmation system without voice input

## 🚨 Troubleshooting

### Common Issues

**"Speech recognition not available"**
- Ensure testing on physical device (not simulator)
- Check speech recognition permissions
- Verify internet connectivity

**"Google Speech API error"**
- Verify API key is valid and active
- Check network connectivity
- Ensure API quotas haven't been exceeded

**"Wake word not detected"**
- Speak clearly and at normal volume
- Ensure microphone permissions are granted
- Check that the app is in the foreground

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Cloud** for the Speech-to-Text API
- **Apple** for Speech Framework and SiriKit
- **SwiftUI** community for UI best practices

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Codingbysid/HeardAI1/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Codingbysid/HeardAI1/discussions)

---

Made with ❤️ for the iOS community

⭐ Star this repository if you find it helpful!
