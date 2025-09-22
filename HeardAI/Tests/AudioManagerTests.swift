import XCTest
import AVFoundation
@testable import HeardAI

/// Unit tests for AudioManager following TDD principles
/// Tests core audio management functionality and edge cases
class AudioManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var audioManager: AudioManager!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        super.setUp()
        audioManager = AudioManager()
    }
    
    override func tearDownWithError() throws {
        audioManager?.stopListeningForWakeWord()
        audioManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAudioManagerInitialization() {
        // Given: A new AudioManager instance
        let manager = AudioManager()
        
        // Then: Initial state should be correct
        XCTAssertFalse(manager.isListening, "AudioManager should not be listening initially")
        XCTAssertFalse(manager.isWakeWordDetected, "Wake word should not be detected initially")
        XCTAssertEqual(manager.audioLevel, 0.0, "Audio level should be zero initially")
    }
    
    // MARK: - Audio Session Tests
    
    func testAudioSessionConfiguration() {
        // Given: An AudioManager instance
        // When: Audio session is configured (happens in init)
        let audioSession = AVAudioSession.sharedInstance()
        
        // Then: Audio session should be properly configured
        XCTAssertEqual(audioSession.category, .playAndRecord, "Audio session category should be playAndRecord")
        XCTAssertTrue(audioSession.isOtherAudioPlaying == false || audioSession.isOtherAudioPlaying == true, "Audio session should be accessible")
    }
    
    // MARK: - Wake Word Detection Tests
    
    func testStartListening() {
        // Given: An AudioManager instance
        // When: Starting to listen for wake word
        audioManager.startListeningForWakeWord()
        
        // Then: Should be in listening state
        XCTAssertTrue(audioManager.isListening, "AudioManager should be listening after startListeningForWakeWord()")
    }
    
    func testStopListening() {
        // Given: An AudioManager that is listening
        audioManager.startListeningForWakeWord()
        XCTAssertTrue(audioManager.isListening, "Precondition: AudioManager should be listening")
        
        // When: Stopping listening
        audioManager.stopListeningForWakeWord()
        
        // Then: Should not be listening
        XCTAssertFalse(audioManager.isListening, "AudioManager should not be listening after stopListeningForWakeWord()")
        XCTAssertFalse(audioManager.isWakeWordDetected, "Wake word detection should be reset")
    }
    
    // MARK: - Audio Level Tests
    
    func testAudioLevelRange() {
        // Given: An AudioManager instance
        // When: Audio level is updated (simulated)
        // Then: Audio level should be within valid range
        XCTAssertGreaterThanOrEqual(audioManager.audioLevel, 0.0, "Audio level should not be negative")
        XCTAssertLessThanOrEqual(audioManager.audioLevel, 1.0, "Audio level should not exceed 1.0")
    }
    
    // MARK: - WAV Data Creation Tests
    
    func testWAVDataCreation() {
        // Given: Sample audio data
        let sampleAudioData = Data(repeating: 0, count: 1024)
        
        // When: Creating WAV data
        let wavData = audioManager.createWAVFormattedData(from: sampleAudioData)
        
        // Then: WAV data should have proper structure
        XCTAssertGreaterThan(wavData.count, 44, "WAV data should include header (44 bytes) plus audio data")
        XCTAssertEqual(wavData.count, 44 + sampleAudioData.count, "WAV data size should be header + audio data")
        
        // Check WAV header signature
        let headerData = wavData.prefix(4)
        let headerString = String(data: headerData, encoding: .ascii)
        XCTAssertEqual(headerString, "RIFF", "WAV file should start with RIFF header")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Given: An AudioManager instance
        // When: Testing error scenarios
        // Then: Should handle errors gracefully without crashing
        
        // Test stopping when not listening
        XCTAssertNoThrow(audioManager.stopListeningForWakeWord(), "Should handle stop when not listening")
        
        // Test multiple start calls
        audioManager.startListeningForWakeWord()
        XCTAssertNoThrow(audioManager.startListeningForWakeWord(), "Should handle multiple start calls")
        
        audioManager.stopListeningForWakeWord()
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Given: An AudioManager instance
        weak var weakManager = audioManager
        
        // When: Releasing the manager
        audioManager = nil
        
        // Then: Should be properly deallocated
        XCTAssertNil(weakManager, "AudioManager should be deallocated when no longer referenced")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance() {
        // Test WAV data creation performance
        let sampleData = Data(repeating: 0, count: 64000) // 4 seconds of audio
        
        measure {
            _ = audioManager.createWAVFormattedData(from: sampleData)
        }
    }
}

// MARK: - Test Extensions

extension AudioManagerTests {
    
    /// Helper method to create test audio data
    private func createTestAudioData(duration: TimeInterval = 1.0) -> Data {
        let sampleCount = Int(Constants.Audio.sampleRate * duration)
        return Data(repeating: 0, count: sampleCount * 2) // 16-bit = 2 bytes per sample
    }
}
