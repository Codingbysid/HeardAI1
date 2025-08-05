# Contributing to HeardAI

Thank you for your interest in contributing to HeardAI! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### **Types of Contributions**
- 🐛 **Bug Reports**: Report issues you encounter
- 💡 **Feature Requests**: Suggest new features or improvements
- 📝 **Documentation**: Improve or add documentation
- 🔧 **Code Contributions**: Submit pull requests with code changes
- 🧪 **Testing**: Help test the app and report findings

## 🚀 Getting Started

### **Prerequisites**
- Xcode 14.0 or later
- iOS 16.0 or later
- Physical iOS device for testing
- OpenAI API key
- Git

### **Development Setup**

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/yourusername/HeardAI.git
   cd HeardAI
   ```

2. **Set up the development environment**
   ```bash
   # Open in Xcode
   open HeardAI.xcodeproj
   ```

3. **Configure your environment**
   - Add your OpenAI API key to environment variables
   - Add required frameworks (AVFoundation, Speech, Intents, IntentsUI, Accelerate)
   - Add Siri capability

4. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Development Guidelines

### **Code Style**
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise

### **File Organization**
```
HeardAI/
├── Services/          # Business logic and external integrations
├── Views/            # SwiftUI views and UI components
├── Utils/            # Utility classes and helpers
├── Models/           # Data models (if any)
└── Resources/        # Assets and resources
```

### **Testing**
- Add unit tests for new functionality
- Test on physical device (not simulator)
- Verify wake word detection in different environments
- Test all supported command types

### **Documentation**
- Update README.md if adding new features
- Add inline comments for complex code
- Update API documentation if changing interfaces

## 🐛 Reporting Issues

### **Bug Report Template**
```markdown
**Bug Description**
Brief description of the issue

**Steps to Reproduce**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- iOS Version: [e.g., 16.0]
- Device: [e.g., iPhone 14]
- App Version: [e.g., 2.0.0]

**Additional Information**
Screenshots, logs, or other relevant information
```

### **Feature Request Template**
```markdown
**Feature Description**
Brief description of the requested feature

**Use Case**
Why this feature would be useful

**Proposed Implementation**
How you think it could be implemented

**Additional Information**
Any other relevant details
```

## 🔧 Submitting Pull Requests

### **Before Submitting**
- [ ] Code follows style guidelines
- [ ] Tests pass on physical device
- [ ] Documentation is updated
- [ ] No breaking changes (unless discussed)

### **Pull Request Template**
```markdown
**Description**
Brief description of changes

**Type of Change**
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

**Testing**
- [ ] Tested on physical device
- [ ] Wake word detection works
- [ ] Siri integration works
- [ ] Performance monitoring works

**Screenshots**
Add screenshots if UI changes

**Additional Notes**
Any other relevant information
```

## 🧪 Testing Guidelines

### **Required Testing**
- **Wake Word Detection**: Test in quiet and noisy environments
- **Command Transcription**: Test with various accents and speech patterns
- **Siri Integration**: Test all 8 command types
- **Performance**: Monitor CPU, memory, and battery usage
- **UI Responsiveness**: Test on different device sizes

### **Testing Checklist**
- [ ] App launches without errors
- [ ] Permissions are granted successfully
- [ ] Wake word detection works reliably
- [ ] Command recording functions properly
- [ ] Whisper API integration works
- [ ] Siri commands execute correctly
- [ ] Performance monitoring shows metrics
- [ ] Battery optimization activates
- [ ] UI updates in real-time

## 📋 Code Review Process

### **Review Criteria**
- **Functionality**: Does the code work as intended?
- **Performance**: Is the code efficient?
- **Security**: Are there any security concerns?
- **Maintainability**: Is the code easy to understand and maintain?
- **Testing**: Are there adequate tests?

### **Review Process**
1. Submit pull request
2. Automated checks run (if configured)
3. Maintainers review the code
4. Address feedback and make changes
5. Code is merged when approved

## 🎯 Areas for Contribution

### **High Priority**
- **Wake Word Detection**: Improve accuracy and reliability
- **Siri Integration**: Add more command types
- **Performance**: Optimize battery usage and response time
- **Testing**: Add comprehensive test coverage

### **Medium Priority**
- **UI/UX**: Improve user interface and experience
- **Documentation**: Enhance documentation and examples
- **Error Handling**: Improve error messages and recovery
- **Accessibility**: Add accessibility features

### **Low Priority**
- **Localization**: Add support for multiple languages
- **Customization**: Allow users to customize wake words
- **Analytics**: Add usage analytics (privacy-friendly)
- **Integration**: Add support for other voice assistants

## 📞 Getting Help

### **Resources**
- **Issues**: [GitHub Issues](https://github.com/yourusername/HeardAI/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/HeardAI/discussions)
- **Documentation**: [Wiki](https://github.com/yourusername/HeardAI/wiki)

### **Community Guidelines**
- Be respectful and inclusive
- Help others when possible
- Provide constructive feedback
- Follow the project's code of conduct

## 🏆 Recognition

Contributors will be recognized in:
- **README.md**: Listed as contributors
- **Release Notes**: Acknowledged for significant contributions
- **GitHub**: Shown in the contributors graph

## 📄 License

By contributing to HeardAI, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to HeardAI! Your contributions help make this project better for everyone. 🎉 