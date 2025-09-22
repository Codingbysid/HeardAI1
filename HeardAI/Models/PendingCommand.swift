import Foundation

/// Model representing a command awaiting user confirmation
struct PendingCommand: Identifiable, Equatable {
    let id = UUID()
    let originalTranscription: String
    var editedCommand: String
    let timestamp: Date
    let confidence: Float?
    
    init(transcription: String, confidence: Float? = nil) {
        self.originalTranscription = transcription
        self.editedCommand = transcription
        self.timestamp = Date()
        self.confidence = confidence
    }
    
    /// Whether the command has been edited by the user
    var wasEdited: Bool {
        return editedCommand != originalTranscription
    }
    
    /// The final command to be executed
    var finalCommand: String {
        return editedCommand.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if the command is valid (not empty)
    var isValid: Bool {
        return !finalCommand.isEmpty
    }
    
    /// Get command type for UI display
    var commandType: String {
        let command = finalCommand.lowercased()
        
        if command.contains("remind") {
            return "Reminder"
        } else if command.contains("message") || command.contains("text") {
            return "Message"
        } else if command.contains("call") || command.contains("phone") {
            return "Call"
        } else if command.contains("weather") {
            return "Weather"
        } else if command.contains("music") || command.contains("play") {
            return "Music"
        } else if command.contains("timer") {
            return "Timer"
        } else if command.contains("alarm") {
            return "Alarm"
        } else {
            return "General"
        }
    }
    
    /// Get icon for command type
    var commandIcon: String {
        let command = finalCommand.lowercased()
        
        if command.contains("remind") {
            return "bell.fill"
        } else if command.contains("message") || command.contains("text") {
            return "message.fill"
        } else if command.contains("call") || command.contains("phone") {
            return "phone.fill"
        } else if command.contains("weather") {
            return "cloud.sun.fill"
        } else if command.contains("music") || command.contains("play") {
            return "music.note"
        } else if command.contains("timer") {
            return "timer"
        } else if command.contains("alarm") {
            return "alarm.fill"
        } else {
            return "bubble.left.fill"
        }
    }
}
