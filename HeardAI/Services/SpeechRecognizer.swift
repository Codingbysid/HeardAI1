import Foundation
import Speech
import Combine

class SpeechRecognizer: ObservableObject {
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var isTranscribing = false
    @Published var error: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    var onTranscriptionComplete: ((String) -> Void)?
    
    init() {
        requestPermission()
    }
    
    private func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    self?.error = "Speech recognition permission denied"
                @unknown default:
                    self?.error = "Speech recognition permission unknown"
                }
            }
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        // Reset state
        transcribedText = ""
        error = nil
        isTranscribing = false
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioEngine = AVAudioEngine()
            guard let inputNode = audioEngine?.inputNode else {
                error = "Audio input not available"
                return
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                error = "Unable to create speech recognition request"
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine?.prepare()
            try audioEngine?.start()
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                        self.stopListening()
                    }
                    return
                }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                    
                    if result.isFinal {
                        DispatchQueue.main.async {
                            self.onTranscriptionComplete?(self.transcribedText)
                            self.stopListening()
                        }
                    }
                }
            }
            
            isListening = true
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func stopListening() {
        // Safely stop audio engine
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            // Safely remove tap
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Reset references
        audioEngine = nil
        
        // Reset state
        isListening = false
        isTranscribing = false
        
        print("Speech recognizer resources cleaned up successfully")
    }
    
    func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let speechRecognizer = speechRecognizer else {
            completion(.failure(SpeechRecognizerError.recognizerNotAvailable))
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result, result.isFinal {
                completion(.success(result.bestTranscription.formattedString))
            }
        }
    }
}

enum SpeechRecognizerError: Error {
    case recognizerNotAvailable
    case permissionDenied
    case audioEngineError
}
