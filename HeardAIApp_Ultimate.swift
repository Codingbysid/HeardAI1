import SwiftUI
import AVFoundation

@main
struct HeardAIApp: App {
    @StateObject private var audioManager = EnhancedAudioManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var whisperService = WhisperService()
    @StateObject private var siriService = ProperSiriKitService()
    
    var body: some Scene {
        WindowGroup {
            UltimateContentView()
                .environmentObject(audioManager)
                .environmentObject(speechRecognizer)
                .environmentObject(whisperService)
                .environmentObject(siriService)
                .onAppear {
                    setupAudioSession()
                    setupAppLifecycle()
                    runFunctionalityTests()
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
            print("App going to background - optimizing for battery")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App becoming active - restore normal performance
            print("App becoming active - restoring normal performance")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App entered background - maintain minimal functionality
            print("App entered background - maintaining minimal functionality")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App will enter foreground - prepare for full functionality
            print("App will enter foreground - preparing for full functionality")
        }
    }
    
    private func runFunctionalityTests() {
        // Run basic functionality tests on app launch
        let testResults = FunctionalityTest.runBasicTests()
        print("=== Functionality Test Results ===")
        print(testResults.summary)
        
        for test in testResults.allTests {
            let status = test.success ? "✅" : "❌"
            print("\(status) \(test.name): \(test.message)")
        }
        
        // Test audio format conversion
        let audioTest = FunctionalityTest.testAudioFormatConversion()
        let audioStatus = audioTest.success ? "✅" : "❌"
        print("\(audioStatus) \(audioTest.name): \(audioTest.message)")
        
        print("=== End Functionality Tests ===")
        
        // Check if all critical tests passed
        if testResults.overallSuccess {
            print("🎉 All critical functionality tests passed!")
        } else {
            print("⚠️ Some functionality tests failed. Check the results above.")
        }
    }
} 