import Foundation
import UIKit

/// Comprehensive system metrics monitoring utility
/// Provides real CPU, memory, network, and battery monitoring
class SystemMetrics {
    
    // MARK: - CPU Monitoring
    
    /// Get real-time CPU usage as percentage (0.0 to 1.0)
    static func getCPUUsage() -> Float {
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
        
        guard kerr == KERN_SUCCESS else { return 0.0 }
        
        // Get thread information for more accurate CPU usage
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        
        let threadResult = task_threads(mach_task_self_, &threadList, &threadCount)
        guard threadResult == KERN_SUCCESS, let threads = threadList else {
            return Float(info.user_time.seconds + info.system_time.seconds) / 100.0
        }
        
        var totalCPUUsage: Float = 0.0
        
        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            
            let threadResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }
            
            if threadResult == KERN_SUCCESS {
                totalCPUUsage += Float(threadInfo.cpu_usage) / Float(TH_USAGE_SCALE)
            }
        }
        
        // Clean up thread list
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount * MemoryLayout<thread_t>.size))
        
        return min(totalCPUUsage, 1.0)
    }
    
    // MARK: - Memory Monitoring
    
    /// Get current memory usage information
    static func getMemoryUsage() -> MemoryInfo {
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
        
        guard kerr == KERN_SUCCESS else {
            return MemoryInfo(usedBytes: 0, totalBytes: ProcessInfo.processInfo.physicalMemory, percentage: 0.0)
        }
        
        let usedBytes = info.resident_size
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let percentage = Float(usedBytes) / Float(totalBytes)
        
        return MemoryInfo(usedBytes: usedBytes, totalBytes: totalBytes, percentage: percentage)
    }
    
    // MARK: - Battery Monitoring
    
    /// Get comprehensive battery information
    static func getBatteryInfo() -> BatteryInfo {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        return BatteryInfo(
            level: level,
            state: state,
            isLowPowerMode: isLowPowerMode,
            isCharging: state == .charging || state == .full
        )
    }
    
    // MARK: - Network Monitoring
    
    /// Check network connectivity status
    static func getNetworkStatus() -> NetworkStatus {
        // This is a simplified check - in production you might want to use Network framework
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return NetworkStatus(isConnected: false, connectionType: .none)
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return NetworkStatus(isConnected: false, connectionType: .none)
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isConnected = isReachable && !needsConnection
        
        let connectionType: ConnectionType
        if flags.contains(.isWWAN) {
            connectionType = .cellular
        } else if isConnected {
            connectionType = .wifi
        } else {
            connectionType = .none
        }
        
        return NetworkStatus(isConnected: isConnected, connectionType: connectionType)
    }
    
    // MARK: - Thermal State
    
    /// Get device thermal state
    static func getThermalState() -> ProcessInfo.ThermalState {
        return ProcessInfo.processInfo.thermalState
    }
    
    // MARK: - App State
    
    /// Get current app state information
    static func getAppState() -> AppStateInfo {
        let appState = UIApplication.shared.applicationState
        let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        
        return AppStateInfo(
            state: appState,
            backgroundTimeRemaining: backgroundTimeRemaining,
            isInBackground: appState == .background
        )
    }
}

// MARK: - Data Structures

struct MemoryInfo {
    let usedBytes: UInt64
    let totalBytes: UInt64
    let percentage: Float
    
    var usedMB: Double {
        return Double(usedBytes) / (1024 * 1024)
    }
    
    var totalMB: Double {
        return Double(totalBytes) / (1024 * 1024)
    }
}

struct BatteryInfo {
    let level: Float // 0.0 to 1.0
    let state: UIDevice.BatteryState
    let isLowPowerMode: Bool
    let isCharging: Bool
    
    var levelPercentage: Int {
        return Int(level * 100)
    }
    
    var shouldOptimizeForBattery: Bool {
        return level < 0.2 || isLowPowerMode
    }
}

enum ConnectionType {
    case none
    case wifi
    case cellular
}

struct NetworkStatus {
    let isConnected: Bool
    let connectionType: ConnectionType
}

struct AppStateInfo {
    let state: UIApplication.State
    let backgroundTimeRemaining: TimeInterval
    let isInBackground: Bool
}
