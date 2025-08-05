import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var siriService: SiriService
    
    @State private var showingSettings = false
    @State private var commandHistory: [String] = []
    
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
                // Wake word detected, start recording command
                speechRecognizer.startListening()
            }
        }
        .onReceive(speechRecognizer.$transcribedText) { text in
            if !text.isEmpty && speechRecognizer.isListening == false {
                // Command transcribed, send to Siri
                siriService.executeCommand(text)
            }
        }
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
