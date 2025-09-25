import Foundation
import Speech
import AVFoundation

/// Real-time wake word detection service for HeardAI
/// 
/// Uses Apple's Speech framework for accurate wake word detection
/// Replaces the simulated detection with actual speech recognition
class WakeWordDetector: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether wake word detection is currently active
    @Published var isDetecting = false
    
    /// The most recently detected wake word
    @Published var detectedWakeWord = ""
    
    /// Current error message, if any
    @Published var error: String?
    
    // MARK: - Private Properties
    
    /// Speech recognizer for wake word detection
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    /// Active recognition request
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Active recognition task
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Audio engine for continuous monitoring
    private var audioEngine: AVAudioEngine?
    
    /// Input node for audio capture
    private var inputNode: AVAudioInputNode?
    
    /// Wake word phrases to detect
    private let wakeWords = ["hey heardai", "hey heard ai", "heardai", "heard ai"]
    
    /// Confidence threshold for wake word detection
    private let confidenceThreshold: Float = 0.7
    
    /// Minimum audio level to trigger recognition
    private let audioLevelThreshold: Float = 0.01
    
    /// Callback for wake word detection
    private var onWakeWordDetected: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        guard speechRecognizer != nil else {
            error = "Speech recognition not available for this locale"
            return
        }
    }
    
    // MARK: - Public Methods
    
    /// Starts continuous wake word detection
    /// - Parameter onDetected: Callback called when wake word is detected
    func startDetection(onDetected: @escaping () -> Void) {
        guard !isDetecting else { return }
        
        onWakeWordDetected = onDetected
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.startAudioEngine()
                case .denied, .restricted, .notDetermined:
                    self?.error = "Speech recognition permission denied"
                @unknown default:
                    self?.error = "Unknown speech recognition authorization status"
                }
            }
        }
    }
    
    /// Stops wake word detection
    func stopDetection() {
        guard isDetecting else { return }
        
        // Stop audio engine
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove audio tap
        if let inputNode = inputNode {
            inputNode.removeTap(onBus: 0)
        }
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Reset state
        audioEngine = nil
        inputNode = nil
        isDetecting = false
        onWakeWordDetected = nil
        
        print("🛑 Wake word detection stopped")
    }
    
    // MARK: - Private Methods
    
    private func startAudioEngine() {
        // Create audio engine
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else {
            error = "Failed to get audio input node"
            return
        }
        
        // Get audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎵 Wake word detection format: \(recordingFormat)")
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            error = "Failed to create speech recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Install audio tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.handleRecognitionResult(result: result, error: error)
        }
        
        // Start audio engine
        do {
            try audioEngine?.start()
            isDetecting = true
            print("✅ Wake word detection started")
        } catch {
            self.error = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Check audio level
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        let average = sum / Float(frameLength)
        
        // Only process if audio level is sufficient
        guard average > audioLevelThreshold else { return }
        
        // Append audio to recognition request
        recognitionRequest?.append(buffer)
    }
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            print("🔴 Speech recognition error: \(error.localizedDescription)")
            return
        }
        
        guard let result = result else { return }
        
        let transcription = result.bestTranscription.formattedString.lowercased()
        print("🔍 Speech recognition: '\(transcription)' (confidence: \(result.bestTranscription.averageConfidence))")
        
        // Check for wake words
        for wakeWord in wakeWords {
            if transcription.contains(wakeWord) && result.bestTranscription.averageConfidence >= confidenceThreshold {
                print("✅ Wake word detected: '\(wakeWord)' (confidence: \(result.bestTranscription.averageConfidence))")
                
                DispatchQueue.main.async {
                    self.detectedWakeWord = wakeWord
                    self.onWakeWordDetected?()
                }
                
                // Stop current recognition and restart
                recognitionTask?.cancel()
                startNewRecognitionTask()
                break
            }
        }
    }
    
    private func startNewRecognitionTask() {
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start new recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.handleRecognitionResult(result: result, error: error)
        }
    }
}

// MARK: - Error Types

enum WakeWordDetectorError: Error, LocalizedError {
    case permissionDenied
    case audioEngineFailed
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .audioEngineFailed:
            return "Failed to start audio engine"
        case .recognitionFailed:
            return "Speech recognition failed"
        }
    }
}
