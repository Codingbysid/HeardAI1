import SwiftUI
import AVFoundation

struct EnhancedContentView: View {
    @EnvironmentObject var audioManager: OptimizedAudioManager
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: EnhancedSiriService
    @StateObject private var performanceMonitor = PerformanceMonitor()
    
    @State private var showingSettings = false
    @State private var showingPerformance = false
    @State private var commandHistory: [String] = []
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Interface
            mainInterface
                .tabItem {
                    Image(systemName: "mic.circle.fill")
                    Text("Voice")
                }
                .tag(0)
            
            // Performance Monitor
            performanceInterface
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Performance")
                }
                .tag(1)
            
            // Settings
            settingsInterface
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .onReceive(whisperService.$transcribedText) { text in
            if !text.isEmpty {
                commandHistory.insert(text, at: 0)
                if commandHistory.count > 10 {
                    commandHistory.removeLast()
                }
            }
        }
        .onReceive(audioManager.$isWakeWordDetected) { detected in
            if detected {
                speechRecognizer.startListening()
            }
        }
        .onReceive(speechRecognizer.$transcribedText) { text in
            if !text.isEmpty && speechRecognizer.isListening == false {
                siriService.executeCommand(text)
            }
        }
    }
    
    private var mainInterface: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .scaleEffect(audioManager.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: audioManager.isListening)
                    
                    Text("HeardAI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Say \"Hey HeardAI\" to activate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Enhanced Status Indicator
                EnhancedStatusIndicatorView()
                
                // Command display
                if !whisperService.transcribedText.isEmpty {
                    EnhancedCommandDisplayView(text: whisperService.transcribedText)
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if audioManager.isListening {
                            audioManager.stopListeningForWakeWord()
                        } else {
                            audioManager.startListeningForWakeWord()
                        }
                    }) {
                        HStack {
                            Image(systemName: audioManager.isListening ? "stop.circle.fill" : "play.circle.fill")
                            Text(audioManager.isListening ? "Stop Listening" : "Start Listening")
                        }
                        .padding()
                        .background(audioManager.isListening ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingPerformance = true
                    }) {
                        Image(systemName: "chart.bar")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                
                // Command history
                if !commandHistory.isEmpty {
                    EnhancedCommandHistoryView(history: commandHistory)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPerformance) {
                PerformanceDetailView()
            }
        }
    }
    
    private var performanceInterface: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Performance Overview
                PerformanceOverviewCard()
                
                // Real-time Metrics
                RealTimeMetricsView()
                
                // Performance Report
                PerformanceReportView()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Performance")
        }
    }
    
    private var settingsInterface: some View {
        NavigationView {
            EnhancedSettingsView()
                .navigationTitle("Settings")
        }
    }
}

// MARK: - Enhanced Status Indicator

struct EnhancedStatusIndicatorView: View {
    @EnvironmentObject var audioManager: OptimizedAudioManager
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: EnhancedSiriService
    
    var body: some View {
        VStack(spacing: 15) {
            // Audio level indicator with battery awareness
            if audioManager.isListening {
                EnhancedAudioLevelIndicator(level: audioManager.audioLevel, batteryLevel: audioManager.batteryLevel)
            }
            
            // Status text with performance info
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if audioManager.performanceMetrics.isLowPowerMode {
                        Text("Low Power Mode")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Battery indicator
                BatteryIndicatorView(level: audioManager.batteryLevel)
            }
        }
    }
    
    private var statusColor: Color {
        if siriService.isExecuting {
            return .orange
        } else if whisperService.isTranscribing {
            return .yellow
        } else if audioManager.isListening {
            return .green
        } else {
            return .gray
        }
    }
    
    private var statusText: String {
        if siriService.isExecuting {
            return "Executing Siri command..."
        } else if whisperService.isTranscribing {
            return "Transcribing audio..."
        } else if audioManager.isListening {
            return "Listening for wake word..."
        } else {
            return "Ready"
        }
    }
}

// MARK: - Enhanced Audio Level Indicator

