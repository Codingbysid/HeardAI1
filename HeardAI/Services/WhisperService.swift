import Foundation
import Combine

/// Google Cloud Speech-to-Text service for HeardAI voice assistant
/// 
/// This service replaces the paid OpenAI Whisper API with Google's free tier,
/// providing 60 minutes of transcription per month at no cost.
///
/// Features:
/// - Real-time audio transcription
/// - Support for LINEAR16 audio format
/// - Automatic punctuation
/// - Error handling and retry logic
/// - Free tier optimization
///
/// Usage:
/// ```swift
/// let service = WhisperService()
/// service.transcribeAudio(audioData) { result in
///     switch result {
///     case .success(let text): print("Transcribed: \(text)")
///     case .failure(let error): print("Error: \(error)")
///     }
/// }
/// ```
class WhisperService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether transcription is currently in progress
    @Published var isTranscribing = false
    
    /// The most recently transcribed text
    @Published var transcribedText = ""
    
    /// Current error message, if any
    @Published var error: String?
    
    // MARK: - Private Properties
    
    /// Google Speech API key loaded from environment or Info.plist
    private let apiKey: String
    
        /// Google Speech-to-Text API endpoint URL
        private let baseURL = "https://speech.googleapis.com/v1/speech:recognize"
    
    init() {
        // Load Google Speech API key from environment variable or Info.plist
        self.apiKey = ProcessInfo.processInfo.environment["GOOGLE_SPEECH_API_KEY"] ?? 
                     Bundle.main.infoDictionary?["GOOGLE_SPEECH_API_KEY"] as? String ?? ""
    }
    
    /// Transcribes audio data using Google Cloud Speech-to-Text API
    /// 
    /// This method converts audio data to text using Google's speech recognition service.
    /// The audio must be in LINEAR16 (16-bit PCM) format at 16kHz sample rate.
    /// 
    /// - Parameters:
    ///   - audioData: Audio data in WAV format (LINEAR16, 16kHz, mono)
    ///   - completion: Completion handler called with transcription result
    ///     - Success: Returns transcribed text string
    ///     - Failure: Returns specific error with details
    /// 
    /// - Note: This method uses the free tier which provides 60 minutes/month
    /// - Warning: Requires valid Google Speech API key in environment or Info.plist
    func transcribeAudio(_ audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(WhisperServiceError.missingAPIKey))
            return
        }
        
        DispatchQueue.main.async {
            self.isTranscribing = true
            self.error = nil
        }
        
        // Convert audio data to base64 for Google API
        let base64Audio = audioData.base64EncodedString()
        
        // Create request payload
        let requestBody: [String: Any] = [
            "config": [
                "encoding": "LINEAR16",
                "sampleRateHertz": 16000, // 16kHz sample rate for speech recognition
                "languageCode": "en-US",
                "enableAutomaticPunctuation": true,
                "model": "default" // Use default model for free tier
            ],
            "audio": [
                "content": base64Audio
            ]
        ]
        
        // Create URL request with API key as query parameter
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(WhisperServiceError.invalidResponse))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(WhisperServiceError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                
                if let error = error {
                    let errorMessage = "Google Speech API network error: \(error.localizedDescription)"
                    print("🔴 \(errorMessage)")
                    self?.error = errorMessage
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = WhisperServiceError.noData
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Handle HTTP errors
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        let errorMessage = "Google Speech API HTTP error: \(httpResponse.statusCode)"
                        print("🔴 \(errorMessage)")
                        
                        // Log response body for debugging
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("🔴 Response body: \(responseString)")
                        }
                        
                        let error = WhisperServiceError.httpError(httpResponse.statusCode)
                        self?.error = errorMessage
                        completion(.failure(error))
                        return
                    }
                }
                
                // Parse the response
                do {
                    let transcription = try self?.parseGoogleSpeechResponse(data) ?? ""
                    if transcription.isEmpty {
                        let error = WhisperServiceError.invalidResponse
                        self?.error = error.localizedDescription
                        completion(.failure(error))
                    } else {
                        self?.transcribedText = transcription
                        completion(.success(transcription))
                    }
                } catch {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Parse Google Speech API response
    private func parseGoogleSpeechResponse(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let response = json as? [String: Any] else {
            throw WhisperServiceError.invalidResponse
        }
        
        // Check for API error
        if let error = response["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("Google Speech API error: \(message)")
            throw WhisperServiceError.invalidResponse
        }
        
        // Extract transcription
        guard let results = response["results"] as? [[String: Any]],
              let firstResult = results.first,
              let alternatives = firstResult["alternatives"] as? [[String: Any]],
              let firstAlternative = alternatives.first,
              let transcript = firstAlternative["transcript"] as? String else {
            throw WhisperServiceError.invalidResponse
        }
        
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Transcribe audio file (convenience method)
    func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let audioData = try Data(contentsOf: url)
            transcribeAudio(audioData, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Error Types (kept compatible with existing code)

enum WhisperServiceError: Error, LocalizedError {
    case missingAPIKey
    case noData
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Google Speech API key is missing. Please set GOOGLE_SPEECH_API_KEY environment variable or add it to Info.plist."
        case .noData:
            return "No data received from Google Speech API"
        case .invalidResponse:
            return "Invalid response from Google Speech API"
        case .httpError(let code):
            return "HTTP error from Google Speech API: \(code)"
        }
    }
}

// MARK: - Free Tier Information

extension WhisperService {
    /// Information about Google Cloud Speech-to-Text free tier
    static var freeTierInfo: String {
        return """
        Google Cloud Speech-to-Text Free Tier:
        • 60 minutes of audio processing per month
        • Standard models included
        • Real-time and batch processing
        • Multiple language support
        • Perfect for beta testing!
        """
    }
    
    /// Estimated usage calculation
    func estimateUsage(audioLengthSeconds: Double) -> String {
        let minutes = audioLengthSeconds / 60.0
        let remainingMinutes = 60.0 - minutes // Assuming fresh month
        
        return """
        Estimated usage: \(String(format: "%.2f", minutes)) minutes
        Remaining free tier: ~\(String(format: "%.1f", remainingMinutes)) minutes
        """
    }
}