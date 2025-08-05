import Foundation
import AVFoundation
import Speech
import Accelerate

class RobustWakeWordDetector: ObservableObject {
    @Published var isWakeWordDetected = false
    @Published var confidence: Float = 0.0
    @Published var detectionMethod: String = ""
    @Published var lastDetectionTime: Date?
    
    private let wakeWord = "hey heardai"
    private let alternativeWakeWords = ["hey heard ai", "hey heard", "heard ai"]
    
    // Detection methods
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Audio processing
    private var audioBuffer = Data()
    private var audioLevelHistory: [Float] = []
    private let maxHistorySize = 20
    
    // Confidence scoring
    private var confidenceThreshold: Float = 0.7
    private var consecutiveDetections = 0
    private let requiredConsecutiveDetections = 2
    
    // Performance optimization
    private let processingQueue = DispatchQueue(label: "wakeword.processing", qos: .userInteractive)
    private let detectionQueue = DispatchQueue(label: "wakeword.detection", qos: .background)
    private var lastProcessingTime: Date = Date()
    private let processingInterval: TimeInterval = 1.0
    
    // Noise reduction
    private var noiseFloor: Float = 0.01
    private var signalThreshold: Float = 0.05
    private var isNoisyEnvironment = false
    
    init() {
        setupSpeechRecognition()
        setupAudioProcessing()
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized for wake word detection")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition permission denied")
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func setupAudioProcessing() {
        audioEngine = AVAudioEngine()
        
        guard let inputNode = audioEngine?.inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
    }
    
