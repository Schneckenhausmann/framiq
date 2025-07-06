# Contributing to Framiq

We love your input! We want to make contributing to Framiq as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## 🚀 Getting Started

### Prerequisites
- macOS 13.0+ (Ventura)
- Xcode 14.0+
- Swift 5.7+

### Setting Up Development Environment

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/Framiq.git
   cd Framiq
   ```
3. **Open in Xcode:**
   ```bash
   open Framiq.xcodeproj
   ```
4. **Build and run** to ensure everything works

## 📋 How to Contribute

### Reporting Bugs
Create an issue using the bug report template and include:
- macOS version
- Xcode version (if building from source)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

### Suggesting Features
Create an issue using the feature request template and include:
- Clear description of the feature
- Use cases and benefits
- Mockups or examples if helpful

### Code Contributions

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. **Make your changes** following our coding standards:
   - Use SwiftUI best practices
   - Follow Swift naming conventions
   - Add comments for complex logic
   - Ensure UI remains responsive

3. **Test thoroughly:**
   - Test on different macOS versions if possible
   - Test with various image formats
   - Test both single and batch processing modes

4. **Commit your changes:**
   ```bash
   git commit -m "Add amazing feature: brief description"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/amazing-feature
   ```

6. **Create a Pull Request** with:
   - Clear title and description
   - Screenshots/videos if UI changes
   - Reference any related issues

## 🎨 Coding Standards

### Swift/SwiftUI Guidelines
- Use `@State` and `@Binding` appropriately
- Prefer `@ObservableObject` for complex state management
- Use `async/await` for asynchronous operations
- Follow SwiftUI view composition principles

### UI/UX Guidelines
- Maintain the existing design language
- Ensure dark mode compatibility
- Use SF Symbols for consistency
- Maintain accessibility standards

### Performance
- Keep the UI responsive during processing
- Use background threads for image processing
- Optimize memory usage for large images
- Test with large batch operations

## 🔧 Development Tips

### Working with Images
- Use `NSImage` for macOS compatibility
- Handle memory management carefully
- Test with various image formats and sizes
- Consider performance implications

### Testing
- Test with real-world image collections
- Verify aspect ratio calculations
- Test error handling scenarios
- Ensure UI updates correctly

## 📝 Documentation

When adding features:
- Update the README if needed
- Add code comments for complex logic
- Update the documentation.md file
- Include examples in your PR description

## 🤝 Community

- Be respectful and constructive
- Help others with questions
- Share feedback and suggestions
- Collaborate openly

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You

Your contributions make Framiq better for everyone! Whether it's code, bug reports, feature requests, or documentation improvements, every contribution matters.

---

**Happy coding! 🎨✨** 