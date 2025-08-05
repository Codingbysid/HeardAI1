import Foundation
import AVFoundation
import Speech
import Combine

class AudioManager: ObservableObject {
    @Published var isListening = false
    @Published var isWakeWordDetected = false
    @Published var audioLevel: Float = 0.0
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private let wakeWord = "hey heardai"
    private var audioBuffer = Data()
    private var isRecordingCommand = false
    
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
        guard !isListening else { return }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine?.start()
            isListening = true
            print("Started listening for wake word")
        } catch {
            print("Failed to start audio engine: \(error)")
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
        
        DispatchQueue.main.async {
            self.audioLevel = average
        }
        
        // Convert buffer to data for wake word detection
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
        audioBuffer.append(data)
        
        // Check for wake word every 2 seconds
        if audioBuffer.count > 32000 { // ~2 seconds at 16kHz
            checkForWakeWord()
            audioBuffer.removeAll()
        }
    }
    
    private func checkForWakeWord() {
        // Simple keyword detection - in production, use a more sophisticated approach
        // This is a simplified version for the MVP
        guard let speechRecognizer = speechRecognizer else { return }
        
        let audioData = audioBuffer
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio.wav")
        
        // Convert audio data to WAV format (simplified)
        // In production, use proper audio format conversion
        
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString.lowercased()
                if transcript.contains(self.wakeWord) {
                    DispatchQueue.main.async {
                        self.wakeWordDetected()
                    }
                }
            }
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
        isRecordingCommand = true
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
        // This will be handled by the WhisperService
        // For now, just print the buffer size
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
    }
}
