import Foundation
import Intents
import IntentsUI
import Speech
import AVFoundation

class EnhancedSiriService: ObservableObject {
    @Published var isExecuting = false
    @Published var error: String?
    @Published var lastExecutedCommand: String = ""
    
    private let intentHandler = IntentHandler()
    
    init() {
        setupIntents()
    }
    
    private func setupIntents() {
        // Register custom intents
        INPreferences.requestSiriAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Siri authorization granted")
                case .denied, .restricted, .notDetermined:
                    print("Siri authorization denied")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func executeCommand(_ command: String) {
        DispatchQueue.main.async {
            self.isExecuting = true
            self.error = nil
            self.lastExecutedCommand = command
        }
        
        let commandType = parseCommand(command)
        
        switch commandType {
        case .reminder:
            executeReminderCommand(command)
        case .message:
            executeMessageCommand(command)
        case .call:
            executeCallCommand(command)
        case .weather:
            executeWeatherCommand(command)
        case .music:
            executeMusicCommand(command)
        case .timer:
            executeTimerCommand(command)
        case .alarm:
            executeAlarmCommand(command)
        case .general:
            executeGeneralCommand(command)
        }
    }
    
    private func executeReminderCommand(_ command: String) {
        let intent = INCreateTaskListIntent()
        intent.title = INSpeakableString(spokenPhrase: "Reminder")
        intent.taskTitles = [INSpeakableString(spokenPhrase: command)]
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to create reminder"
                }
            }
        }
    }
    
    private func executeMessageCommand(_ command: String) {
        let intent = INSendMessageIntent()
        intent.content = command
        
        // Extract recipient if mentioned
        if let recipient = extractRecipient(from: command) {
            intent.recipients = [INPerson(personHandle: INPersonHandle(value: recipient, type: .unknown), nameComponents: nil, displayName: recipient, image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: false, suggestionType: .instantMessageAddress)]
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to send message"
                }
            }
        }
    }
    
    private func executeCallCommand(_ command: String) {
        let intent = INStartAudioCallIntent()
        
        if let contact = extractContact(from: command) {
            intent.contacts = [INPerson(personHandle: INPersonHandle(value: contact, type: .unknown), nameComponents: nil, displayName: contact, image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: false, suggestionType: .instantMessageAddress)]
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to initiate call"
                }
            }
        }
    }
    
    private func executeWeatherCommand(_ command: String) {
        let intent = INSearchForNotebookItemsIntent()
        intent.title = INSpeakableString(spokenPhrase: "Weather")
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to get weather"
                }
            }
        }
    }
    
    private func executeMusicCommand(_ command: String) {
        let intent = INPlayMediaIntent()
        intent.mediaSearch = INMediaSearch(mediaType: .song, sortOrder: .unknown, artistName: nil, albumName: nil, genreNames: nil, releaseDate: nil, reference: .unknown, mediaIdentifier: nil)
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to play music"
                }
            }
        }
    }
    
    private func executeTimerCommand(_ command: String) {
        let intent = INCreateTimerIntent()
        
        // Extract time duration from command
        if let duration = extractTimeDuration(from: command) {
            intent.duration = duration
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to set timer"
                }
            }
        }
    }
    
    private func executeAlarmCommand(_ command: String) {
        let intent = INCreateAlarmIntent()
        
        // Extract time from command
        if let time = extractTime(from: command) {
            intent.dateTimeComponents = time
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if !success {
                    self.error = "Failed to set alarm"
                }
            }
        }
    }
    
    private func executeGeneralCommand(_ command: String) {
        // Use Siri's general command handling
        let encodedCommand = command.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let siriURL = URL(string: "siri://\(encodedCommand)")!
        
        if UIApplication.shared.canOpenURL(siriURL) {
            UIApplication.shared.open(siriURL) { success in
                DispatchQueue.main.async {
                    self.isExecuting = false
                    if !success {
                        self.error = "Failed to execute command"
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isExecuting = false
                self.error = "Siri is not available"
            }
        }
    }
    
    private func presentIntent(_ intent: INIntent, completion: @escaping (Bool) -> Void) {
        let intentViewController = INUIAddVoiceShortcutViewController(intent: intent)
        intentViewController.delegate = intentHandler
        
        // Present the intent view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let rootViewController = window.rootViewController
            rootViewController?.present(intentViewController, animated: true) {
                completion(true)
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: - Command Parsing
    
    private func parseCommand(_ command: String) -> SiriCommandType {
        let lowercased = command.lowercased()
        
        if lowercased.contains("remind") || lowercased.contains("reminder") {
            return .reminder
        } else if lowercased.contains("message") || lowercased.contains("text") || lowercased.contains("send") {
            return .message
        } else if lowercased.contains("call") || lowercased.contains("phone") {
            return .call
        } else if lowercased.contains("weather") {
            return .weather
        } else if lowercased.contains("play") || lowercased.contains("music") || lowercased.contains("song") {
            return .music
        } else if lowercased.contains("timer") || lowercased.contains("set timer") {
            return .timer
        } else if lowercased.contains("alarm") || lowercased.contains("set alarm") {
            return .alarm
        } else {
            return .general
        }
    }
    
    private func extractRecipient(from command: String) -> String? {
        // Simple extraction - in production, use NLP
        let words = command.components(separatedBy: " ")
        for (index, word) in words.enumerated() {
            if word.lowercased() == "to" && index + 1 < words.count {
                return words[index + 1]
            }
        }
        return nil
    }
    
    private func extractContact(from command: String) -> String? {
        // Simple extraction - in production, use NLP
        let words = command.components(separatedBy: " ")
        for (index, word) in words.enumerated() {
            if word.lowercased() == "call" && index + 1 < words.count {
                return words[index + 1]
            }
        }
        return nil
    }
    
    private func extractTimeDuration(from command: String) -> TimeInterval? {
        // Simple extraction - in production, use NLP
        let words = command.components(separatedBy: " ")
        for (index, word) in words.enumerated() {
            if word.lowercased() == "for" && index + 1 < words.count {
                if let number = Int(words[index + 1]) {
                    return TimeInterval(number * 60) // Assume minutes
                }
            }
        }
        return nil
    }
    
    private func extractTime(from command: String) -> DateComponents? {
        // Simple extraction - in production, use NLP
        // This is a simplified version
        return DateComponents()
    }
}

// MARK: - Intent Handler

class IntentHandler: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Voice shortcut error: \(error)")
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Enhanced Command Types

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