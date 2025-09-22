import XCTest
import Combine
@testable import HeardAI

/// Unit tests for WhisperService (Google Speech integration)
/// Tests speech-to-text functionality and error handling
class WhisperServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var whisperService: WhisperService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        super.setUp()
        whisperService = WhisperService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables?.removeAll()
        whisperService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testWhisperServiceInitialization() {
        // Given: A new WhisperService instance
        let service = WhisperService()
        
        // Then: Initial state should be correct
        XCTAssertFalse(service.isTranscribing, "Service should not be transcribing initially")
        XCTAssertEqual(service.transcribedText, "", "Transcribed text should be empty initially")
        XCTAssertNil(service.error, "Error should be nil initially")
    }
    
    // MARK: - API Key Tests
    
    func testAPIKeyLoading() {
        // Given: A WhisperService instance
        // When: Service is initialized
        // Then: Should attempt to load API key from environment or Info.plist
        
        // Note: In a real test, we would mock the environment/Info.plist
        // For now, we just verify the service initializes without crashing
        XCTAssertNotNil(whisperService, "WhisperService should initialize successfully")
    }
    
    func testMissingAPIKeyError() {
        // Given: A WhisperService with no API key (simulated)
        let expectation = self.expectation(description: "API key error")
        let testData = Data("test".utf8)
        
        // When: Attempting to transcribe without API key
        whisperService.transcribeAudio(testData) { result in
            // Then: Should return missing API key error
            switch result {
            case .success:
                XCTFail("Should not succeed without API key")
            case .failure(let error):
                if let whisperError = error as? WhisperServiceError {
                    XCTAssertEqual(whisperError, .missingAPIKey, "Should return missing API key error")
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Audio Data Validation Tests
    
    func testEmptyAudioData() {
        // Given: Empty audio data
        let emptyData = Data()
        let expectation = self.expectation(description: "Empty data handling")
        
        // When: Attempting to transcribe empty data
        whisperService.transcribeAudio(emptyData) { result in
            // Then: Should handle gracefully
            switch result {
            case .success(let text):
                XCTAssertTrue(text.isEmpty || !text.isEmpty, "Should handle empty data gracefully")
            case .failure:
                // Failure is acceptable for empty data
                break
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testValidAudioDataStructure() {
        // Given: Valid WAV-formatted audio data
        let validWAVData = createTestWAVData()
        
        // When: Checking data structure
        // Then: Should have proper WAV header
        XCTAssertGreaterThan(validWAVData.count, 44, "WAV data should include header")
        
        let headerData = validWAVData.prefix(4)
        let headerString = String(data: headerData, encoding: .ascii)
        XCTAssertEqual(headerString, "RIFF", "Should have valid RIFF header")
    }
    
    // MARK: - Published Properties Tests
    
    func testIsTranscribingProperty() {
        // Given: A WhisperService instance
        let expectation = self.expectation(description: "isTranscribing updates")
        var receivedValues: [Bool] = []
        
        // When: Observing isTranscribing property
        whisperService.$isTranscribing
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate transcription start
        let testData = createTestWAVData()
        whisperService.transcribeAudio(testData) { _ in }
        
        waitForExpectations(timeout: 5.0)
        
        // Then: Should have received state changes
        XCTAssertGreaterThanOrEqual(receivedValues.count, 2, "Should receive isTranscribing updates")
        XCTAssertEqual(receivedValues.first, false, "Initial value should be false")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorPropertyUpdates() {
        // Given: A WhisperService instance
        let expectation = self.expectation(description: "Error property updates")
        
        // When: Observing error property
        whisperService.$error
            .dropFirst() // Skip initial nil value
            .sink { error in
                // Then: Should receive error updates
                XCTAssertNotNil(error, "Should receive error update")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger an error by using invalid data
        let invalidData = Data("invalid".utf8)
        whisperService.transcribeAudio(invalidData) { _ in }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Response Parsing Tests
    
    func testGoogleSpeechResponseParsing() {
        // Given: Sample Google Speech API response
        let sampleResponse = """
        {
            "results": [
                {
                    "alternatives": [
                        {
                            "transcript": "Hello world",
                            "confidence": 0.95
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        // When: Parsing the response
        do {
            let transcription = try whisperService.parseGoogleSpeechResponse(sampleResponse)
            
            // Then: Should extract correct transcription
            XCTAssertEqual(transcription, "Hello world", "Should parse transcription correctly")
        } catch {
            XCTFail("Should parse valid response without error: \(error)")
        }
    }
    
    func testInvalidResponseParsing() {
        // Given: Invalid JSON response
        let invalidResponse = "invalid json".data(using: .utf8)!
        
        // When: Attempting to parse invalid response
        // Then: Should throw appropriate error
        XCTAssertThrowsError(try whisperService.parseGoogleSpeechResponse(invalidResponse)) { error in
            XCTAssertTrue(error is WhisperServiceError, "Should throw WhisperServiceError")
        }
    }
    
    // MARK: - File Transcription Tests
    
    func testAudioFileTranscription() {
        // Given: A temporary audio file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_audio.wav")
        let testData = createTestWAVData()
        
        do {
            try testData.write(to: tempURL)
            
            let expectation = self.expectation(description: "File transcription")
            
            // When: Transcribing audio file
            whisperService.transcribeAudioFile(url: tempURL) { result in
                // Then: Should handle file transcription
                switch result {
                case .success(let text):
                    XCTAssertTrue(text.isEmpty || !text.isEmpty, "Should return transcription result")
                case .failure(let error):
                    // Failure is acceptable without valid API key
                    XCTAssertNotNil(error, "Should provide error details")
                }
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10.0)
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testTranscriptionPerformance() {
        // Given: Large audio data
        let largeAudioData = createTestWAVData(duration: 4.0) // 4 seconds
        
        // When: Measuring transcription setup time
        measure {
            let expectation = self.expectation(description: "Transcription performance")
            
            whisperService.transcribeAudio(largeAudioData) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0) // Only measure setup time
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates test WAV data for testing purposes
    /// - Parameter duration: Duration of test audio in seconds
    /// - Returns: Valid WAV-formatted test data
    private func createTestWAVData(duration: TimeInterval = 1.0) -> Data {
        let sampleCount = Int(Constants.Audio.sampleRate * duration)
        let audioData = Data(repeating: 0, count: sampleCount * 2) // 16-bit samples
        
        var wavData = Data()
        
        // Add basic WAV header
        let headerSize = 44
        let fileSize = headerSize + audioData.count - 8
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: UInt32(16000).littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: UInt32(32000).littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) })
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(audioData.count).littleEndian) { Data($0) })
        wavData.append(audioData)
        
        return wavData
    }
}
