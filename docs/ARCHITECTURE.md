# HeardAI Architecture Documentation

## 🏗️ System Overview

HeardAI is built with a modular, service-oriented architecture that separates concerns and promotes maintainability. The app follows the MVVM (Model-View-ViewModel) pattern with SwiftUI and uses Combine for reactive programming.

## 📁 Project Structure

```
HeardAI/
├── HeardAIApp.swift              # Main app entry point
├── HeardAI/
│   ├── Services/                 # Business logic and external integrations
│   │   ├── AudioManager.swift            # Core audio processing
│   │   ├── WhisperService.swift          # Google Speech integration
│   │   ├── SiriService.swift             # Siri command execution
│   │   └── SpeechRecognizer.swift        # On-device speech recognition
│   ├── Views/                    # SwiftUI views and UI components
│   │   └── ContentView.swift             # Main UI with command confirmation
│   ├── Utils/                    # Utility classes and helpers
│   │   ├── TestRunner.swift              # Diagnostic testing
│   │   └── FunctionalityTest.swift       # Comprehensive testing
│   ├── Models/                   # Data models (future use)
│   ├── Resources/                # Assets and resources
│   └── Info.plist               # App configuration and permissions
├── docs/                        # Documentation
├── README.md                    # Project overview
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # MIT License
└── .gitignore                   # Git ignore rules
```

## 🔧 Core Services Architecture

### **1. AudioManager**
**Purpose**: Core audio processing and wake word detection

**Key Responsibilities**:
- Manages audio session configuration
- Handles wake word detection
- Records user commands
- Integrates with Google Speech API
- Manages memory and performance

**Dependencies**:
- `WhisperService` (Google Speech)
- `SiriService` (Command execution)

**Key Methods**:
```swift
func startListeningForWakeWord()
func stopListeningForWakeWord()
private func processRecordedCommand()
private func presentCommandForConfirmation(_ transcription: String)
```

### **2. WhisperService**
**Purpose**: Google Cloud Speech-to-Text integration for free transcription

**Key Features**:
- Google Speech API integration
- 60 minutes/month free tier
- Automatic punctuation
- Error handling and retry logic
- Secure API key management

**Key Methods**:
```swift
func transcribeAudio(_ audioData: Data, completion: @escaping (Result<String, Error>) -> Void)
func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void)
private func parseGoogleSpeechResponse(_ data: Data) throws -> String
```

### **3. SiriService**
**Purpose**: Siri command execution and intent handling

**Supported Commands**:
- Reminders (URL scheme)
- Messages (Siri integration)
- Calls (Siri integration)
- Weather (Siri integration)
- Music (Siri integration)
- Timers (Siri integration)
- Alarms (Siri integration)
- General commands (URL scheme)

**Key Methods**:
```swift
func executeCommand(_ command: String)
private func parseCommand(_ command: String) -> SiriCommandType
private func openSiriWithCommand(_ command: String)
```

### **4. SpeechRecognizer**
**Purpose**: On-device speech recognition for fallback

**Key Features**:
- Apple Speech Framework integration
- Offline capability
- Real-time processing
- Privacy-focused

**Key Methods**:
```swift
func startListening()
func stopListening()
private func processAudioBuffer(_ buffer: AVAudioPCMBuffer)
```

## 🎨 UI Architecture

### **SwiftUI Views Hierarchy**
```
UltimateContentView (Main Container)
├── TabView
│   ├── mainVoiceInterface
│   │   ├── WakeWordConfidenceView
│   │   ├── UltimateStatusIndicatorView
│   │   ├── UltimateCommandDisplayView
│   │   ├── SiriResponseView
│   │   └── UltimateCommandHistoryView
│   ├── performanceInterface
│   │   ├── PerformanceOverviewCard
│   │   ├── WakeWordPerformanceCard
│   │   ├── RealTimeMetricsView
│   │   └── PerformanceReportView
│   └── settingsInterface
│       └── UltimateSettingsView
```

### **State Management**
- Uses `@StateObject` for service instances
- Uses `@EnvironmentObject` for dependency injection
- Uses `@Published` properties for reactive updates
- Uses Combine for cross-service communication

## 🔄 Data Flow

### **Wake Word Detection Flow**
```
Audio Input → EnhancedAudioManager → RobustWakeWordDetector
                                    ↓
                              Multiple Detection Methods
                                    ↓
                              Confidence Scoring
                                    ↓
                              Wake Word Detected
                                    ↓
                              Command Recording
                                    ↓
                              Transcription (Whisper + On-device)
                                    ↓
                              Siri Command Execution
```

### **Siri Integration Flow**
```
Command Text → ProperSiriKitService → Command Parsing
                                    ↓
                              Intent Creation
                                    ↓
                              Intent Presentation
                                    ↓
                              Siri Execution
                                    ↓
                              Response Handling
```

## 🚀 Performance Architecture

### **Performance Monitoring**
- Real-time CPU, memory, and battery monitoring
- Historical data tracking
- Performance scoring and recommendations
- Adaptive optimization based on system state

### **Battery Optimization**
- Adaptive wake word check intervals
- Silence detection to reduce processing
- Low power mode detection
- Background processing optimization

### **Memory Management**
- Efficient buffer management
- Automatic cleanup of temporary files
- Memory usage monitoring
- Leak detection and prevention

## 🔒 Security Architecture

### **API Key Management**
- Environment variable storage
- Secure transmission over HTTPS
- No local storage of sensitive data
- API key validation

### **Privacy Protection**
- No voice data storage
- Temporary file cleanup
- Encrypted API communications
- Minimal data collection

## 🧪 Testing Architecture

### **Functionality Testing**
- Comprehensive test suite on app launch
- Audio session testing
- Speech recognition testing
- API key validation
- Permission checking
- File system access testing

### **Performance Testing**
- Real-time metrics collection
- Battery usage monitoring
- Memory leak detection
- Response time measurement

## 🔧 Configuration Management

### **Environment Configuration**
- iOS deployment target: 16.0
- Swift language version: 5.0
- Required frameworks: AVFoundation, Speech, Intents, IntentsUI, Accelerate
- Siri capability enabled

### **Permission Configuration**
- Microphone access
- Speech recognition
- Siri access
- Background audio processing

## 📊 Monitoring and Analytics

### **Real-time Metrics**
- Audio level monitoring
- Wake word confidence tracking
- Performance metrics collection
- Error tracking and reporting

### **User Experience Metrics**
- Wake word detection accuracy
- Command transcription success rate
- Siri integration success rate
- App responsiveness metrics

## 🔮 Future Architecture Considerations

### **Scalability**
- Modular service architecture for easy extension
- Plugin system for additional wake word methods
- Configurable command types
- Multi-language support preparation

### **Maintainability**
- Clear separation of concerns
- Comprehensive documentation
- Consistent coding standards
- Extensive error handling

### **Extensibility**
- Service-oriented architecture
- Protocol-based interfaces
- Dependency injection
- Event-driven communication

This architecture provides a solid foundation for a production-ready voice assistant with room for future enhancements and improvements. 