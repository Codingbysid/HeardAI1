import SwiftUI
import AVFoundation

struct UltimateContentView: View {
    @EnvironmentObject var audioManager: EnhancedAudioManager
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: ProperSiriKitService
    @StateObject private var performanceMonitor = PerformanceMonitor()
    
    @State private var showingSettings = false
    @State private var showingPerformance = false
    @State private var commandHistory: [String] = []
    @State private var selectedTab = 0
    @State private var showingWakeWordInfo = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Voice Interface
            mainVoiceInterface
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
        .onReceive(siriService.$intentResponse) { response in
            if !response.isEmpty {
                commandHistory.insert("Siri: \(response)", at: 0)
                if commandHistory.count > 10 {
                    commandHistory.removeLast()
                }
            }
        }
    }
    
    private var mainVoiceInterface: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with wake word info
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
                    
                    // Wake word confidence indicator
                    if audioManager.isListening {
                        WakeWordConfidenceView(
                            confidence: audioManager.wakeWordConfidence,
                            method: audioManager.detectionMethod
                        )
                    }
                }
                
                // Enhanced Status Indicator
                UltimateStatusIndicatorView()
                
                // Command display
                if !whisperService.transcribedText.isEmpty {
                    UltimateCommandDisplayView(text: whisperService.transcribedText)
                }
                
                // Siri response display
                if !siriService.intentResponse.isEmpty {
                    SiriResponseView(response: siriService.intentResponse)
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
                        showingWakeWordInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
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
                    UltimateCommandHistoryView(history: commandHistory)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingWakeWordInfo) {
                WakeWordInfoView()
            }
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
                
                // Wake Word Performance
                WakeWordPerformanceCard()
                
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
            UltimateSettingsView()
                .navigationTitle("Settings")
        }
    }
}

// MARK: - Wake Word Confidence View

struct WakeWordConfidenceView: View {
    let confidence: Float
    let method: String
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Wake Word Confidence:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)
            }
            
            if !method.isEmpty {
                HStack {
                    Text("Detection Method:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(method)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Ultimate Status Indicator

struct UltimateStatusIndicatorView: View {
    @EnvironmentObject var audioManager: EnhancedAudioManager
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: ProperSiriKitService
    
    var body: some View {
        VStack(spacing: 15) {
            // Audio level indicator with battery awareness
            if audioManager.isListening {
                UltimateAudioLevelIndicator(
                    level: audioManager.audioLevel,
                    batteryLevel: audioManager.batteryLevel,
                    confidence: audioManager.wakeWordConfidence
                )
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
                    
                    if !audioManager.detectionMethod.isEmpty {
                        Text("Method: \(audioManager.detectionMethod)")
                            .font(.caption)
                            .foregroundColor(.blue)
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

// MARK: - Ultimate Audio Level Indicator

struct UltimateAudioLevelIndicator: View {
    let level: Float
    let batteryLevel: Float
    let confidence: Float
    
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
            
            HStack {
                Text("Audio Level: \(Int(level * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Confidence: \(Int(confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(confidenceColor)
            }
        }
    }
    
    private var audioColor: Color {
        if batteryLevel < 0.2 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var confidenceColor: Color {
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Ultimate Command Display

struct UltimateCommandDisplayView: View {
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

// MARK: - Siri Response View

struct SiriResponseView: View {
    let response: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Siri Response:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(response)
                .font(.body)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Ultimate Command History

struct UltimateCommandHistoryView: View {
    let history: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Commands:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(history.prefix(5), id: \.self) { command in
                HStack {
                    Image(systemName: command.hasPrefix("Siri:") ? "siri" : "command")
                        .foregroundColor(command.hasPrefix("Siri:") ? .green : .blue)
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

// MARK: - Wake Word Performance Card

struct WakeWordPerformanceCard: View {
    @EnvironmentObject var audioManager: EnhancedAudioManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Wake Word Performance")
                .font(.headline)
            
            HStack(spacing: 20) {
                MetricCard(title: "Confidence", value: "\(Int(audioManager.wakeWordConfidence * 100))%", color: .blue)
                MetricCard(title: "Method", value: audioManager.detectionMethod.isEmpty ? "None" : audioManager.detectionMethod, color: .green)
                MetricCard(title: "Battery", value: "\(Int(audioManager.batteryLevel * 100))%", color: .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Wake Word Info View

struct WakeWordInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Wake Word Detection")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How it works:")
                            .font(.headline)
                        
                        Text("• Multiple detection methods are used simultaneously")
                        Text("• Speech recognition analyzes audio for wake word")
                        Text("• Pattern matching looks for audio patterns")
                        Text("• Keyword spotting uses machine learning features")
                        Text("• Results are combined for high confidence detection")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Wake Word:")
                            .font(.headline)
                        
                        Text("Say \"Hey HeardAI\" clearly to activate the assistant")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tips for better detection:")
                            .font(.headline)
                        
                        Text("• Speak clearly and at normal volume")
                        Text("• Reduce background noise")
                        Text("• Wait for the app to be ready")
                        Text("• Try again if not detected")
                    }
                }
                .padding()
            }
            .navigationTitle("Wake Word Info")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Ultimate Settings View

struct UltimateSettingsView: View {
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
            
            Section(header: Text("Wake Word Settings")) {
                HStack {
                    Text("Detection Sensitivity")
                    Spacer()
                    Text("Medium")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Confidence Threshold")
                    Spacer()
                    Text("70%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Multiple Methods")
                    Spacer()
                    Text("Enabled")
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
                    Text("Battery Optimization")
                    Spacer()
                    Text("Enabled")
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Enhanced Features")
                    Spacer()
                    Text("Enabled")
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct UltimateContentView_Previews: PreviewProvider {
    static var previews: some View {
        UltimateContentView()
            .environmentObject(EnhancedAudioManager())
            .environmentObject(SpeechRecognizer())
            .environmentObject(WhisperService())
            .environmentObject(ProperSiriKitService())
    }
} 