    func startListening() {
        do {
            try audioEngine?.start()
            print("Started robust wake word detection")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopListening() {
        audioEngine?.stop()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        print("Stopped wake word detection")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        processingQueue.async { [weak self] in
            self?.analyzeAudioBuffer(channelData, frameLength: Int(buffer.frameLength))
        }
    }
    
    private func analyzeAudioBuffer(_ channelData: UnsafePointer<Float>, frameLength: Int) {
        // Calculate audio level
        let audioLevel = calculateAudioLevel(channelData, frameLength: frameLength)
        
        // Update audio level history
        audioLevelHistory.append(audioLevel)
        if audioLevelHistory.count > maxHistorySize {
            audioLevelHistory.removeFirst()
        }
        
        // Detect noise level
        detectNoiseLevel(audioLevel)
        
        // Only process if audio level is above threshold
        if audioLevel > signalThreshold {
            // Convert buffer to data for processing
            let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
            audioBuffer.append(data)
            
            // Check for wake word periodically
            let now = Date()
            if now.timeIntervalSince(lastProcessingTime) >= processingInterval {
                lastProcessingTime = now
                checkForWakeWord()
            }
        }
        
        // Limit buffer size
        if audioBuffer.count > 64000 { // ~4 seconds at 16kHz
            audioBuffer.removeFirst(audioBuffer.count - 64000)
        }
    }
    
    private func calculateAudioLevel(_ channelData: UnsafePointer<Float>, frameLength: Int) -> Float {
        // Use RMS (Root Mean Square) for better level detection
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        // Apply smoothing
        let smoothedLevel = rms * 10.0 // Scale for better visualization
        
        DispatchQueue.main.async {
            self.confidence = min(smoothedLevel, 1.0)
        }
        
        return smoothedLevel
    }
    
    private func detectNoiseLevel(_ audioLevel: Float) {
        let averageLevel = audioLevelHistory.reduce(0, +) / Float(audioLevelHistory.count)
        
        if averageLevel > noiseFloor * 2 {
            isNoisyEnvironment = true
            signalThreshold = noiseFloor * 3
        } else {
            isNoisyEnvironment = false
            signalThreshold = noiseFloor * 2
        }
    }
    
    private func checkForWakeWord() {
        guard audioBuffer.count > 32000 else { return } // At least 2 seconds of audio
        
        detectionQueue.async { [weak self] in
            self?.performWakeWordDetection()
        }
    }
    
    private func performWakeWordDetection() {
        // Method 1: Speech Recognition
        let speechResult = detectWithSpeechRecognition()
        
        // Method 2: Pattern Matching
        let patternResult = detectWithPatternMatching()
        
        // Method 3: Keyword Spotting
        let keywordResult = detectWithKeywordSpotting()
        
        // Combine results for final decision
        let finalResult = combineDetectionResults(speechResult, patternResult, keywordResult)
        
        if finalResult.detected {
            DispatchQueue.main.async {
                self.handleWakeWordDetection(method: finalResult.method, confidence: finalResult.confidence)
            }
        }
    }
    
    private func detectWithSpeechRecognition() -> DetectionResult {
        guard let speechRecognizer = speechRecognizer else {
            return DetectionResult(detected: false, confidence: 0.0, method: "Speech Recognition")
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("wakeword_temp_\(Date().timeIntervalSince1970).wav")
        
        do {
            // Convert audio buffer to WAV format
            let int16Data = AudioFormatConverter.convertFloatToInt16(audioBuffer)
            let wavData = try AudioFormatConverter.convertToWAV(
                audioBuffer: int16Data,
                sampleRate: 16000,
                channels: 1
            )
            try wavData.write(to: tempURL)
            
            let request = SFSpeechURLRecognitionRequest(url: tempURL)
            
            let semaphore = DispatchSemaphore(value: 0)
            var result: DetectionResult = DetectionResult(detected: false, confidence: 0.0, method: "Speech Recognition")
            
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] recognitionResult, error in
                defer {
                    try? FileManager.default.removeItem(at: tempURL)
                    semaphore.signal()
                }
                
                if let error = error {
                    print("Speech recognition error: \(error)")
                    return
                }
                
                if let recognitionResult = recognitionResult {
                    let transcript = recognitionResult.bestTranscription.formattedString.lowercased()
                    let confidence = Float(recognitionResult.bestTranscription.segments.first?.confidence ?? 0.0)
                    
                    // Check for wake word in transcript
                    let detected = self?.checkTranscriptForWakeWord(transcript) ?? false
                    
                    result = DetectionResult(
                        detected: detected,
                        confidence: detected ? confidence : 0.0,
                        method: "Speech Recognition"
                    )
                }
            }
            
            _ = semaphore.wait(timeout: .now() + 3.0)
            return result
            
        } catch {
            print("Failed to process speech recognition: \(error)")
            return DetectionResult(detected: false, confidence: 0.0, method: "Speech Recognition")
        }
    }
    
    private func detectWithPatternMatching() -> DetectionResult {
        // Simple pattern matching for wake word
        // In production, use more sophisticated pattern matching algorithms
        
        let audioData = audioBuffer
        let pattern = "hey heardai".lowercased()
        
        // Convert audio to text using basic pattern matching
        // This is a simplified approach - in production, use proper audio pattern matching
        
        return DetectionResult(detected: false, confidence: 0.0, method: "Pattern Matching")
    }
    
    private func detectWithKeywordSpotting() -> DetectionResult {
        // Keyword spotting using audio features
        // This would use machine learning models in production
        
        let audioFeatures = extractAudioFeatures(audioBuffer)
        let keywordScore = calculateKeywordScore(audioFeatures)
        
        let detected = keywordScore > 0.6
        let confidence = detected ? keywordScore : 0.0
        
        return DetectionResult(
            detected: detected,
            confidence: confidence,
            method: "Keyword Spotting"
        )
    }
    
    private func extractAudioFeatures(_ audioData: Data) -> [Float] {
        // Extract basic audio features for keyword spotting
        // In production, use more sophisticated feature extraction
        
        var features: [Float] = []
        
        // Calculate basic statistics
        let floatArray = audioData.withUnsafeBytes { $0.bindMemory(to: Float.self) }
        
        if floatArray.count > 0 {
            var mean: Float = 0.0
            var variance: Float = 0.0
            var maxValue: Float = 0.0
            var minValue: Float = 0.0
            
            vDSP_meanv(floatArray.baseAddress!, 1, &mean, vDSP_Length(floatArray.count))
            vDSP_maxv(floatArray.baseAddress!, 1, &maxValue, vDSP_Length(floatArray.count))
            vDSP_minv(floatArray.baseAddress!, 1, &minValue, vDSP_Length(floatArray.count))
            
            // Calculate variance
            var squaredValues = [Float](repeating: 0.0, count: floatArray.count)
            vDSP_vsq(floatArray.baseAddress!, 1, &squaredValues, 1, vDSP_Length(floatArray.count))
            vDSP_meanv(&squaredValues, 1, &variance, vDSP_Length(squaredValues.count))
            variance -= mean * mean
            
            features = [mean, variance, maxValue, minValue, Float(floatArray.count)]
        }
        
        return features
    }
    
    private func calculateKeywordScore(_ features: [Float]) -> Float {
        // Simple keyword scoring based on audio features
        // In production, use trained machine learning models
        
        guard features.count >= 5 else { return 0.0 }
        
        let mean = features[0]
        let variance = features[1]
        let maxValue = features[2]
        let minValue = features[3]
        let length = features[4]
        
        // Simple scoring based on audio characteristics
        var score: Float = 0.0
        
        // Check for human speech characteristics
        if mean > 0.01 && mean < 0.5 {
            score += 0.3
        }
        
        if variance > 0.001 && variance < 0.1 {
            score += 0.3
        }
        
        if maxValue > 0.1 {
            score += 0.2
        }
        
        if length > 16000 { // At least 1 second of audio
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    private func checkTranscriptForWakeWord(_ transcript: String) -> Bool {
        // Check for exact wake word match
        if transcript.contains(wakeWord) {
            return true
        }
        
        // Check for alternative wake words
        for alternative in alternativeWakeWords {
            if transcript.contains(alternative) {
                return true
            }
        }
        
        // Check for partial matches with high confidence
        let words = transcript.components(separatedBy: " ")
        let wakeWordParts = wakeWord.components(separatedBy: " ")
        
        var matchCount = 0
        for part in wakeWordParts {
            if words.contains(part) {
                matchCount += 1
            }
        }
        
        // Require at least 2 out of 3 words to match
        return matchCount >= 2
    }
    
    private func combineDetectionResults(_ results: DetectionResult...) -> DetectionResult {
        var totalConfidence: Float = 0.0
        var detectedCount = 0
        var bestMethod = ""
        var bestConfidence: Float = 0.0
        
        for result in results {
            if result.detected {
                detectedCount += 1
                totalConfidence += result.confidence
                
                if result.confidence > bestConfidence {
                    bestConfidence = result.confidence
                    bestMethod = result.method
                }
            }
        }
        
        // Require at least one detection method to be confident
        let detected = detectedCount > 0 && bestConfidence > confidenceThreshold
        let averageConfidence = detectedCount > 0 ? totalConfidence / Float(detectedCount) : 0.0
        
        return DetectionResult(
            detected: detected,
            confidence: averageConfidence,
            method: bestMethod
        )
    }
    
    private func handleWakeWordDetection(method: String, confidence: Float) {
        consecutiveDetections += 1
        
        if consecutiveDetections >= requiredConsecutiveDetections {
            isWakeWordDetected = true
            detectionMethod = method
            lastDetectionTime = Date()
            
            print("Wake word detected with \(method) (confidence: \(confidence))")
            
            // Reset for next detection
            consecutiveDetections = 0
            audioBuffer.removeAll()
        }
    }
    
    func resetDetection() {
        isWakeWordDetected = false
        consecutiveDetections = 0
        audioBuffer.removeAll()
        confidence = 0.0
        detectionMethod = ""
    }
}

// MARK: - Detection Result

struct DetectionResult {
    let detected: Bool
    let confidence: Float
    let method: String
} 