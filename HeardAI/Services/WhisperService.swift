import Foundation
import Combine

class WhisperService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcribedText = ""
    @Published var error: String?
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    
    init() {
        // In production, load this from secure storage
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    func transcribeAudio(_ audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(WhisperServiceError.missingAPIKey))
            return
        }
        
        DispatchQueue.main.async {
            self.isTranscribing = true
            self.error = nil
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("text\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = WhisperServiceError.noData
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let transcription = String(data: data, encoding: .utf8) {
                            self?.transcribedText = transcription
                            completion(.success(transcription))
                        } else {
                            let error = WhisperServiceError.invalidResponse
                            self?.error = error.localizedDescription
                            completion(.failure(error))
                        }
                    } else {
                        let error = WhisperServiceError.httpError(httpResponse.statusCode)
                        self?.error = error.localizedDescription
                        completion(.failure(error))
                    }
                } else {
                    let error = WhisperServiceError.invalidResponse
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let audioData = try Data(contentsOf: url)
            transcribeAudio(audioData, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}

enum WhisperServiceError: Error, LocalizedError {
    case missingAPIKey
    case noData
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing"
        case .noData:
            return "No data received from API"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
