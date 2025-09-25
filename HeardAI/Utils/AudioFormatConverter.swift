import Foundation
import AVFoundation

/// Audio format conversion utility for HeardAI voice assistant
/// 
/// Handles conversion between different audio formats, specifically:
/// - Device sample rate (48kHz) to Google Speech API format (16kHz)
/// - Float32 to Int16 PCM conversion
/// - Proper WAV header generation
///
/// This is critical for proper Google Speech API integration
class AudioFormatConverter {
    
    // MARK: - Constants
    
    /// Target sample rate for Google Speech API
    private static let targetSampleRate: Double = 16000.0
    
    /// Target bit depth for Google Speech API
    private static let targetBitDepth: Int = 16
    
    /// Target number of channels (mono)
    private static let targetChannels: Int = 1
    
    // MARK: - Public Methods
    
    /// Converts audio buffer from device format to Google Speech API format
    /// - Parameters:
    ///   - buffer: Input audio buffer from device
    ///   - inputFormat: Original audio format from device
    /// - Returns: Converted audio data in LINEAR16 format at 16kHz
    static func convertToGoogleSpeechFormat(
        buffer: AVAudioPCMBuffer,
        inputFormat: AVAudioFormat
    ) -> Data? {
        
        // Create target format for Google Speech API
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: UInt32(targetChannels),
            interleaved: true
        ) else {
            print("🔴 Failed to create target audio format")
            return nil
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            print("🔴 Failed to create audio converter")
            return nil
        }
        
        // Calculate output buffer size
        let inputFrameCount = buffer.frameLength
        let outputFrameCount = AVAudioFrameCount(
            Double(inputFrameCount) * (targetSampleRate / inputFormat.sampleRate)
        )
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCount
        ) else {
            print("🔴 Failed to create output buffer")
            return nil
        }
        
        // Perform conversion
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard status != .error, error == nil else {
            print("🔴 Audio conversion failed: \(error?.localizedDescription ?? "Unknown error")")
            return nil
        }
        
        // Convert to Data
        guard let channelData = outputBuffer.int16ChannelData?[0] else {
            print("🔴 Failed to get channel data from converted buffer")
            return nil
        }
        
        let frameCount = Int(outputBuffer.frameLength)
        let dataSize = frameCount * MemoryLayout<Int16>.size
        
        return Data(bytes: channelData, count: dataSize)
    }
    
    /// Creates a proper WAV file header for Google Speech API
    /// - Parameter audioData: Converted audio data in LINEAR16 format
    /// - Returns: WAV-formatted data with proper headers
    static func createWAVHeader(for audioData: Data) -> Data {
        var wavData = Data()
        
        let headerSize = 44
        let dataSize = audioData.count
        let fileSize = headerSize + dataSize - 8
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // fmt chunk size
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (PCM)
        wavData.append(withUnsafeBytes(of: UInt16(targetChannels).littleEndian) { Data($0) }) // channels
        wavData.append(withUnsafeBytes(of: UInt32(targetSampleRate).littleEndian) { Data($0) }) // sample rate
        wavData.append(withUnsafeBytes(of: UInt32(targetSampleRate * Double(targetChannels) * Double(targetBitDepth / 8)).littleEndian) { Data($0) }) // byte rate
        wavData.append(withUnsafeBytes(of: UInt16(targetBitDepth / 8 * targetChannels).littleEndian) { Data($0) }) // block align
        wavData.append(withUnsafeBytes(of: UInt16(targetBitDepth).littleEndian) { Data($0) }) // bits per sample
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
        wavData.append(audioData)
        
        return wavData
    }
    
    /// Converts and packages audio for Google Speech API
    /// - Parameters:
    ///   - buffer: Input audio buffer
    ///   - inputFormat: Original audio format
    /// - Returns: Complete WAV file data ready for Google Speech API
    static func convertForGoogleSpeech(
        buffer: AVAudioPCMBuffer,
        inputFormat: AVAudioFormat
    ) -> Data? {
        
        // Convert audio format
        guard let convertedData = convertToGoogleSpeechFormat(
            buffer: buffer,
            inputFormat: inputFormat
        ) else {
            return nil
        }
        
        // Create WAV header
        return createWAVHeader(for: convertedData)
    }
    
    /// Validates audio data quality for speech recognition
    /// - Parameter audioData: Audio data to validate
    /// - Returns: True if audio quality is sufficient for speech recognition
    static func validateAudioQuality(_ audioData: Data) -> Bool {
        // Check minimum data size (at least 0.1 seconds at 16kHz)
        let minimumSize = Int(targetSampleRate * 0.1 * Double(targetChannels) * Double(targetBitDepth / 8))
        
        guard audioData.count >= minimumSize else {
            print("⚠️ Audio data too short for reliable speech recognition")
            return false
        }
        
        // Check for silence (all zeros or very low amplitude)
        let samples = audioData.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Int16.self)
        }
        
        var maxAmplitude: Int16 = 0
        for sample in samples {
            maxAmplitude = max(maxAmplitude, abs(sample))
        }
        
        // Minimum amplitude threshold (adjust based on testing)
        let minAmplitude: Int16 = 100
        guard maxAmplitude > minAmplitude else {
            print("⚠️ Audio data appears to be silence or too quiet")
            return false
        }
        
        print("✅ Audio quality validation passed (max amplitude: \(maxAmplitude))")
        return true
    }
}

// MARK: - Error Types

enum AudioFormatConverterError: Error, LocalizedError {
    case invalidInputFormat
    case conversionFailed
    case insufficientData
    case poorAudioQuality
    
    var errorDescription: String? {
        switch self {
        case .invalidInputFormat:
            return "Invalid input audio format"
        case .conversionFailed:
            return "Audio format conversion failed"
        case .insufficientData:
            return "Insufficient audio data for processing"
        case .poorAudioQuality:
            return "Audio quality too poor for speech recognition"
        }
    }
}
