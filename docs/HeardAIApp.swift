import SwiftUI
import AVFoundation

@main
struct HeardAIApp: App {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var whisperService = WhisperService()
    @StateObject private var siriService = SiriService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(speechRecognizer)
                .environmentObject(whisperService)
                .environmentObject(siriService)
                .onAppear {
                    setupAudioSession()
                }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
}
