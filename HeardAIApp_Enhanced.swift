import SwiftUI
import AVFoundation

@main
struct HeardAIApp: App {
    @StateObject private var audioManager = OptimizedAudioManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var whisperService = WhisperService()
    @StateObject private var siriService = EnhancedSiriService()
    
    var body: some Scene {
        WindowGroup {
            EnhancedContentView()
                .environmentObject(audioManager)
                .environmentObject(speechRecognizer)
                .environmentObject(whisperService)
                .environmentObject(siriService)
                .onAppear {
                    setupAudioSession()
                    setupAppLifecycle()
                }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            // Set optimal audio session configuration
            try audioSession.setPreferredSampleRate(16000)
            try audioSession.setPreferredIOBufferDuration(0.1)
            
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAppLifecycle() {
        // Handle app lifecycle events for better performance
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App going to background - optimize for battery
            audioManager.performanceMetrics.isLowPowerMode = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App becoming active - restore normal performance
            audioManager.performanceMetrics.isLowPowerMode = false
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App entered background - maintain minimal functionality
            print("App entered background")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App will enter foreground - prepare for full functionality
            print("App will enter foreground")
        }
    }
} 