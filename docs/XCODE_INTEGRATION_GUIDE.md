# Xcode Integration Guide - Adding Enhanced Files

## 📋 Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- Physical iOS device for testing
- OpenAI API key

## 🚀 Step-by-Step Integration

### **Step 1: Open Your Project**
```bash
# Navigate to your project directory
cd /Users/siddharthgupta/Desktop/HeardAI

# Open in Xcode
open HeardAI.xcodeproj
```

### **Step 2: Add Required Frameworks**

1. **Select your project** in the navigator
2. **Select the HeardAI target**
3. **Go to "General" tab**
4. **Scroll to "Frameworks, Libraries, and Embedded Content"**
5. **Click "+" and add these frameworks:**

```
✅ AVFoundation.framework
✅ Speech.framework
✅ Intents.framework
✅ IntentsUI.framework
✅ Accelerate.framework
```

### **Step 3: Add Siri Capability**

1. **Go to "Signing & Capabilities" tab**
2. **Click "+" button**
3. **Search for "Siri"**
4. **Add "Siri" capability**

### **Step 4: Add New Service Files**

#### **4.1 Add ProperSiriKitService.swift**
1. **Right-click on "Services" folder** in project navigator
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `ProperSiriKitService.swift`**
6. **Copy and paste the content** from the file we created

#### **4.2 Add RobustWakeWordDetector.swift**
1. **Right-click on "Services" folder**
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `RobustWakeWordDetector.swift`**
6. **Copy and paste the content** from the file we created

#### **4.3 Add EnhancedAudioManager.swift**
1. **Right-click on "Services" folder**
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `EnhancedAudioManager.swift`**
6. **Copy and paste the content** from the file we created

#### **4.4 Add AudioFormatConverter.swift**
1. **Right-click on "Services" folder**
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `AudioFormatConverter.swift`**
6. **Copy and paste the content** from the file we created

### **Step 5: Add New View Files**

#### **5.1 Add UltimateContentView.swift**
1. **Right-click on "Views" folder**
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `UltimateContentView.swift`**
6. **Copy and paste the content** from the file we created

### **Step 6: Add New Utility Files**

#### **6.1 Create Utils Folder (if it doesn't exist)**
1. **Right-click on "HeardAI" folder**
2. **Select "New Group"**
3. **Name it: "Utils"**

#### **6.2 Add PerformanceMonitor.swift**
1. **Right-click on "Utils" folder**
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `PerformanceMonitor.swift`**
6. **Copy and paste the content** from the file we created

#### **6.3 Add FunctionalityTest.swift**
1. **Right-click on "Utils" folder**
2. **Select "Add Files to 'HeardAI'"**
3. **Click "Create New File"**
4. **Choose "Swift File"**
5. **Name it: `FunctionalityTest.swift`**
6. **Copy and paste the content** from the file we created

### **Step 7: Update Main App File**

#### **7.1 Replace HeardAIApp.swift**
1. **Open `HeardAIApp.swift`**
2. **Select all content** (Cmd+A)
3. **Delete it**
4. **Copy and paste the content** from `HeardAIApp_Ultimate.swift`

### **Step 8: Update ContentView.swift**

#### **8.1 Replace ContentView.swift**
1. **Open `ContentView.swift`**
2. **Select all content** (Cmd+A)
3. **Delete it**
4. **Copy and paste the content** from `UltimateContentView.swift`

### **Step 9: Configure Build Settings**

1. **Select the HeardAI target**
2. **Go to "Build Settings" tab**
3. **Set these values:**
   - **iOS Deployment Target**: 16.0
   - **Swift Language Version**: Swift 5
   - **Enable Bitcode**: No

### **Step 10: Add Environment Variable**

#### **Option A: Environment Variable (Recommended)**
1. **Go to Product → Scheme → Edit Scheme**
2. **Select "Run" on the left**
3. **Go to "Arguments" tab**
4. **Under "Environment Variables", click "+"**
5. **Add:**
   - **Name**: `OPENAI_API_KEY`
   - **Value**: Your OpenAI API key

#### **Option B: Info.plist**
1. **Open `Info.plist`**
2. **Add this entry:**
```xml
<key>OPENAI_API_KEY</key>
<string>your-api-key-here</string>
```

### **Step 11: Update Info.plist Permissions**

Ensure these permissions are in your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>HeardAI needs microphone access to listen for voice commands and the wake word "Hey HeardAI".</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>HeardAI uses speech recognition to accurately transcribe your voice commands before sending them to Siri.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>background-processing</string>
</array>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🔧 Verification Steps

### **Step 12: Build and Test**

1. **Clean Build Folder** (Product → Clean Build Folder)
2. **Build the project** (Cmd+B)
3. **Check for any compilation errors**
4. **Run on physical device** (not simulator)

### **Step 13: Test Basic Functionality**

1. **Launch the app**
2. **Grant permissions** when prompted:
   - Microphone access
   - Speech recognition
   - Siri access
3. **Check console output** for functionality test results
4. **Test wake word detection**: Say "Hey HeardAI"

## 🚨 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: "No such module 'AVFoundation'"**
**Solution:**
- Clean build folder (Product → Clean Build Folder)
- Check framework linking in target settings
- Verify deployment target is iOS 16.0+

#### **Issue: "Speech recognition not available"**
**Solution:**
- Ensure testing on physical device (not simulator)
- Check speech recognition permissions
- Verify internet connectivity

#### **Issue: "Audio session setup failed"**
**Solution:**
- Check microphone permissions
- Ensure device is not in silent mode
- Verify audio session configuration

#### **Issue: "OpenAI API key missing"**
**Solution:**
- Verify environment variable is set correctly
- Check API key validity
- Ensure network connectivity

#### **Issue: "Siri not responding"**
**Solution:**
- Check Siri capability in project settings
- Verify Siri permissions
- Test with simple commands first

## ✅ Final Checklist

### **Files Added Successfully:**
- [ ] `ProperSiriKitService.swift`
- [ ] `RobustWakeWordDetector.swift`
- [ ] `EnhancedAudioManager.swift`
- [ ] `AudioFormatConverter.swift`
- [ ] `UltimateContentView.swift`
- [ ] `PerformanceMonitor.swift`
- [ ] `FunctionalityTest.swift`
- [ ] Updated `HeardAIApp.swift`
- [ ] Updated `ContentView.swift`

### **Configuration Complete:**
- [ ] Required frameworks added
- [ ] Siri capability enabled
- [ ] Build settings configured
- [ ] Environment variable set
- [ ] Permissions configured
- [ ] Project builds successfully
- [ ] App runs on device
- [ ] Functionality tests pass

## 🎯 Expected Results

After successful integration:

1. **App launches** with functionality test results in console
2. **Wake word detection** works with multiple methods
3. **Command transcription** uses Whisper API + on-device fallback
4. **Siri integration** handles 8 different command types
5. **Performance monitoring** shows real-time metrics
6. **UI displays** confidence levels and detection methods

## 🚀 Next Steps

1. **Test wake word detection** in different environments
2. **Try various command types** (reminder, message, call, etc.)
3. **Monitor performance metrics** in the Performance tab
4. **Check battery optimization** in low power mode
5. **Verify Siri responses** for each command type

The enhanced HeardAI app should now be fully functional with robust wake word detection and proper SiriKit integration! 