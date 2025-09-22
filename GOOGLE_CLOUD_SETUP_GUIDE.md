# Google Cloud Speech-to-Text Setup Guide

## 🎯 Overview
This guide will help you set up Google Cloud Speech-to-Text API for the HeardAI app, replacing the paid OpenAI Whisper API with Google's free tier (60 minutes/month).

## 📋 Prerequisites
- Google account
- Credit card (for verification, but free tier won't charge)
- Xcode project ready

## 🚀 Step-by-Step Setup

### Step 1: Create Google Cloud Project

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create New Project**
   - Click "Select a project" dropdown
   - Click "New Project"
   - Project name: `HeardAI-SpeechAPI`
   - Click "Create"

3. **Enable Speech-to-Text API**
   - Go to: https://console.cloud.google.com/apis/library
   - Search for "Cloud Speech-to-Text API"
   - Click on it and click "Enable"

### Step 2: Create Service Account

1. **Navigate to Service Accounts**
   - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts
   - Click "Create Service Account"

2. **Configure Service Account**
   - Service account name: `heardai-speech-service`
   - Service account ID: `heardai-speech-service`
   - Description: `Service account for HeardAI speech recognition`
   - Click "Create and Continue"

3. **Grant Permissions**
   - Role: Select "Cloud Speech Client"
   - Click "Continue"
   - Click "Done"

### Step 3: Generate API Key

1. **Create JSON Key**
   - Click on your service account
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Select "JSON" format
   - Click "Create"
   - **Save the downloaded JSON file securely**

### Step 4: Get API Key (Alternative Method)

For simpler integration, you can also use an API key:

1. **Go to Credentials**
   - Visit: https://console.cloud.google.com/apis/credentials
   - Click "Create Credentials" → "API key"
   - Copy the generated API key
   - **Restrict the key** (recommended):
     - Click "Restrict key"
     - Under "API restrictions", select "Cloud Speech-to-Text API"
     - Save

## 🔧 Integration Options

### Option A: Using API Key (Simpler)
- Use the API key in HTTP requests
- Easier to integrate
- Good for testing and development

### Option B: Using Service Account JSON (More Secure)
- Use the downloaded JSON file
- Better for production
- More secure authentication

## 📊 Free Tier Limits

- **60 minutes** of audio processing per month
- **Standard models** included
- **Enhanced models** available with additional cost
- Perfect for beta testing!

## 🔒 Security Notes

- **Never commit API keys or JSON files to Git**
- Store credentials securely
- Use environment variables
- Consider using restricted API keys

## ✅ Verification

Test your setup:
```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json; charset=utf-8" \
  "https://speech.googleapis.com/v1/speech:recognize" \
  -d '{
    "config": {
      "encoding":"WEBM_OPUS",
      "sampleRateHertz":48000,
      "languageCode":"en-US"
    },
    "audio": {
      "content":"test"
    }
  }'
```

## 🎯 Next Steps

After completing this setup:
1. Note down your API key or save your JSON file
2. We'll integrate it into the HeardAI app
3. Replace the WhisperService with GoogleSpeechService
4. Test the integration

Your Google Cloud Speech-to-Text API is now ready for integration! 🎉
