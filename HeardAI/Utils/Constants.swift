import Foundation

/// Application-wide constants for HeardAI
/// Centralized configuration to follow DRY principle and improve maintainability
enum Constants {
    
    // MARK: - Audio Configuration
    
    enum Audio {
        /// Standard sample rate for audio processing (16kHz)
        static let sampleRate: Double = 16000
        
        /// Number of audio channels (mono)
        static let channels: Int = 1
        
        /// Audio bit depth for processing
        static let bitDepth: Int = 16
        
        /// Audio buffer size for real-time processing
        static let bufferSize: Int = 1024
        
        /// Maximum audio buffer duration in seconds
        static let maxBufferDuration: TimeInterval = 4.0
        
        /// Command recording duration in seconds
        static let commandRecordingDuration: TimeInterval = 5.0
        
        /// Reduced recording duration for low power mode
        static let lowPowerRecordingDuration: TimeInterval = 3.0
        
        /// Audio level threshold for silence detection
        static let silenceThreshold: Float = 0.01
        
        /// Maximum audio level history size for smoothing
        static let audioLevelHistorySize: Int = 10
    }
    
    // MARK: - Wake Word Configuration
    
    enum WakeWord {
        /// Primary wake word phrase
        static let primary = "hey heardai"
        
        /// Alternative wake word phrases
        static let alternatives = ["hey heard ai", "hey heard", "heard ai"]
        
        /// Confidence threshold for wake word detection (0.0 to 1.0)
        static let confidenceThreshold: Float = 0.7
        
        /// Required consecutive detections before triggering
        static let requiredConsecutiveDetections = 2
        
        /// Processing interval between wake word checks
        static let processingInterval: TimeInterval = 1.0
    }
    
    // MARK: - API Configuration
    
    enum API {
        /// Google Speech-to-Text API endpoint
        static let googleSpeechURL = "https://speech.googleapis.com/v1/speech:recognize"
        
        /// Environment variable key for Google Speech API key
        static let googleSpeechAPIKeyEnvVar = "GOOGLE_SPEECH_API_KEY"
        
        /// Info.plist key for Google Speech API key
        static let googleSpeechAPIKeyPlistKey = "GOOGLE_SPEECH_API_KEY"
        
        /// Request timeout for API calls
        static let requestTimeout: TimeInterval = 30.0
        
        /// Maximum audio file size for API (10MB)
        static let maxAudioFileSize = 10 * 1024 * 1024
    }
    
    // MARK: - UI Configuration
    
    enum UI {
        /// Maximum number of commands to keep in history
        static let maxCommandHistory = 10
        
        /// Command confirmation timeout in seconds
        static let confirmationTimeout: TimeInterval = 30.0
        
        /// Animation duration for UI transitions
        static let animationDuration: TimeInterval = 0.3
        
        /// Corner radius for cards and buttons
        static let cornerRadius: CGFloat = 12.0
        
        /// Standard padding for UI elements
        static let standardPadding: CGFloat = 16.0
    }
    
    // MARK: - Performance Configuration
    
    enum Performance {
        /// Performance monitoring update interval
        static let monitoringInterval: TimeInterval = 1.0
        
        /// Maximum number of performance data points to keep
        static let maxPerformanceHistory = 100
        
        /// Battery level threshold for low power mode
        static let lowBatteryThreshold: Float = 0.2
        
        /// CPU usage threshold for performance warnings
        static let highCPUThreshold: Float = 0.5
        
        /// Memory usage threshold for performance warnings
        static let highMemoryThreshold: Float = 0.3
    }
    
    // MARK: - File System
    
    enum FileSystem {
        /// Temporary file prefix for audio files
        static let tempAudioFilePrefix = "heardai_audio_"
        
        /// Temporary file extension for audio files
        static let tempAudioFileExtension = "wav"
        
        /// Maximum temporary file age before cleanup (1 hour)
        static let maxTempFileAge: TimeInterval = 3600
    }
    
    // MARK: - Notification Names
    
    enum Notifications {
        /// Posted when a command is ready for user confirmation
        static let commandReadyForConfirmation = Notification.Name("commandReadyForConfirmation")
        
        /// Posted when app enters low power mode
        static let lowPowerModeEnabled = Notification.Name("lowPowerModeEnabled")
        
        /// Posted when app exits low power mode
        static let lowPowerModeDisabled = Notification.Name("lowPowerModeDisabled")
    }
    
    // MARK: - Error Messages
    
    enum ErrorMessages {
        static let audioSessionFailed = "Failed to configure audio session"
        static let speechRecognitionUnavailable = "Speech recognition is not available"
        static let microphonePermissionDenied = "Microphone permission is required"
        static let speechPermissionDenied = "Speech recognition permission is required"
        static let apiKeyMissing = "API key is missing or invalid"
        static let networkError = "Network connection error"
        static let transcriptionFailed = "Failed to transcribe audio"
        static let siriUnavailable = "Siri is not available"
    }
    
    // MARK: - Success Messages
    
    enum SuccessMessages {
        static let audioSessionConfigured = "Audio session configured successfully"
        static let speechRecognitionAuthorized = "Speech recognition authorized"
        static let wakeWordDetected = "Wake word detected"
        static let commandTranscribed = "Command transcribed successfully"
        static let commandExecuted = "Command executed successfully"
        static let resourcesCleanedUp = "Resources cleaned up successfully"
    }
}
