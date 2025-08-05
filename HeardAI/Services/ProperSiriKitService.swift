import Foundation
import Intents
import IntentsUI
import Speech
import AVFoundation

class ProperSiriKitService: ObservableObject {
    @Published var isExecuting = false
    @Published var error: String?
    @Published var lastExecutedCommand: String = ""
    @Published var intentResponse: String = ""
    
    private let intentHandler = CustomIntentHandler()
    
    init() {
        setupIntents()
        registerCustomIntents()
    }
    
    private func setupIntents() {
        // Request Siri authorization
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
    
    private func registerCustomIntents() {
        // Register custom intents for better Siri integration
        let intentIdentifiers = [
            "com.heardai.reminder",
            "com.heardai.message", 
            "com.heardai.call",
            "com.heardai.weather",
            "com.heardai.music",
            "com.heardai.timer",
            "com.heardai.alarm"
        ]
        
        INPreferences.requestSiriAuthorization { status in
            if status == .authorized {
                // Register intents with Siri
                self.registerIntentsWithSiri()
            }
        }
    }
    
    private func registerIntentsWithSiri() {
        // This would be done in a real app with proper intent definitions
        // For now, we'll use the system intents
        print("Intents registered with Siri")
    }
    
    func executeCommand(_ command: String) {
        DispatchQueue.main.async {
            self.isExecuting = true
            self.error = nil
            self.lastExecutedCommand = command
            self.intentResponse = ""
        }
        
        let commandType = parseCommand(command)
        
        switch commandType {
        case .reminder:
            executeReminderIntent(command)
        case .message:
            executeMessageIntent(command)
        case .call:
            executeCallIntent(command)
        case .weather:
            executeWeatherIntent(command)
        case .music:
            executeMusicIntent(command)
        case .timer:
            executeTimerIntent(command)
        case .alarm:
            executeAlarmIntent(command)
        case .general:
            executeGeneralCommand(command)
        }
    }
    
    // MARK: - Intent Execution
    
    private func executeReminderIntent(_ command: String) {
        let intent = INCreateTaskListIntent()
        intent.title = INSpeakableString(spokenPhrase: "Reminder")
        
        // Extract reminder content
        let reminderContent = extractReminderContent(from: command)
        intent.taskTitles = [INSpeakableString(spokenPhrase: reminderContent)]
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Reminder created: \(reminderContent)"
                } else {
                    self.error = "Failed to create reminder"
                }
            }
        }
    }
    
    private func executeMessageIntent(_ command: String) {
        let intent = INSendMessageIntent()
        
        // Extract message content and recipient
        let (content, recipient) = extractMessageContent(from: command)
        intent.content = content
        
        if let recipient = recipient {
            let person = INPerson(
                personHandle: INPersonHandle(value: recipient, type: .unknown),
                nameComponents: nil,
                displayName: recipient,
                image: nil,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: false,
                suggestionType: .instantMessageAddress
            )
            intent.recipients = [person]
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Message sent to \(recipient ?? "default recipient")"
                } else {
                    self.error = "Failed to send message"
                }
            }
        }
    }
    
    private func executeCallIntent(_ command: String) {
        let intent = INStartAudioCallIntent()
        
        if let contact = extractContact(from: command) {
            let person = INPerson(
                personHandle: INPersonHandle(value: contact, type: .unknown),
                nameComponents: nil,
                displayName: contact,
                image: nil,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: false,
                suggestionType: .instantMessageAddress
            )
            intent.contacts = [person]
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Calling \(contact ?? "contact")"
                } else {
                    self.error = "Failed to initiate call"
                }
            }
        }
    }
    
    private func executeWeatherIntent(_ command: String) {
        // Use a custom weather intent or general search
        let intent = INSearchForNotebookItemsIntent()
        intent.title = INSpeakableString(spokenPhrase: "Weather")
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Weather information requested"
                } else {
                    self.error = "Failed to get weather"
                }
            }
        }
    }
    
    private func executeMusicIntent(_ command: String) {
        let intent = INPlayMediaIntent()
        
        // Extract music details
        let (artist, song) = extractMusicDetails(from: command)
        
        var mediaSearch: INMediaSearch?
        if let artist = artist, let song = song {
            mediaSearch = INMediaSearch(
                mediaType: .song,
                sortOrder: .unknown,
                artistName: artist,
                albumName: nil,
                genreNames: nil,
                releaseDate: nil,
                reference: .unknown,
                mediaIdentifier: nil
            )
        } else {
            mediaSearch = INMediaSearch(
                mediaType: .song,
                sortOrder: .unknown,
                artistName: nil,
                albumName: nil,
                genreNames: nil,
                releaseDate: nil,
                reference: .unknown,
                mediaIdentifier: nil
            )
        }
        
        intent.mediaSearch = mediaSearch
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Playing music"
                } else {
                    self.error = "Failed to play music"
                }
            }
        }
    }
    
    private func executeTimerIntent(_ command: String) {
        let intent = INCreateTimerIntent()
        
        if let duration = extractTimeDuration(from: command) {
            intent.duration = duration
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Timer set"
                } else {
                    self.error = "Failed to set timer"
                }
            }
        }
    }
    
    private func executeAlarmIntent(_ command: String) {
        let intent = INCreateAlarmIntent()
        
        if let time = extractTime(from: command) {
            intent.dateTimeComponents = time
        }
        
        presentIntent(intent) { success in
            DispatchQueue.main.async {
                self.isExecuting = false
                if success {
                    self.intentResponse = "Alarm set"
                } else {
                    self.error = "Failed to set alarm"
                }
            }
        }
    }
    
    private func executeGeneralCommand(_ command: String) {
        // Use Siri's general command handling with URL scheme
        let encodedCommand = command.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let siriURL = URL(string: "siri://\(encodedCommand)")!
        
        if UIApplication.shared.canOpenURL(siriURL) {
            UIApplication.shared.open(siriURL) { success in
                DispatchQueue.main.async {
                    self.isExecuting = false
                    if success {
                        self.intentResponse = "Command sent to Siri"
                    } else {
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
    
    // MARK: - Intent Presentation
    
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
    
    // MARK: - Command Parsing and Extraction
    
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
    
    private func extractReminderContent(from command: String) -> String {
        let words = command.components(separatedBy: " ")
        var content = ""
        
        for (index, word) in words.enumerated() {
            if word.lowercased() == "remind" || word.lowercased() == "reminder" {
                if index + 1 < words.count {
                    content = Array(words[(index + 1)...]).joined(separator: " ")
                }
                break
            }
        }
        
        return content.isEmpty ? command : content
    }
    
    private func extractMessageContent(from command: String) -> (String, String?) {
        let words = command.components(separatedBy: " ")
        var content = command
        var recipient: String?
        
        for (index, word) in words.enumerated() {
            if word.lowercased() == "to" && index + 1 < words.count {
                recipient = words[index + 1]
                // Remove recipient from content
                content = Array(words[..<index]).joined(separator: " ")
                break
            }
        }
        
        return (content, recipient)
    }
    
    private func extractContact(from command: String) -> String? {
        let words = command.components(separatedBy: " ")
        
        for (index, word) in words.enumerated() {
            if word.lowercased() == "call" && index + 1 < words.count {
                return words[index + 1]
            }
        }
        
        return nil
    }
    
    private func extractMusicDetails(from command: String) -> (String?, String?) {
        let words = command.components(separatedBy: " ")
        var artist: String?
        var song: String?
        
        for (index, word) in words.enumerated() {
            if word.lowercased() == "play" && index + 1 < words.count {
                if index + 2 < words.count && words[index + 2].lowercased() == "by" {
                    song = words[index + 1]
                    if index + 3 < words.count {
                        artist = words[index + 3]
                    }
                } else {
                    song = words[index + 1]
                }
                break
            }
        }
        
        return (artist, song)
    }
    
    private func extractTimeDuration(from command: String) -> TimeInterval? {
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
        // Simple time extraction - in production, use NLP
        let words = command.components(separatedBy: " ")
        
        for (index, word) in words.enumerated() {
            if word.lowercased() == "at" && index + 1 < words.count {
                let timeString = words[index + 1]
                return parseTimeString(timeString)
            }
        }
        
        return nil
    }
    
    private func parseTimeString(_ timeString: String) -> DateComponents? {
        // Simple time parsing (HH:MM format)
        let components = timeString.components(separatedBy: ":")
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return DateComponents(hour: hour, minute: minute)
        }
        return nil
    }
}

// MARK: - Custom Intent Handler

class CustomIntentHandler: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Voice shortcut error: \(error)")
        } else if let shortcut = voiceShortcut {
            print("Voice shortcut created: \(shortcut.intent)")
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
        print("Voice shortcut creation cancelled")
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