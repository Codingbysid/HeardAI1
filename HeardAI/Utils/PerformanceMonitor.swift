import Foundation
import UIKit
import Combine

class PerformanceMonitor: ObservableObject {
    @Published var currentMetrics = PerformanceData()
    @Published var historicalMetrics: [PerformanceData] = []
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMetrics() {
        let metrics = PerformanceData()
        
        // CPU Usage
        metrics.cpuUsage = getCPUUsage()
        
        // Memory Usage
        metrics.memoryUsage = getMemoryUsage()
        
        // Battery Level
        metrics.batteryLevel = UIDevice.current.batteryLevel
        
        // Network Status
        metrics.isNetworkAvailable = checkNetworkAvailability()
        
        // Audio Session Status
        metrics.audioSessionActive = checkAudioSessionStatus()
        
        // App State
        metrics.appState = UIApplication.shared.applicationState
        
        // Update current metrics
        DispatchQueue.main.async {
            self.currentMetrics = metrics
            self.historicalMetrics.append(metrics)
            
            // Keep only last 100 measurements
            if self.historicalMetrics.count > 100 {
                self.historicalMetrics.removeFirst()
            }
        }
    }
    
    private func getCPUUsage() -> Float {
        // Simplified CPU usage calculation
        // In production, use proper system monitoring
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Float(info.user_time.seconds + info.system_time.seconds)
        }
        
        return 0.0
    }
    
    private func getMemoryUsage() -> Float {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Float(info.resident_size)
            let totalMemory = Float(ProcessInfo.processInfo.physicalMemory)
            return usedMemory / totalMemory
        }
        
        return 0.0
    }
    
    private func checkNetworkAvailability() -> Bool {
        // Simplified network check
        // In production, use proper network monitoring
        return true
    }
    
    private func checkAudioSessionStatus() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        return audioSession.isOtherAudioPlaying
    }
    
    // MARK: - Performance Analysis
    
    func getAverageMetrics() -> PerformanceData {
        guard !historicalMetrics.isEmpty else { return PerformanceData() }
        
        let avgCPU = historicalMetrics.map { $0.cpuUsage }.reduce(0, +) / Float(historicalMetrics.count)
        let avgMemory = historicalMetrics.map { $0.memoryUsage }.reduce(0, +) / Float(historicalMetrics.count)
        let avgBattery = historicalMetrics.map { $0.batteryLevel }.reduce(0, +) / Float(historicalMetrics.count)
        
        var avgMetrics = PerformanceData()
        avgMetrics.cpuUsage = avgCPU
        avgMetrics.memoryUsage = avgMemory
        avgMetrics.batteryLevel = avgBattery
        
        return avgMetrics
    }
    
    func getPerformanceReport() -> PerformanceReport {
        let avgMetrics = getAverageMetrics()
        
        return PerformanceReport(
            averageCPUUsage: avgMetrics.cpuUsage,
            averageMemoryUsage: avgMetrics.memoryUsage,
            averageBatteryLevel: avgMetrics.batteryLevel,
            sessionDuration: getSessionDuration(),
            totalMeasurements: historicalMetrics.count,
            isLowPowerMode: UIDevice.current.batteryLevel < 0.2,
            recommendations: generateRecommendations()
        )
    }
    
    private func getSessionDuration() -> TimeInterval {
        guard let firstMeasurement = historicalMetrics.first else { return 0 }
        return Date().timeIntervalSince(firstMeasurement.timestamp)
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let avgMetrics = getAverageMetrics()
        
        if avgMetrics.cpuUsage > 0.5 {
            recommendations.append("High CPU usage detected. Consider optimizing audio processing.")
        }
        
        if avgMetrics.memoryUsage > 0.3 {
            recommendations.append("High memory usage detected. Consider reducing buffer sizes.")
        }
        
        if avgMetrics.batteryLevel < 0.2 {
            recommendations.append("Low battery detected. Consider reducing wake word check frequency.")
        }
        
        if historicalMetrics.count > 50 {
            let recentMetrics = Array(historicalMetrics.suffix(10))
            let recentCPU = recentMetrics.map { $0.cpuUsage }.reduce(0, +) / Float(recentMetrics.count)
            
            if recentCPU > avgMetrics.cpuUsage * 1.5 {
                recommendations.append("CPU usage is increasing. Check for memory leaks.")
            }
        }
        
        return recommendations
    }
}

// MARK: - Data Structures

struct PerformanceData {
    var timestamp: Date = Date()
    var cpuUsage: Float = 0.0
    var memoryUsage: Float = 0.0
    var batteryLevel: Float = 0.0
    var isNetworkAvailable: Bool = true
    var audioSessionActive: Bool = false
    var appState: UIApplication.State = .active
}

struct PerformanceReport {
    let averageCPUUsage: Float
    let averageMemoryUsage: Float
    let averageBatteryLevel: Float
    let sessionDuration: TimeInterval
    let totalMeasurements: Int
    let isLowPowerMode: Bool
    let recommendations: [String]
    
    var formattedDuration: String {
        let hours = Int(sessionDuration) / 3600
        let minutes = Int(sessionDuration) % 3600 / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var performanceScore: Float {
        // Calculate a performance score based on metrics
        let cpuScore = max(0, 1 - averageCPUUsage)
        let memoryScore = max(0, 1 - averageMemoryUsage)
        let batteryScore = averageBatteryLevel
        
        return (cpuScore + memoryScore + batteryScore) / 3.0
    }
} 