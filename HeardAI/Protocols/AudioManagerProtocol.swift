import Foundation
import Combine
import AVFoundation

/// Protocol defining the interface for audio management in HeardAI
/// Provides a consistent interface across different audio manager implementations
protocol AudioManagerProtocol: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the audio manager is currently listening for wake words
    var isListening: Bool { get }
    
    /// Whether a wake word has been detected
    var isWakeWordDetected: Bool { get }
    
    /// Current audio level (0.0 to 1.0)
    var audioLevel: Float { get }
    
    // MARK: - Core Methods
    
    /// Start listening for wake word detection
    func startListeningForWakeWord()
    
    /// Stop listening and clean up resources
    func stopListeningForWakeWord()
}

/// Protocol for speech transcription services
protocol SpeechTranscriptionProtocol: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether transcription is in progress
    var isTranscribing: Bool { get }
    
    /// Last transcribed text
    var transcribedText: String { get }
    
    /// Current error message, if any
    var error: String? { get }
    
    // MARK: - Core Methods
    
    /// Transcribe audio data to text
    /// - Parameters:
    ///   - audioData: Audio data in supported format
    ///   - completion: Completion handler with result
    func transcribeAudio(_ audioData: Data, completion: @escaping (Result<String, Error>) -> Void)
    
    /// Transcribe audio file to text
    /// - Parameters:
    ///   - url: URL of audio file
    ///   - completion: Completion handler with result
    func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void)
}

/// Protocol for Siri command execution
protocol SiriCommandProtocol: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether a command is currently being executed
    var isExecuting: Bool { get }
    
    /// Current error message, if any
    var error: String? { get }
    
    // MARK: - Core Methods
    
    /// Execute a voice command through Siri
    /// - Parameter command: Natural language command to execute
    func executeCommand(_ command: String)
}

/// Protocol for wake word detection
protocol WakeWordDetectorProtocol: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether wake word has been detected
    var isWakeWordDetected: Bool { get }
    
    /// Confidence level of detection (0.0 to 1.0)
    var confidence: Float { get }
    
    /// Detection method used
    var detectionMethod: String { get }
    
    // MARK: - Core Methods
    
    /// Start listening for wake word
    func startListening()
    
    /// Stop listening and clean up
    func stopListening()
    
    /// Reset detection state
    func resetDetection()
}

/// Protocol for performance monitoring
protocol PerformanceMonitorProtocol: ObservableObject {
    
    // MARK: - Performance Data
    
    /// Current performance metrics
    var currentMetrics: PerformanceData { get }
    
    /// Historical performance data
    var historicalMetrics: [PerformanceData] { get }
    
    // MARK: - Core Methods
    
    /// Start performance monitoring
    func startMonitoring()
    
    /// Stop performance monitoring
    func stopMonitoring()
    
    /// Get average performance metrics
    func getAverageMetrics() -> PerformanceData
    
    /// Generate performance report
    func getPerformanceReport() -> PerformanceReport
}

// MARK: - Supporting Types

/// Enumeration of supported command types
enum SiriCommandType {
    case reminder
    case message
    case call
    case weather
    case music
    case timer
    case alarm
    case general
}

/// Audio format specifications for consistent processing
struct AudioFormat {
    static let sampleRate: Double = 16000
    static let channels: Int = 1
    static let bitDepth: Int = 16
    static let bufferSize: Int = 1024
    static let maxBufferDuration: TimeInterval = 4.0 // seconds
    
    /// Maximum buffer size in bytes
    static var maxBufferSize: Int {
        return Int(sampleRate * maxBufferDuration) * channels * (bitDepth / 8)
    }
}

/// Service configuration for consistent setup
struct ServiceConfiguration {
    static let wakeWord = "hey heardai"
    static let alternativeWakeWords = ["hey heard ai", "hey heard", "heard ai"]
    static let commandRecordingDuration: TimeInterval = 5.0
    static let lowPowerCommandDuration: TimeInterval = 3.0
    static let confidenceThreshold: Float = 0.7
}
