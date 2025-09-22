import Foundation
import os.log

/// Centralized logging utility for HeardAI
/// Provides structured logging with different levels and categories
class Logger {
    
    // MARK: - Log Categories
    
    private static let audioLog = OSLog(subsystem: "com.heardai.app", category: "Audio")
    private static let speechLog = OSLog(subsystem: "com.heardai.app", category: "Speech")
    private static let siriLog = OSLog(subsystem: "com.heardai.app", category: "Siri")
    private static let performanceLog = OSLog(subsystem: "com.heardai.app", category: "Performance")
    private static let generalLog = OSLog(subsystem: "com.heardai.app", category: "General")
    
    // MARK: - Log Levels
    
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fault: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "🔴"
            case .fault: return "💥"
            }
        }
    }
    
    // MARK: - Audio Logging
    
    static func audio(_ message: String, level: LogLevel = .info) {
        let formattedMessage = "\(level.emoji) [Audio] \(message)"
        os_log("%{public}@", log: audioLog, type: level.osLogType, formattedMessage)
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    // MARK: - Speech Recognition Logging
    
    static func speech(_ message: String, level: LogLevel = .info) {
        let formattedMessage = "\(level.emoji) [Speech] \(message)"
        os_log("%{public}@", log: speechLog, type: level.osLogType, formattedMessage)
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    // MARK: - Siri Integration Logging
    
    static func siri(_ message: String, level: LogLevel = .info) {
        let formattedMessage = "\(level.emoji) [Siri] \(message)"
        os_log("%{public}@", log: siriLog, type: level.osLogType, formattedMessage)
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    // MARK: - Performance Logging
    
    static func performance(_ message: String, level: LogLevel = .info) {
        let formattedMessage = "\(level.emoji) [Performance] \(message)"
        os_log("%{public}@", log: performanceLog, type: level.osLogType, formattedMessage)
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    // MARK: - General Logging
    
    static func general(_ message: String, level: LogLevel = .info) {
        let formattedMessage = "\(level.emoji) [General] \(message)"
        os_log("%{public}@", log: generalLog, type: level.osLogType, formattedMessage)
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    // MARK: - Convenience Methods
    
    static func debug(_ message: String, category: String = "General") {
        switch category.lowercased() {
        case "audio": audio(message, level: .debug)
        case "speech": speech(message, level: .debug)
        case "siri": siri(message, level: .debug)
        case "performance": performance(message, level: .debug)
        default: general(message, level: .debug)
        }
    }
    
    static func info(_ message: String, category: String = "General") {
        switch category.lowercased() {
        case "audio": audio(message, level: .info)
        case "speech": speech(message, level: .info)
        case "siri": siri(message, level: .info)
        case "performance": performance(message, level: .info)
        default: general(message, level: .info)
        }
    }
    
    static func warning(_ message: String, category: String = "General") {
        switch category.lowercased() {
        case "audio": audio(message, level: .warning)
        case "speech": speech(message, level: .warning)
        case "siri": siri(message, level: .warning)
        case "performance": performance(message, level: .warning)
        default: general(message, level: .warning)
        }
    }
    
    static func error(_ message: String, category: String = "General") {
        switch category.lowercased() {
        case "audio": audio(message, level: .error)
        case "speech": speech(message, level: .error)
        case "siri": siri(message, level: .error)
        case "performance": performance(message, level: .error)
        default: general(message, level: .error)
        }
    }
    
    // MARK: - Performance Metrics Logging
    
    static func logPerformanceMetrics(cpu: Float, memory: Float, battery: Float) {
        let message = String(format: "CPU: %.1f%%, Memory: %.1f%%, Battery: %.1f%%", 
                           cpu * 100, memory * 100, battery * 100)
        performance(message, level: .debug)
    }
    
    // MARK: - Audio Metrics Logging
    
    static func logAudioMetrics(level: Float, bufferSize: Int, isListening: Bool) {
        let message = String(format: "Audio Level: %.3f, Buffer: %d bytes, Listening: %@", 
                           level, bufferSize, isListening ? "YES" : "NO")
        audio(message, level: .debug)
    }
    
    // MARK: - API Request Logging
    
    static func logAPIRequest(service: String, endpoint: String, success: Bool, responseTime: TimeInterval? = nil) {
        let timeString = responseTime != nil ? String(format: " (%.2fs)", responseTime!) : ""
        let status = success ? "✅" : "🔴"
        let message = "\(status) \(service) API: \(endpoint)\(timeString)"
        speech(message, level: success ? .info : .error)
    }
}
