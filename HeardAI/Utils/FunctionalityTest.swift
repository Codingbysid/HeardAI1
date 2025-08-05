import Foundation
import AVFoundation
import Speech

class FunctionalityTest {
    
    static func runBasicTests() -> TestResults {
        var results = TestResults()
        
        // Test 1: Audio Session
        results.audioSessionTest = testAudioSession()
        
        // Test 2: Speech Recognition
        results.speechRecognitionTest = testSpeechRecognition()
        
        // Test 3: API Key
        results.apiKeyTest = testAPIKey()
        
        // Test 4: Permissions
        results.permissionsTest = testPermissions()
        
        // Test 5: File System
        results.fileSystemTest = testFileSystem()
        
        return results
    }
    
    private static func testAudioSession() -> TestResult {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            return TestResult(
                name: "Audio Session",
                success: true,
                message: "Audio session configured successfully"
            )
        } catch {
            return TestResult(
                name: "Audio Session",
                success: false,
                message: "Failed to configure audio session: \(error.localizedDescription)"
            )
        }
    }
    
    private static func testSpeechRecognition() -> TestResult {
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        if speechRecognizer?.isAvailable == true {
            return TestResult(
                name: "Speech Recognition",
                success: true,
                message: "Speech recognition is available"
            )
        } else {
            return TestResult(
                name: "Speech Recognition",
                success: false,
                message: "Speech recognition is not available"
            )
        }
    }
    
    private static func testAPIKey() -> TestResult {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        
        if !apiKey.isEmpty {
            return TestResult(
                name: "API Key",
                success: true,
                message: "OpenAI API key is configured"
            )
        } else {
            return TestResult(
                name: "API Key",
                success: false,
                message: "OpenAI API key is missing. Add it to environment variables or Info.plist"
            )
        }
    }
    
    private static func testPermissions() -> TestResult {
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        var issues: [String] = []
        
        if microphoneStatus != .granted {
            issues.append("Microphone permission not granted")
        }
        
        if speechStatus != .authorized {
            issues.append("Speech recognition permission not granted")
        }
        
        if issues.isEmpty {
            return TestResult(
                name: "Permissions",
                success: true,
                message: "All required permissions are granted"
            )
        } else {
            return TestResult(
                name: "Permissions",
                success: false,
                message: "Permission issues: \(issues.joined(separator: ", "))"
            )
        }
    }
    
    private static func testFileSystem() -> TestResult {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.txt")
        
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
            
            return TestResult(
                name: "File System",
                success: true,
                message: "File system access is working"
            )
        } catch {
            return TestResult(
                name: "File System",
                success: false,
                message: "File system access failed: \(error.localizedDescription)"
            )
        }
    }
    
    static func testAudioFormatConversion() -> TestResult {
        // Create test audio data
        let testData = Data(repeating: 0, count: 1024)
        
        do {
            let wavData = try AudioFormatConverter.convertToWAV(
                audioBuffer: testData,
                sampleRate: 16000,
                channels: 1
            )
            
            if wavData.count > 44 { // WAV header is 44 bytes
                return TestResult(
                    name: "Audio Format Conversion",
                    success: true,
                    message: "Audio format conversion working"
                )
            } else {
                return TestResult(
                    name: "Audio Format Conversion",
                    success: false,
                    message: "Generated WAV data is too small"
                )
            }
        } catch {
            return TestResult(
                name: "Audio Format Conversion",
                success: false,
                message: "Audio format conversion failed: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Test Results

struct TestResults {
    var audioSessionTest: TestResult?
    var speechRecognitionTest: TestResult?
    var apiKeyTest: TestResult?
    var permissionsTest: TestResult?
    var fileSystemTest: TestResult?
    var audioFormatTest: TestResult?
    
    var allTests: [TestResult] {
        return [
            audioSessionTest,
            speechRecognitionTest,
            apiKeyTest,
            permissionsTest,
            fileSystemTest,
            audioFormatTest
        ].compactMap { $0 }
    }
    
    var passedTests: Int {
        return allTests.filter { $0.success }.count
    }
    
    var totalTests: Int {
        return allTests.count
    }
    
    var overallSuccess: Bool {
        return passedTests == totalTests
    }
    
    var summary: String {
        let successRate = totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
        return "\(passedTests)/\(totalTests) tests passed (\(String(format: "%.1f", successRate))%)"
    }
}

struct TestResult {
    let name: String
    let success: Bool
    let message: String
} 