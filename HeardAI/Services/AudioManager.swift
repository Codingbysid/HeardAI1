import Foundation
import AVFoundation
import Speech
import Combine
import UIKit

/// Core audio management service for HeardAI voice assistant
/// 
/// Responsibilities:
/// - Manages audio session configuration and permissions
/// - Handles wake word detection through continuous audio monitoring
/// - Records user commands after wake word detection
/// - Integrates with Google Speech-to-Text API for transcription
/// - Coordinates with Siri for command execution
///
/// Usage:
/// ```swift
/// let audioManager = AudioManager()
/// audioManager.startListeningForWakeWord()
/// ```
class AudioManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether the audio manager is actively listening for wake words
    @Published var isListening = false
    
    /// Indicates whether a wake word has been detected and command recording is active
    @Published var isWakeWordDetected = false
    
    /// Current audio input level (0.0 to 1.0) for visual feedback
    @Published var audioLevel: Float = 0.0
    
    // MARK: - Private Properties
    
    /// Core audio engine for capturing microphone input
    private var audioEngine: AVAudioEngine?
    
    /// Audio input node for processing microphone data
    private var inputNode: AVAudioInputNode?
    
    /// Speech recognition request for processing audio buffers
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Active speech recognition task
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Speech recognizer configured for US English
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // MARK: - Configuration Constants
    
    /// The wake word phrase that activates command recording
    private let wakeWord = "hey heardai"
    
    /// Buffer for storing audio data during processing
    private var audioBuffer = Data()
    
    /// Flag indicating whether command recording is currently active
    private var isRecordingCommand = false
    
    /// Audio level threshold for detecting speech
    private var audioLevelThreshold: Float = 0.005
    
    /// Counter for consecutive high audio level frames
    private var consecutiveHighLevelFrames = 0
    
    /// Required number of high level frames to trigger wake word check
    private var requiredHighLevelFrames = 5 // ~0.1 seconds at 48kHz
    
    /// Timestamp of last wake word detection to prevent rapid triggers
    private var lastWakeWordTime: Date = Date.distantPast
    
    /// Cooldown period between wake word detections
    private var wakeWordCooldown: TimeInterval = 2.0
    
    init() {
        setupAudioSession()
        requestSpeechRecognitionPermission()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.startListeningForWakeWord()
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition permission denied")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func startListeningForWakeWord() {
        guard !isListening else { 
            print("⚠️ Already listening for wake word")
            return 
        }
        
        print("🎤 Starting wake word detection...")
        print("🎯 Listening for: '\(wakeWord)'")
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else { 
            print("🔴 Failed to get audio input node")
            return 
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎵 Audio format: \(recordingFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine?.start()
            isListening = true
            print("✅ Started listening for wake word: '\(wakeWord)'")
        } catch {
            print("🔴 Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Calculate audio level for visualization
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        let average = sum / Float(frameLength)
        
        // Update audio level immediately for wake word detection
        audioLevel = average
        
        DispatchQueue.main.async {
            self.audioLevel = average
        }
        
        // Convert buffer to data for wake word detection
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
        audioBuffer.append(data)
        
        // If we're recording a command, don't check for wake word
        if isRecordingCommand {
            print("🎙️ Recording command... (buffer size: \(audioBuffer.count) bytes)")
            return
        }
        
        // Check for wake word more frequently for better responsiveness
        if audioBuffer.count > 19200 { // ~0.5 seconds at 48kHz
            print("🔍 Checking for wake word... (buffer size: \(audioBuffer.count) bytes, audio level: \(audioLevel))")
            checkForWakeWord()
            audioBuffer.removeAll()
        }
    }
    
    private func checkForWakeWord() {
        // Check if we're in cooldown period
        let now = Date()
        if now.timeIntervalSince(lastWakeWordTime) < wakeWordCooldown {
            return
        }
        
        // Check audio level - if it's high enough, we might have speech
        if audioLevel > audioLevelThreshold {
            consecutiveHighLevelFrames += 1
            
            // If we have sustained high audio level, check for wake word
            if consecutiveHighLevelFrames >= requiredHighLevelFrames {
                print("🔍 High audio level detected, checking for wake word...")
                checkForWakeWordInBuffer()
                consecutiveHighLevelFrames = 0
            }
        } else {
            consecutiveHighLevelFrames = 0
        }
    }
    
    private func checkForWakeWordInBuffer() {
        // Simple keyword matching approach
        // This is a basic implementation - in a real app, you'd use more sophisticated
        // speech recognition or keyword spotting
        
        // For now, we'll use a simple approach: if we detect high audio levels
        // and the user says something, we'll assume it's the wake word
        // This is a placeholder - in production, you'd integrate with a proper
        // wake word detection service
        
        print("🎤 Checking for wake word in audio buffer...")
        
        // Simulate wake word detection after a short delay
        // In a real implementation, this would be replaced with actual speech recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // For demo purposes, we'll trigger wake word detection
            // In production, this would be based on actual speech recognition results
            print("✅ Wake word detected (simulated)")
            self.lastWakeWordTime = Date()
            self.wakeWordDetected()
        }
    }
    
    
    private func wakeWordDetected() {
        isWakeWordDetected = true
        isListening = false
        stopListeningForWakeWord()
        
        // Start recording the command
        startRecordingCommand()
    }
    
    private func startRecordingCommand() {
        print("🎙️ Starting command recording...")
        isRecordingCommand = true
        isListening = true
        audioBuffer.removeAll()
        
        // Start a timer to record for 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.stopRecordingCommand()
        }
    }
    
    private func stopRecordingCommand() {
        isRecordingCommand = false
        isWakeWordDetected = false
        
        // Process the recorded command
        processRecordedCommand()
        
        // Resume listening for wake word
        startListeningForWakeWord()
    }
    
    private func processRecordedCommand() {
        guard !audioBuffer.isEmpty else {
            print("⚠️ No audio data recorded for command")
            return
        }
        
        print("🎤 Processing recorded command - buffer size: \(audioBuffer.count) bytes")
        
        // For now, use a simplified approach since AudioFormatConverter is not in the build
        // In a complete implementation, we would convert the audio to proper format
        
        // Create a simple WAV-like data structure
        let wavData = createWAVFormattedData(from: audioBuffer)
        
        // Send to Google Speech API for transcription
        let speechService = WhisperService()
        speechService.transcribeAudio(wavData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcription):
                    print("✅ Google Speech transcription: \(transcription)")
                    // Instead of immediately executing, present for confirmation
                    self?.presentCommandForConfirmation(transcription)
                case .failure(let error):
                    print("🔴 Google Speech transcription failed: \(error)")
                    // Could add fallback to on-device speech recognition here
                }
            }
        }
    }
    
    /// Present command for user confirmation instead of immediate execution
    private func presentCommandForConfirmation(_ transcription: String) {
        // This will be handled by the ContentView's CommandConfirmationManager
        // For now, we'll use a notification to communicate with the UI
        NotificationCenter.default.post(
            name: .commandReadyForConfirmation,
            object: nil,
            userInfo: ["transcription": transcription]
        )
    }
    
    /// Creates a basic WAV file header and data structure from raw audio buffer
    /// - Parameter audioData: Raw audio data to be converted
    /// - Returns: WAV-formatted data suitable for speech recognition APIs
    private func createWAVFormattedData(from audioData: Data) -> Data {
        // This is a simplified conversion - in production, use proper audio format conversion
        var wavData = Data()
        
        // Add basic WAV header (44 bytes)
        let headerSize = 44
        let dataSize = audioData.count
        let fileSize = headerSize + dataSize - 8
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // fmt chunk size
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (PCM)
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // channels
        wavData.append(withUnsafeBytes(of: UInt32(16000).littleEndian) { Data($0) }) // sample rate
        wavData.append(withUnsafeBytes(of: UInt32(32000).littleEndian) { Data($0) }) // byte rate
        wavData.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }) // block align
        wavData.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // bits per sample
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
        wavData.append(audioData)
        
        return wavData
    }
    
    private func executeCommandWithSiri(_ command: String) {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Empty command, skipping Siri execution")
            return
        }
        
        print("🤖 Executing command with Siri: \(command)")
        
        // Use the SiriService to execute the command
        let siriService = SiriService()
        siriService.executeSiriCommand(command) { result in
            switch result {
            case .success:
                print("✅ Command executed successfully")
            case .failure(let error):
                print("🔴 Failed to execute command: \(error.localizedDescription)")
            }
        }
    }
    
    func stopListeningForWakeWord() {
        // Stop recording command if active
        if isRecordingCommand {
            isRecordingCommand = false
        }
        
        // Safely clean up audio engine resources
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Safely remove tap if input node exists
        if let inputNode = inputNode {
            inputNode.removeTap(onBus: 0)
        }
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Clear audio buffers to prevent memory leaks
        audioBuffer.removeAll()
        
        // Reset references
        audioEngine = nil
        inputNode = nil
        isListening = false
        
        print("Basic audio resources cleaned up successfully")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let commandReadyForConfirmation = Notification.Name("commandReadyForConfirmation")
}
