import SwiftUI

/// View for confirming voice commands before sending to Siri
/// Allows users to review, edit, accept, or reject transcribed commands
struct CommandConfirmationView: View {
    @ObservedObject var confirmationManager: CommandConfirmationManager
    @State private var editedText: String = ""
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        if let command = confirmationManager.pendingCommand {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: command.commandIcon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text(command.commandType)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Timeout indicator
                        Text(confirmationManager.timeRemainingString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Text("Review your command before sending to Siri")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Command Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Command:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if command.wasEdited {
                            Text("Edited")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if isEditing {
                        TextField("Edit your command...", text: $editedText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                finishEditing()
                            }
                    } else {
                        Text(editedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onTapGesture {
                                startEditing()
                            }
                    }
                }
                
                // Confidence indicator (if available)
                if let confidence = command.confidence {
                    HStack {
                        Text("Confidence:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: confidence, in: 0...1)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 4)
                        
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    // Reject Button
                    Button(action: {
                        confirmationManager.rejectCommand()
                    }) {
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
                    .disabled(confirmationManager.isProcessingConfirmation)
                    
                    // Accept Button
                    Button(action: {
                        if isEditing {
                            finishEditing()
                        }
                        confirmationManager.acceptCommand()
                    }) {
                        HStack {
                            if confirmationManager.isProcessingConfirmation {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(confirmationManager.isProcessingConfirmation ? "Sending..." : "Accept")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || confirmationManager.isProcessingConfirmation)
                }
                
                // Quick Edit Suggestions (if command was misheard)
                if !command.wasEdited {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Common corrections:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(getQuickSuggestions(for: command.originalTranscription), id: \.self) { suggestion in
                                    Button(suggestion) {
                                        editedText = suggestion
                                        confirmationManager.updateCommandText(suggestion)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
            .onAppear {
                editedText = command.editedCommand
            }
            .onChange(of: editedText) { newValue in
                confirmationManager.updateCommandText(newValue)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startEditing() {
        isEditing = true
        isTextFieldFocused = true
    }
    
    private func finishEditing() {
        isEditing = false
        isTextFieldFocused = false
    }
    
    private func getQuickSuggestions(for originalText: String) -> [String] {
        let text = originalText.lowercased()
        var suggestions: [String] = []
        
        // Common misheard commands
        if text.contains("call") {
            suggestions.append("Call Mom")
            suggestions.append("Call Dad")
        } else if text.contains("remind") {
            suggestions.append("Remind me to call Mom")
            suggestions.append("Set reminder for meeting")
        } else if text.contains("timer") {
            suggestions.append("Set timer for 5 minutes")
            suggestions.append("Set timer for 10 minutes")
        } else if text.contains("weather") {
            suggestions.append("What's the weather?")
            suggestions.append("Weather forecast")
        }
        
        return suggestions
    }
}

// MARK: - Preview

struct CommandConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CommandConfirmationManager()
        manager.presentCommandForConfirmation("Call John", confidence: 0.85)
        
        return CommandConfirmationView(confirmationManager: manager)
            .previewLayout(.sizeThatFits)
    }
}
