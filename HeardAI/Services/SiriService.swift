import Foundation
import Intents
import IntentsUI
import UIKit

class SiriService: ObservableObject {
    @Published var isExecuting = false
    @Published var error: String?
    
    func executeSiriCommand(_ command: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async {
            self.isExecuting = true
            self.error = nil
        }
        
        // Create a custom intent for Siri (for future SiriKit integration)
        _ = INSendMessageIntent(
            recipients: nil,
            outgoingMessageType: .outgoingMessageText,
            content: command,
            speakableGroupName: nil,
            conversationIdentifier: nil,
            serviceName: nil,
            sender: nil,
            attachments: nil
        )
        
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
        DispatchQueue.main.async {
            self.isExecuting = true
            self.error = nil
        }
        
        print("Executing Siri command: \(command)")
        
        // Parse command and execute appropriate action
        let commandType = parseCommand(command)
        
        switch commandType {
        case .reminder:
            executeReminderCommand(command)
        case .message:
            executeMessageCommand(command)
        case .call:
            executeCallCommand(command)
        case .weather:
            openSiriWithCommand(command)
        case .music:
            openSiriWithCommand(command)
        case .timer:
            executeTimerCommand(command)
        case .alarm:
            executeAlarmCommand(command)
        case .general:
            openSiriWithCommand(command)
        }
    }
    
    private func executeReminderCommand(_ command: String) {
        // Extract reminder content and use Siri URL scheme
        let reminderText = command.replacingOccurrences(of: "remind me to ", with: "")
                                  .replacingOccurrences(of: "set reminder ", with: "")
        let encodedText = reminderText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? reminderText
        
        if let url = URL(string: "x-apple-reminderkit://REMCDReminder/\(encodedText)") {
            UIApplication.shared.open(url) { [weak self] success in
                DispatchQueue.main.async {
                    self?.isExecuting = false
                    if !success {
                        self?.openSiriWithCommand(command)
                    }
                }
            }
        } else {
            openSiriWithCommand(command)
        }
    }
    
    private func executeMessageCommand(_ command: String) {
        // Use Siri for message commands
        openSiriWithCommand(command)
    }
    
    private func executeCallCommand(_ command: String) {
        // For now, use Siri as it handles contact resolution better
        openSiriWithCommand(command)
    }
    
    private func executeTimerCommand(_ command: String) {
        // Use Siri for timer commands as it handles natural language well
        openSiriWithCommand(command)
    }
    
    private func executeAlarmCommand(_ command: String) {
        // Use Siri for alarm commands as it handles natural language well
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
    case timer
    case alarm
    case general
}
