import Foundation
import AVFoundation

class AudioFormatConverter {
    
    static func convertToWAV(audioBuffer: Data, sampleRate: Double = 16000, channels: Int = 1) throws -> Data {
        // Create audio format for WAV
        let audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: AVAudioChannelCount(channels)
        )!
        
        // Convert raw audio data to WAV format
        let wavData = try convertRawAudioToWAV(
            rawData: audioBuffer,
            sampleRate: sampleRate,
            channels: channels
        )
        
        return wavData
    }
    
    private static func convertRawAudioToWAV(rawData: Data, sampleRate: Double, channels: Int) throws -> Data {
        var wavData = Data()
        
        // WAV header
        let headerSize = 44
        let dataSize = rawData.count
        let fileSize = headerSize + dataSize - 8
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // fmt chunk size
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (PCM)
        wavData.append(withUnsafeBytes(of: UInt16(channels).littleEndian) { Data($0) }) // channels
        wavData.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // sample rate
        wavData.append(withUnsafeBytes(of: UInt32(sampleRate * Double(channels) * 2).littleEndian) { Data($0) }) // byte rate
        wavData.append(withUnsafeBytes(of: UInt16(channels * 2).littleEndian) { Data($0) }) // block align
        wavData.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // bits per sample
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
        wavData.append(rawData)
        
        return wavData
    }
    
    static func convertFloatToInt16(_ floatData: Data) -> Data {
        var int16Data = Data()
        let floatArray = floatData.withUnsafeBytes { $0.bindMemory(to: Float.self) }
        
        for floatValue in floatArray {
            let int16Value = Int16(floatValue * Float(Int16.max))
            int16Data.append(withUnsafeBytes(of: int16Value.littleEndian) { Data($0) })
        }
        
        return int16Data
    }
} 