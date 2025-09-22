import Foundation

/// High-performance circular buffer for audio data management
/// Eliminates expensive removeFirst operations and prevents memory fragmentation
class CircularBuffer<T> {
    private var buffer: [T]
    private var head: Int = 0
    private var tail: Int = 0
    private var count: Int = 0
    private let capacity: Int
    
    /// Initialize with specified capacity
    /// - Parameter capacity: Maximum number of elements the buffer can hold
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array<T>()
        self.buffer.reserveCapacity(capacity)
    }
    
    /// Add element to the buffer
    /// If buffer is full, overwrites the oldest element
    /// - Parameter element: Element to add
    func append(_ element: T) {
        if count < capacity {
            buffer.append(element)
            count += 1
            tail = buffer.count
        } else {
            buffer[head] = element
            head = (head + 1) % capacity
            tail = (tail + 1) % capacity
        }
    }
    
    /// Get all elements in insertion order
    /// - Returns: Array of elements in correct order
    func getAllElements() -> [T] {
        guard count > 0 else { return [] }
        
        if count < capacity {
            return Array(buffer[0..<count])
        } else {
            let firstPart = Array(buffer[head..<capacity])
            let secondPart = Array(buffer[0..<head])
            return firstPart + secondPart
        }
    }
    
    /// Clear all elements from buffer
    func removeAll() {
        buffer.removeAll(keepingCapacity: true)
        head = 0
        tail = 0
        count = 0
    }
    
    /// Current number of elements in buffer
    var currentCount: Int {
        return count
    }
    
    /// Check if buffer is empty
    var isEmpty: Bool {
        return count == 0
    }
    
    /// Check if buffer is full
    var isFull: Bool {
        return count == capacity
    }
}

/// Specialized circular buffer for audio data (Data type)
class AudioCircularBuffer {
    private var dataBuffer: Data
    private var maxSize: Int
    private var currentSize: Int = 0
    
    init(maxSize: Int) {
        self.maxSize = maxSize
        self.dataBuffer = Data()
        self.dataBuffer.reserveCapacity(maxSize)
    }
    
    /// Append audio data to buffer
    /// Automatically manages overflow by keeping most recent data
    /// - Parameter data: Audio data to append
    func append(_ data: Data) {
        if currentSize + data.count <= maxSize {
            // Simple append if within capacity
            dataBuffer.append(data)
            currentSize += data.count
        } else {
            // Need to manage overflow
            let excessBytes = (currentSize + data.count) - maxSize
            
            if excessBytes < currentSize {
                // Remove excess from beginning
                dataBuffer = Data(dataBuffer.dropFirst(excessBytes))
                dataBuffer.append(data)
                currentSize = maxSize
            } else {
                // New data is larger than buffer, keep only the tail
                let keepBytes = min(data.count, maxSize)
                let startIndex = data.count - keepBytes
                dataBuffer = Data(data.dropFirst(startIndex))
                currentSize = keepBytes
            }
        }
    }
    
    /// Get all current audio data
    /// - Returns: Complete audio data buffer
    func getData() -> Data {
        return dataBuffer
    }
    
    /// Clear all audio data
    func removeAll() {
        dataBuffer.removeAll(keepingCapacity: true)
        currentSize = 0
    }
    
    /// Current size in bytes
    var count: Int {
        return currentSize
    }
    
    /// Check if buffer is empty
    var isEmpty: Bool {
        return currentSize == 0
    }
}
