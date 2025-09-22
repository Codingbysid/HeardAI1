import Foundation
import SwiftUI

/// Centralized error handling for HeardAI
/// Provides consistent error management and user feedback
class ErrorHandler: ObservableObject {
    
    @Published var currentError: HeardAIError?
    @Published var showingError = false
    
    // MARK: - Error Handling
    
    /// Handle an error with appropriate logging and user feedback
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Additional context about where the error occurred
    ///   - showToUser: Whether to show this error to the user
    func handle(_ error: Error, context: String = "", showToUser: Bool = true) {
        let heardAIError = HeardAIError.from(error, context: context)
        
        // Log the error
        Logger.error("Error in \(context): \(heardAIError.localizedDescription)")
        
        // Update UI if needed
        if showToUser {
            DispatchQueue.main.async {
                self.currentError = heardAIError
                self.showingError = true
            }
        }
    }
    
    /// Handle a custom error message
    /// - Parameters:
    ///   - message: Custom error message
    ///   - category: Error category
    ///   - showToUser: Whether to show this error to the user
    func handleCustomError(_ message: String, category: ErrorCategory = .general, showToUser: Bool = true) {
        let error = HeardAIError.custom(message, category: category)
        
        Logger.error("Custom error (\(category)): \(message)")
        
        if showToUser {
            DispatchQueue.main.async {
                self.currentError = error
                self.showingError = true
            }
        }
    }
    
    /// Clear current error
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showingError = false
        }
    }
    
    /// Check if there's a critical error that should stop app functionality
    var hasCriticalError: Bool {
        guard let error = currentError else { return false }
        return error.isCritical
    }
}

// MARK: - HeardAI Error Types

enum HeardAIError: LocalizedError, Identifiable {
    case audioSessionFailed(String)
    case speechRecognitionUnavailable
    case speechRecognitionFailed(String)
    case apiKeyMissing(String)
    case networkError(String)
    case transcriptionFailed(String)
    case siriUnavailable
    case siriExecutionFailed(String)
    case permissionDenied(String)
    case fileSystemError(String)
    case custom(String, category: ErrorCategory)
    
    var id: String {
        return errorDescription ?? "unknown_error"
    }
    
    var errorDescription: String? {
        switch self {
        case .audioSessionFailed(let message):
            return "Audio session failed: \(message)"
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available on this device"
        case .speechRecognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        case .apiKeyMissing(let service):
            return "\(service) API key is missing. Please check your configuration."
        case .networkError(let message):
            return "Network error: \(message)"
        case .transcriptionFailed(let message):
            return "Voice transcription failed: \(message)"
        case .siriUnavailable:
            return "Siri is not available on this device"
        case .siriExecutionFailed(let message):
            return "Failed to execute Siri command: \(message)"
        case .permissionDenied(let permission):
            return "\(permission) permission is required for HeardAI to work properly"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .custom(let message, _):
            return message
        }
    }
    
    var isCritical: Bool {
        switch self {
        case .audioSessionFailed, .speechRecognitionUnavailable, .apiKeyMissing, .permissionDenied:
            return true
        default:
            return false
        }
    }
    
    var category: ErrorCategory {
        switch self {
        case .audioSessionFailed:
            return .audio
        case .speechRecognitionUnavailable, .speechRecognitionFailed, .transcriptionFailed:
            return .speech
        case .apiKeyMissing, .networkError:
            return .network
        case .siriUnavailable, .siriExecutionFailed:
            return .siri
        case .permissionDenied:
            return .permissions
        case .fileSystemError:
            return .system
        case .custom(_, let category):
            return category
        }
    }
    
    /// Create HeardAIError from any Error
    static func from(_ error: Error, context: String = "") -> HeardAIError {
        if let heardAIError = error as? HeardAIError {
            return heardAIError
        }
        
        // Convert common errors to HeardAI errors
        let errorMessage = error.localizedDescription
        
        if errorMessage.contains("network") || errorMessage.contains("internet") {
            return .networkError(errorMessage)
        } else if errorMessage.contains("permission") || errorMessage.contains("denied") {
            return .permissionDenied(errorMessage)
        } else if errorMessage.contains("audio") || errorMessage.contains("microphone") {
            return .audioSessionFailed(errorMessage)
        } else if errorMessage.contains("speech") || errorMessage.contains("recognition") {
            return .speechRecognitionFailed(errorMessage)
        } else {
            return .custom(errorMessage, category: .general)
        }
    }
}

// MARK: - Error Categories

enum ErrorCategory: String, CaseIterable {
    case audio = "Audio"
    case speech = "Speech"
    case siri = "Siri"
    case network = "Network"
    case permissions = "Permissions"
    case system = "System"
    case general = "General"
}

// MARK: - Error Recovery Suggestions

extension HeardAIError {
    var recoverySuggestion: String {
        switch self {
        case .audioSessionFailed:
            return "Check microphone permissions and ensure no other apps are using audio."
        case .speechRecognitionUnavailable:
            return "Speech recognition requires a physical device with iOS 16.0 or later."
        case .speechRecognitionFailed:
            return "Try speaking more clearly or check your internet connection."
        case .apiKeyMissing:
            return "Add your Google Speech API key to the app configuration."
        case .networkError:
            return "Check your internet connection and try again."
        case .transcriptionFailed:
            return "Try speaking more clearly or check your microphone."
        case .siriUnavailable:
            return "Enable Siri in device settings."
        case .siriExecutionFailed:
            return "Try a simpler command or check Siri permissions."
        case .permissionDenied:
            return "Grant the required permission in device settings."
        case .fileSystemError:
            return "Check available storage space."
        case .custom(_, _):
            return "Please try again or restart the app."
        }
    }
}
