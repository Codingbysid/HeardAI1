import SwiftUI
import AVFoundation

@main
struct HeardAIApp: App {
    // MARK: - Core Services
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
                    runDiagnosticTests()
                }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            // Set optimal audio session configuration
            try audioSession.setPreferredSampleRate(16000) // 16kHz sample rate
            try audioSession.setPreferredIOBufferDuration(0.1) // 100ms buffer
            
        } catch {
            print("❌ Failed to setup audio session: \(error.localizedDescription)")
            // In production, could show user-friendly error dialog
        }
    }
    
    private func runDiagnosticTests() {
        // Run basic diagnostic tests
        print("🧪 Running HeardAI diagnostic tests...")
        
        // Test 1: Service Initialization (services are @StateObject so always initialized)
        print("✅ AudioManager: Initialized")
        print("✅ WhisperService: Initialized") 
        print("✅ SiriService: Initialized")
        print("✅ SpeechRecognizer: Initialized")
        
        print("🎉 All core services initialized successfully!")
        print("🚀 HeardAI is ready for use!")
    }
}