struct EnhancedAudioLevelIndicator: View {
    let level: Float
    let batteryLevel: Float
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(audioColor)
                        .frame(width: 4, height: CGFloat(level * 50) * (1.0 - Double(index) * 0.1))
                        .animation(.easeInOut(duration: 0.1), value: level)
                }
            }
            .frame(height: 50)
            
            Text("Audio Level: \(Int(level * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var audioColor: Color {
        if batteryLevel < 0.2 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Battery Indicator

struct BatteryIndicatorView: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIcon)
                .foregroundColor(batteryColor)
            
            Text("\(Int(level * 100))%")
                .font(.caption)
                .foregroundColor(batteryColor)
        }
    }
    
    private var batteryIcon: String {
        if level > 0.8 {
            return "battery.100"
        } else if level > 0.6 {
            return "battery.75"
        } else if level > 0.4 {
            return "battery.50"
        } else if level > 0.2 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
    
    private var batteryColor: Color {
        if level > 0.5 {
            return .green
        } else if level > 0.2 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Enhanced Command Display

struct EnhancedCommandDisplayView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Command:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Enhanced Command History

struct EnhancedCommandHistoryView: View {
    let history: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Commands:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(history.prefix(5), id: \.self) { command in
                HStack {
                    Image(systemName: "command")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(command)
                        .font(.caption)
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Performance Views

struct PerformanceOverviewCard: View {
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Performance Overview")
                .font(.headline)
            
            HStack(spacing: 20) {
                MetricCard(title: "CPU", value: "\(Int(performanceMonitor.currentMetrics.cpuUsage * 100))%", color: .blue)
                MetricCard(title: "Memory", value: "\(Int(performanceMonitor.currentMetrics.memoryUsage * 100))%", color: .green)
                MetricCard(title: "Battery", value: "\(Int(performanceMonitor.currentMetrics.batteryLevel * 100))%", color: .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RealTimeMetricsView: View {
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Real-time Metrics")
                .font(.headline)
            
            VStack(spacing: 8) {
                MetricRow(label: "CPU Usage", value: performanceMonitor.currentMetrics.cpuUsage, format: "%.1f%%")
                MetricRow(label: "Memory Usage", value: performanceMonitor.currentMetrics.memoryUsage, format: "%.1f%%")
                MetricRow(label: "Battery Level", value: performanceMonitor.currentMetrics.batteryLevel, format: "%.1f%%")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MetricRow: View {
    let label: String
    let value: Float
    let format: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            
            Spacer()
            
            Text(String(format: format, value * 100))
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct PerformanceReportView: View {
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Performance Report")
                .font(.headline)
            
            let report = performanceMonitor.getPerformanceReport()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Duration: \(report.formattedDuration)")
                    .font(.caption)
                
                Text("Performance Score: \(Int(report.performanceScore * 100))%")
                    .font(.caption)
                
                if !report.recommendations.isEmpty {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(report.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Enhanced Settings

struct EnhancedSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section(header: Text("API Configuration")) {
                HStack {
                    Text("OpenAI API Key")
                    Spacer()
                    Text("Configure in Settings")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Permissions")) {
                HStack {
                    Text("Microphone Access")
                    Spacer()
                    Text("Required")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Speech Recognition")
                    Spacer()
                    Text("Required")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Siri Access")
                    Spacer()
                    Text("Required")
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("Performance")) {
                HStack {
                    Text("Low Power Mode")
                    Spacer()
                    Text("Auto")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Wake Word Sensitivity")
                    Spacer()
                    Text("Medium")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Performance Detail View

struct PerformanceDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PerformanceOverviewCard()
                    RealTimeMetricsView()
                    PerformanceReportView()
                }
                .padding()
            }
            .navigationTitle("Performance Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct EnhancedContentView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedContentView()
            .environmentObject(OptimizedAudioManager())
            .environmentObject(SpeechRecognizer())
            .environmentObject(WhisperService())
            .environmentObject(EnhancedSiriService())
    }
} 