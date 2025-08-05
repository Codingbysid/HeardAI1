import Foundation
import AVFoundation
import Speech
import Combine
import Accelerate

class OptimizedAudioManager: ObservableObject {
    @Published var isListening = false
    @Published var isWakeWordDetected = false
    @Published var audioLevel: Float = 0.0
    @Published var batteryLevel: Float = 0.0
    @Published var performanceMetrics = PerformanceMetrics()
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private let wakeWord = "hey heardai"
    private var audioBuffer = Data()
    private var isRecordingCommand = false
    
    // Performance optimization properties
    private var audioQueue = DispatchQueue(label: "audio.processing", qos: .userInteractive)
    private var wakeWordDetectionQueue = DispatchQueue(label: "wakeword.detection", qos: .background)
    private var performanceTimer: Timer?
    private var lastWakeWordCheck: Date = Date()
    private var wakeWordCheckInterval: TimeInterval = 2.0
    
    // Battery optimization
    private var isLowPowerMode = false
    private var adaptiveCheckInterval: TimeInterval = 2.0
    
    // Audio processing optimization
    private var audioLevelHistory: [Float] = []
    private let maxHistorySize = 10
    private var silenceThreshold: Float = 0.01
    private var isSilent = false
    
    init() {
        setupAudioSession()
        requestSpeechRecognitionPermission()
        setupPerformanceMonitoring()
        checkBatteryStatus()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Set optimal sample rate and buffer size
            try audioSession.setPreferredSampleRate(16000)
            try audioSession.setPreferredIOBufferDuration(0.1)
            
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
    }
    
    private func checkBatteryStatus() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        
        // Adjust performance based on battery level
        if batteryLevel < 0.2 {
            isLowPowerMode = true
            adaptiveCheckInterval = 4.0
            silenceThreshold = 0.02
        } else {
            isLowPowerMode = false
            adaptiveCheckInterval = 2.0
            silenceThreshold = 0.01
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
        guard !isListening else { return }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBufferOptimized(buffer)
        }
        
        do {
            try audioEngine?.start()
            isListening = true
            performanceMetrics.startTime = Date()
            print("Started listening for wake word")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBufferOptimized(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Process audio on background queue
        audioQueue.async { [weak self] in
            self?.calculateAudioLevelOptimized(channelData, frameLength: Int(buffer.frameLength))
            self?.detectSilence(channelData, frameLength: Int(buffer.frameLength))
            self?.updateAudioBuffer(buffer)
        }
    }
    
    private func calculateAudioLevelOptimized(_ channelData: UnsafePointer<Float>, frameLength: Int) {
        // Use Accelerate framework for faster processing
        var maxValue: Float = 0.0
        vDSP_maxv(channelData, 1, &maxValue, vDSP_Length(frameLength))
        
        // Smooth audio level using moving average
        audioLevelHistory.append(maxValue)
        if audioLevelHistory.count > maxHistorySize {
            audioLevelHistory.removeFirst()
        }
        
        let smoothedLevel = audioLevelHistory.reduce(0, +) / Float(audioLevelHistory.count)
        
        DispatchQueue.main.async {
            self.audioLevel = smoothedLevel
        }
    }
    
    private func detectSilence(_ channelData: UnsafePointer<Float>, frameLength: Int) {
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        let wasSilent = isSilent
        isSilent = rms < silenceThreshold
        
        // Only process wake word if not silent (battery optimization)
        if !isSilent && !wasSilent {
            checkForWakeWordOptimized()
        }
    }
    
    private func updateAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
        audioBuffer.append(data)
        
        // Limit buffer size to prevent memory issues
        if audioBuffer.count > 64000 { // ~4 seconds at 16kHz
            audioBuffer.removeFirst(audioBuffer.count - 64000)
        }
    }
    
    private func checkForWakeWordOptimized() {
        let now = Date()
        guard now.timeIntervalSince(lastWakeWordCheck) >= adaptiveCheckInterval else { return }
        
        lastWakeWordCheck = now
        
        // Only process if we have enough audio data
        guard audioBuffer.count > 32000 else { return }
        
        wakeWordDetectionQueue.async { [weak self] in
            self?.performWakeWordDetection()
        }
    }
    
    private func performWakeWordDetection() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        // Create a temporary audio file for processing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio_\(Date().timeIntervalSince1970).wav")
        
        do {
            // Convert audio buffer to WAV format
            try convertAudioBufferToWAV(audioBuffer, outputURL: tempURL)
            
            let recognitionRequest = SFSpeechURLRecognitionRequest(url: tempURL)
            self.recognitionRequest = recognitionRequest
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
                
                if let result = result {
                    let transcript = result.bestTranscription.formattedString.lowercased()
                    if transcript.contains(self.wakeWord) {
                        DispatchQueue.main.async {
                            self.wakeWordDetected()
                        }
                    }
                }
            }
        } catch {
            print("Failed to process wake word detection: \(error)")
        }
    }
    
    private func convertAudioBufferToWAV(_ buffer: Data, outputURL: URL) throws {
        // Convert float audio data to 16-bit PCM
        let int16Data = AudioFormatConverter.convertFloatToInt16(buffer)
        
        // Convert to WAV format
        let wavData = try AudioFormatConverter.convertToWAV(
            audioBuffer: int16Data,
            sampleRate: 16000,
            channels: 1
        )
        
        // Write to file
        try wavData.write(to: outputURL)
    }
    
    private func wakeWordDetected() {
        isWakeWordDetected = true
        isListening = false
        stopListeningForWakeWord()
        
        // Start recording the command with optimized settings
        startRecordingCommandOptimized()
    }
    
    private func startRecordingCommandOptimized() {
        isRecordingCommand = true
        audioBuffer.removeAll()
        
        // Adjust recording duration based on battery level
        let recordingDuration: TimeInterval = isLowPowerMode ? 3.0 : 5.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + recordingDuration) { [weak self] in
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
        // This will be handled by the WhisperService
        print("Recorded command buffer size: \(audioBuffer.count)")
    }
    
    func stopListeningForWakeWord() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
        
        performanceMetrics.endTime = Date()
    }
    
    private func updatePerformanceMetrics() {
        checkBatteryStatus()
        
        // Update performance metrics
        performanceMetrics.audioLevel = audioLevel
        performanceMetrics.batteryLevel = batteryLevel
        performanceMetrics.isLowPowerMode = isLowPowerMode
        performanceMetrics.wakeWordCheckInterval = adaptiveCheckInterval
        
        // Calculate CPU usage (simplified)
        performanceMetrics.cpuUsage = calculateCPUUsage()
        
        // Calculate memory usage
        performanceMetrics.memoryUsage = calculateMemoryUsage()
    }
    
    private func calculateCPUUsage() -> Float {
        // Simplified CPU usage calculation
        // In production, use proper system monitoring
        return Float.random(in: 0.1...0.3) // Placeholder
    }
    
    private func calculateMemoryUsage() -> Float {
        // Simplified memory usage calculation
        // In production, use proper memory monitoring
        return Float.random(in: 0.05...0.15) // Placeholder
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    var startTime: Date = Date()
    var endTime: Date?
    var audioLevel: Float = 0.0
    var batteryLevel: Float = 0.0
    var isLowPowerMode: Bool = false
    var wakeWordCheckInterval: TimeInterval = 2.0
    var cpuUsage: Float = 0.0
    var memoryUsage: Float = 0.0
    
    var sessionDuration: TimeInterval {
        return endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime)
    }
    
    var averageAudioLevel: Float {
        return audioLevel // Simplified for MVP
    }
} 