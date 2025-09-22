import SwiftUI

/// Main content view for HeardAI voice assistant application
/// 
/// This view provides the primary user interface for voice interaction,
/// including wake word detection, command transcription, and Siri integration.
/// 
/// Features:
/// - Real-time audio level visualization
/// - Wake word detection status
/// - Command confirmation dialog with edit capability
/// - Command history display
/// - Settings access
/// 
/// Architecture:
/// - Uses MVVM pattern with environment objects for services
/// - Reactive UI updates through Combine publishers
/// - Modular design with separate view components
struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: SiriService
    
    // MARK: - State Properties
    
    /// Controls the presentation of the settings sheet
    @State private var showingSettings = false
    
    /// Maintains a history of executed commands for user reference
    @State private var commandHistory: [String] = []
    
    // MARK: - Command Confirmation State
    
    /// The original transcribed command awaiting user confirmation
    @State private var pendingCommand: String = ""
    
    /// Controls the visibility of the command confirmation dialog
    @State private var showingConfirmation = false
    
    /// The user-editable version of the transcribed command
    @State private var editedCommand: String = ""
    
    /// Indicates whether a command is currently being processed/sent to Siri
    @State private var isProcessingCommand = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("HeardAI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Say \"Hey HeardAI\" to activate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Status indicator
                StatusIndicatorView()
                
                // Command display
                if !whisperService.transcribedText.isEmpty {
                    CommandDisplayView(text: whisperService.transcribedText)
                }
                
                // Action buttons
                VStack(spacing: 15) {
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
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Manual test button for demo purposes
                    Button(action: {
                        // Simulate a wake word detection for testing
                        presentCommandForConfirmation("Set a timer for 5 minutes")
                    }) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text("Test Command (Demo)")
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // Command history
                if !commandHistory.isEmpty {
                    CommandHistoryView(history: commandHistory)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .overlay(
                // Command Confirmation Overlay
                Group {
                    if showingConfirmation {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Dismiss on background tap
                                rejectCommand()
                            }
                        
                        CommandConfirmationCard()
                    }
                }
            )
        }
        .onReceive(whisperService.$transcribedText) { text in
            if !text.isEmpty {
                commandHistory.insert(text, at: 0)
                if commandHistory.count > 10 { // Maximum command history
                    commandHistory.removeLast()
                }
            }
        }
        .onReceive(audioManager.$isWakeWordDetected) { detected in
            if detected {
                print("🎤 Wake word detected, audio manager will handle command recording")
                // AudioManager now handles the complete flow:
                // 1. Records command audio
                // 2. Sends to Google Speech API  
                // 3. Presents for confirmation (NEW)
                // 4. Executes with Siri after approval
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .commandReadyForConfirmation)) { notification in
            if let transcription = notification.userInfo?["transcription"] as? String {
                presentCommandForConfirmation(transcription)
            }
        }
    }
    
    // MARK: - Command Confirmation Methods
    
    private func presentCommandForConfirmation(_ transcription: String) {
        pendingCommand = transcription
        editedCommand = transcription
        showingConfirmation = true
        isProcessingCommand = false
        
        print("🎤 Presenting command for confirmation: \(transcription)")
    }
    
    private func acceptCommand() {
        let finalCommand = editedCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalCommand.isEmpty else { return }
        
        isProcessingCommand = true
        print("✅ User accepted command: \(finalCommand)")
        
        // Add to command history
        commandHistory.insert(finalCommand, at: 0)
        if commandHistory.count > 10 { // Maximum command history
            commandHistory.removeLast()
        }
        
        // Execute with Siri
        siriService.executeCommand(finalCommand)
        
        // Clear confirmation
        clearConfirmation()
    }
    
    private func rejectCommand() {
        print("❌ User rejected command: \(pendingCommand)")
        clearConfirmation()
    }
    
    private func clearConfirmation() {
        showingConfirmation = false
        pendingCommand = ""
        editedCommand = ""
        isProcessingCommand = false
    }
    
    // MARK: - Command Confirmation Card
    
    @ViewBuilder
    private func CommandConfirmationCard() -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: getCommandIcon(for: pendingCommand))
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(getCommandType(for: pendingCommand))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Review your command before sending to Siri")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Command Text Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Command:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Edit your command...", text: $editedCommand)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                // Reject Button
                Button(action: rejectCommand) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .disabled(isProcessingCommand)
                
                // Accept Button
                Button(action: acceptCommand) {
                    HStack {
                        if isProcessingCommand {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isProcessingCommand ? "Sending..." : "Accept")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(editedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
                }
                .disabled(editedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessingCommand)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
    
    // MARK: - Helper Methods for Command UI
    
    private func getCommandType(for command: String) -> String {
        let cmd = command.lowercased()
        
        if cmd.contains("remind") { return "Reminder" }
        else if cmd.contains("message") || cmd.contains("text") { return "Message" }
        else if cmd.contains("call") || cmd.contains("phone") { return "Call" }
        else if cmd.contains("weather") { return "Weather" }
        else if cmd.contains("music") || cmd.contains("play") { return "Music" }
        else if cmd.contains("timer") { return "Timer" }
        else if cmd.contains("alarm") { return "Alarm" }
        else { return "General" }
    }
    
    private func getCommandIcon(for command: String) -> String {
        let cmd = command.lowercased()
        
        if cmd.contains("remind") { return "bell.fill" }
        else if cmd.contains("message") || cmd.contains("text") { return "message.fill" }
        else if cmd.contains("call") || cmd.contains("phone") { return "phone.fill" }
        else if cmd.contains("weather") { return "cloud.sun.fill" }
        else if cmd.contains("music") || cmd.contains("play") { return "music.note" }
        else if cmd.contains("timer") { return "timer" }
        else if cmd.contains("alarm") { return "alarm.fill" }
        else { return "bubble.left.fill" }
    }
}

struct StatusIndicatorView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: SiriService
    
    var body: some View {
        VStack(spacing: 15) {
            // Audio level indicator
            if audioManager.isListening {
                AudioLevelIndicator(level: audioManager.audioLevel)
            }
            
            // Status text
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

struct AudioLevelIndicator: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 4, height: CGFloat(level * 50) * (1.0 - Double(index) * 0.1))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
        .frame(height: 50)
    }
}

struct CommandDisplayView: View {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CommandHistoryView: View {
    let history: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Commands:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(history.prefix(5), id: \.self) { command in
                Text(command)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AudioManager())
            .environmentObject(SpeechRecognizer())
            .environmentObject(WhisperService())
            .environmentObject(SiriService())
    }
}
