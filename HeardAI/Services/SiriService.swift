import Foundation
import Intents
import IntentsUI

class SiriService: ObservableObject {
    @Published var isExecuting = false
    @Published var error: String?
    
    func executeSiriCommand(_ command: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async {
            self.isExecuting = true
            self.error = nil
        }
        
        // Create a custom intent for Siri
        let intent = INSendMessageIntent()
        intent.content = command
        
        // For the MVP, we'll use a simplified approach
        // In production, you would use SiriKit with proper intent handling
        
        // Simulate Siri execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            DispatchQueue.main.async {
                self.isExecuting = false
                completion(.success(()))
            }
        }
    }
    
    func openSiriWithCommand(_ command: String) {
        // Create a URL scheme to open Siri with the command
        let encodedCommand = command.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let siriURL = URL(string: "siri://\(encodedCommand)")!
        
        if UIApplication.shared.canOpenURL(siriURL) {
            UIApplication.shared.open(siriURL) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.error = "Failed to open Siri"
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.error = "Siri is not available"
            }
        }
    }
    
    func executeCommand(_ command: String) {
        // This is a simplified implementation for the MVP
        // In a full implementation, you would:
        // 1. Parse the command to determine the intent
        // 2. Create the appropriate SiriKit intent
        // 3. Present the intent to Siri
        
        print("Executing Siri command: \(command)")
        
        // For now, we'll just open Siri with the command
        openSiriWithCommand(command)
    }
}

// Extension to handle different types of Siri commands
extension SiriService {
    func parseCommand(_ command: String) -> SiriCommandType {
        let lowercased = command.lowercased()
        
        if lowercased.contains("set reminder") || lowercased.contains("remind me") {
            return .reminder
        } else if lowercased.contains("send message") || lowercased.contains("text") {
            return .message
        } else if lowercased.contains("call") || lowercased.contains("phone") {
            return .call
        } else if lowercased.contains("weather") {
            return .weather
        } else if lowercased.contains("play music") || lowercased.contains("play") {
            return .music
        } else {
            return .general
        }
    }
}

enum SiriCommandType {
    case reminder
    case message
    case call
    case weather
    case music
    case general
}
