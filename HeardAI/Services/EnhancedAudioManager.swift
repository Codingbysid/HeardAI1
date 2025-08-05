import Foundation
import AVFoundation
import Speech
import Combine
import Accelerate

class EnhancedAudioManager: ObservableObject {
    @Published var isListening = false
    @Published var isWakeWordDetected = false
    @Published var audioLevel: Float = 0.0
    @Published var batteryLevel: Float = 0.0
    @Published var performanceMetrics = PerformanceMetrics()
    @Published var wakeWordConfidence: Float = 0.0
    @Published var detectionMethod: String = ""
    
    // Services
    private let wakeWordDetector = RobustWakeWordDetector()
    private let siriService = ProperSiriKitService()
    
    // Audio processing
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // Command recording
    private var isRecordingCommand = false
    private var commandAudioBuffer = Data()
    private var commandRecordingTimer: Timer?
    
    // Performance optimization
    private var audioQueue = DispatchQueue(label: "audio.processing", qos: .userInteractive)
    private var performanceTimer: Timer?
    private var lastWakeWordCheck: Date = Date()
    
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
        setupWakeWordDetector()
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
    
    private func setupWakeWordDetector() {
        // Observe wake word detector state
        wakeWordDetector.$isWakeWordDetected
            .sink { [weak self] detected in
                DispatchQueue.main.async {
                    self?.handleWakeWordDetection(detected)
                }
            }
            .store(in: &cancellables)
        
        wakeWordDetector.$confidence
            .sink { [weak self] confidence in
                DispatchQueue.main.async {
                    self?.wakeWordConfidence = confidence
                }
            }
            .store(in: &cancellables)
        
        wakeWordDetector.$detectionMethod
            .sink { [weak self] method in
                DispatchQueue.main.async {
                    self?.detectionMethod = method
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // Start the robust wake word detector
        wakeWordDetector.startListening()
        
        // Also start the enhanced audio processing
        startEnhancedAudioProcessing()
        
        isListening = true
        performanceMetrics.startTime = Date()
        print("Started enhanced listening for wake word")
    }
    
    private func startEnhancedAudioProcessing() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBufferOptimized(buffer)
        }
        
        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start enhanced audio engine: \(error)")
        }
    }
    
    private func processAudioBufferOptimized(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Process audio on background queue
        audioQueue.async { [weak self] in
            self?.calculateAudioLevelOptimized(channelData, frameLength: Int(buffer.frameLength))
            self?.detectSilence(channelData, frameLength: Int(buffer.frameLength))
            self?.updateCommandBuffer(buffer)
        }
    }
    
    private func calculateAudioLevelOptimized(_ channelData: UnsafePointer<Float>, frameLength: Int) {
        // Use Accelerate framework for faster calculations
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
        
        // Only process if not silent (battery optimization)
        if !isSilent && !wasSilent {
            // The wake word detector handles its own processing
        }
    }
    
    private func updateCommandBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isRecordingCommand else { return }
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
        commandAudioBuffer.append(data)
        
        // Limit buffer size to prevent memory issues
        if commandAudioBuffer.count > 64000 { // ~4 seconds at 16kHz
            commandAudioBuffer.removeFirst(commandAudioBuffer.count - 64000)
        }
    }
    
    private func handleWakeWordDetection(_ detected: Bool) {
        if detected {
            isWakeWordDetected = true
            isListening = false
            stopListeningForWakeWord()
            
            // Start recording the command
            startRecordingCommand()
        }
    }
    
    private func startRecordingCommand() {
        isRecordingCommand = true
        commandAudioBuffer.removeAll()
        
        // Start a timer to record for 5 seconds (or 3 seconds in low power mode)
        let recordingDuration: TimeInterval = isLowPowerMode ? 3.0 : 5.0
        
        commandRecordingTimer = Timer.scheduledTimer(withTimeInterval: recordingDuration, repeats: false) { [weak self] _ in
            self?.stopRecordingCommand()
        }
        
        print("Started recording command")
    }
    
    private func stopRecordingCommand() {
        isRecordingCommand = false
        isWakeWordDetected = false
        commandRecordingTimer?.invalidate()
        commandRecordingTimer = nil
        
        // Process the recorded command
        processRecordedCommand()
        
        // Resume listening for wake word
        startListeningForWakeWord()
    }
    
    private func processRecordedCommand() {
        // Send the command audio to Whisper API for transcription
        processCommandWithWhisper()
        
        // Also try on-device transcription as backup
        processCommandWithSpeechRecognition()
    }
    
    private func processCommandWithWhisper() {
        // Convert audio buffer to WAV format
        do {
            let int16Data = AudioFormatConverter.convertFloatToInt16(commandAudioBuffer)
            let wavData = try AudioFormatConverter.convertToWAV(
                audioBuffer: int16Data,
                sampleRate: 16000,
                channels: 1
            )
            
            // Send to Whisper API
            let whisperService = WhisperService()
            whisperService.transcribeAudio(wavData) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let transcription):
                        print("Whisper transcription: \(transcription)")
                        self?.executeCommandWithSiri(transcription)
                    case .failure(let error):
                        print("Whisper transcription failed: \(error)")
                        // Fall back to on-device transcription
                    }
                }
            }
        } catch {
            print("Failed to convert audio for Whisper: \(error)")
        }
    }
    
    private func processCommandWithSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        do {
            let int16Data = AudioFormatConverter.convertFloatToInt16(commandAudioBuffer)
            let wavData = try AudioFormatConverter.convertToWAV(
                audioBuffer: int16Data,
                sampleRate: 16000,
                channels: 1
            )
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("command_temp_\(Date().timeIntervalSince1970).wav")
            try wavData.write(to: tempURL)
            
            let request = SFSpeechURLRecognitionRequest(url: tempURL)
            
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                defer {
                    try? FileManager.default.removeItem(at: tempURL)
                }
                
                if let error = error {
                    print("Speech recognition error: \(error)")
                    return
                }
                
                if let result = result, result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    print("Speech recognition transcription: \(transcription)")
                    self?.executeCommandWithSiri(transcription)
                }
            }
        } catch {
            print("Failed to process command with speech recognition: \(error)")
        }
    }
    
    private func executeCommandWithSiri(_ command: String) {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        print("Executing command with Siri: \(command)")
        siriService.executeCommand(command)
    }
    
    func stopListeningForWakeWord() {
        wakeWordDetector.stopListening()
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        commandRecordingTimer?.invalidate()
        commandRecordingTimer = nil
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