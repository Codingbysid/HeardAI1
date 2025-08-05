# HeardAI Setup Guide

## Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- Physical iOS device (audio features don't work in simulator)
- OpenAI API key

## Step 1: Project Setup

### 1.1 Open Project in Xcode
```bash
# Navigate to project directory
cd /Users/siddharthgupta/Desktop/HeardAI

# Open in Xcode
open HeardAI.xcodeproj
```

### 1.2 Configure Build Settings
1. Select the HeardAI project in the navigator
2. Select the HeardAI target
3. Go to "Build Settings" tab
4. Set the following:
   - **iOS Deployment Target**: 16.0
   - **Swift Language Version**: Swift 5
   - **Enable Bitcode**: No (for better performance)

### 1.3 Add Required Frameworks
1. Select the HeardAI target
2. Go to "General" tab
3. Scroll to "Frameworks, Libraries, and Embedded Content"
4. Click "+" and add:
   - `AVFoundation.framework`
   - `Speech.framework`
   - `Intents.framework`
   - `IntentsUI.framework`

## Step 2: Environment Configuration

### 2.1 Add OpenAI API Key
1. In Xcode, go to Product → Scheme → Edit Scheme
2. Select "Run" on the left
3. Go to "Arguments" tab
4. Under "Environment Variables", add:
   - Name: `OPENAI_API_KEY`
   - Value: Your OpenAI API key

### 2.2 Alternative: Add to Info.plist
Add this to your Info.plist:
```xml
<key>OPENAI_API_KEY</key>
<string>your-api-key-here</string>
```

## Step 3: Permissions Setup

### 3.1 Verify Info.plist Permissions
The following permissions should already be in Info.plist:
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `UIBackgroundModes` (audio, background-processing)

### 3.2 Add Siri Capability
1. Select the HeardAI target
2. Go to "Signing & Capabilities"
3. Click "+" and add "Siri"

## Step 4: Build and Test

### 4.1 Build Configuration
1. Select your physical device as the target
2. Clean build folder (Product → Clean Build Folder)
3. Build the project (⌘+B)

### 4.2 Common Issues and Solutions

#### Issue: "Speech recognition not available"
**Solution**: 
- Ensure you're testing on a physical device
- Check that speech recognition permissions are granted
- Verify internet connectivity

#### Issue: "Audio session setup failed"
**Solution**:
- Check microphone permissions
- Ensure device is not in silent mode
- Verify audio session configuration

#### Issue: "OpenAI API key missing"
**Solution**:
- Verify environment variable is set correctly
- Check API key validity
- Ensure network connectivity

## Step 5: Testing Workflow

### 5.1 Basic Functionality Test
1. Launch app on physical device
2. Grant microphone and speech recognition permissions
3. Tap "Start Listening"
4. Say "Hey HeardAI" clearly
5. Wait for wake word detection
6. Speak a command
7. Verify transcription and Siri execution

### 5.2 Debug Information
Enable debug logging by adding this to AudioManager.swift:
```swift
private func debugLog(_ message: String) {
    print("[AudioManager] \(message)")
}
```

## Step 6: Performance Monitoring

### 6.1 Enable Performance Monitoring
1. In Xcode, go to Product → Scheme → Edit Scheme
2. Select "Run" → "Options"
3. Check "Enable Performance Monitoring"

### 6.2 Monitor Key Metrics
- Audio level responsiveness
- Wake word detection accuracy
- Transcription speed
- Battery usage
- Memory usage

## Troubleshooting

### Common Build Errors
1. **"No such module 'AVFoundation'"**
   - Clean build folder and rebuild
   - Check framework linking

2. **"Permission denied"**
   - Reset permissions in Settings → Privacy
   - Reinstall app

3. **"Audio session failed"**
   - Check device audio settings
   - Ensure app has microphone access

### Performance Issues
1. **High battery usage**
   - Check audio session configuration
   - Optimize wake word detection frequency

2. **Slow response time**
   - Check network connectivity
   - Verify API key configuration
   - Monitor transcription service

## Next Steps
After successful setup, proceed to:
1. SiriKit Integration Improvements
2. Performance Optimizations
3. Advanced Features Implementation 