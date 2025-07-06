# Framiq - Professional Image Framing Application

## Overview

Framiq is a macOS SwiftUI application designed for professional image framing and processing. It provides both single image and batch processing capabilities, automatically resizing images to fit specified aspect ratios with optional white borders for a gallery-style presentation.

## Features

### Core Functionality
- **Single Image Processing**: Process individual images with drag & drop or file selection
- **Batch Processing**: Process entire directories of images
- **Aspect Ratio Fitting**: Automatically fits images within chosen canvas aspect ratios
- **Border Effects**: Optional white borders (0-50%) for gallery framing
- **Real-time Preview**: Live preview of how images will appear after processing
- **Progress Tracking**: Detailed progress indicators and completion status

### Supported Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- TIFF (.tiff, .tif)
- HEIC (.heic)

## Architecture

### Project Structure
```
IMG2Pixelfed/
├── IMG2Pixelfed.xcodeproj          # Xcode project file
├── IMG2Pixelfed/                   # Main source directory
│   ├── App.swift                   # Application entry point
│   ├── ContentView.swift           # Main UI components
│   ├── ImageProcessor.swift        # Core image processing logic
│   └── Info.plist                  # App configuration
├── docs/                           # Documentation
└── README.md                       # Project overview
```

## Application Components

### 1. App.swift
Main application entry point that sets up the SwiftUI app structure.

### 2. ContentView.swift
The primary UI file containing all SwiftUI components:

#### Main Views
- **ContentView**: Root view managing mode selection between single and batch processing
- **SingleImageView**: UI for single image processing mode
- **BatchProcessingView**: UI for batch processing mode

#### UI Components

##### Left Sidebar Components
- **SingleImageLeftSidebar**: Controls for single image mode
- **LeftSidebar**: Controls for batch processing mode
- **ModeSelector**: Toggle between single image and batch processing
- **ModernCanvasSettings**: Aspect ratio and border configuration
- **ModernDirectoryRow**: Directory selection interface

##### Center Preview Components
- **SingleImagePreviewArea**: Preview for single image mode
- **CenterPreviewArea**: Preview for batch processing mode
- **AutomaticPreviewArea**: Displays detected aspect ratios with interactive selection
- **RealImagePreview**: Renders actual image with applied settings
- **PreviewCard**: Small preview cards for detected image types
- **LargePreviewCard**: Main preview display

##### Right Sidebar Components
- **RightSidebar**: Processing status and results display
- **DetailedProcessingStatus**: Real-time processing progress
- **ProcessingResults**: Completion status and statistics
- **EmptyStateView**: Default state when no processing has occurred

##### Utility Components
- **FramiqLogo**: Application logo with gradient styling
- **SectionHeader**: Consistent section headers throughout the UI

### 3. ImageProcessor.swift
Core image processing engine handling:

#### Key Properties
```swift
@Published var isProcessing: Bool = false
@Published var progress: Double = 0.0
@Published var processedCount: Int = 0
@Published var totalCount: Int = 0
@Published var currentFile: String = ""
@Published var processedImages: [String] = []
@Published var skippedImages: [String] = []
@Published var detectedAspectRatios: [DetectedAspectRatio] = []
```

#### Core Methods
- `processSingleImage()`: Handles single image processing with _framiq suffix
- `startProcessing()`: Manages batch processing of directory
- `detectAspectRatios()`: Analyzes input directory for image aspect ratios
- `processImage()`: Core image processing algorithm
- `cancelProcessing()`: Allows user to stop processing

## Data Models

### AspectRatio Enum
Predefined aspect ratios for canvas sizing:
- Square (1:1)
- Portrait variations (4:5, 2:3, 3:4, 9:16)
- Landscape variations (3:2, 4:3, 16:9)
- Custom ratio support

### DetectedAspectRatio Struct
```swift
struct DetectedAspectRatio: Identifiable {
    let id = UUID()
    let width: Double
    let height: Double
    let count: Int
    let sampleFileName: String
    
    var ratio: Double { width / height }
    var displayName: String { /* formatted name */ }
}
```

## Image Processing Algorithm

### Core Logic
1. **Image Loading**: Load source image using NSImage
2. **Canvas Calculation**: Determine target canvas size based on image's longest dimension
3. **Aspect Ratio Fitting**: Calculate how image fits within chosen aspect ratio
4. **Border Application**: Add optional white border around canvas
5. **Image Rendering**: Create final composite image
6. **File Output**: Save processed image with appropriate naming

### Canvas Sizing Algorithm
```swift
// Calculate canvas dimensions based on longest side
let longestSide = max(imageSize.width, imageSize.height)
let canvasWidth = longestSide * aspectRatio.width / max(aspectRatio.width, aspectRatio.height)
let canvasHeight = longestSide * aspectRatio.height / max(aspectRatio.width, aspectRatio.height)

// Apply border if specified
let borderMultiplier = 1.0 + (borderPercentage / 100.0)
let finalWidth = canvasWidth * borderMultiplier
let finalHeight = canvasHeight * borderMultiplier
```

### Image Fitting Logic
- **Aspect Ratio Preservation**: Original image aspect ratio is always maintained
- **Fit-to-Canvas**: Images are scaled to fit within canvas bounds
- **White Background**: Canvas uses white background for professional appearance
- **Center Positioning**: Images are centered within their allocated space

## User Interface Design

### Layout Structure
- **Horizontal Three-Panel Layout**: Optimized for desktop workflow
- **Left Panel**: Controls and settings (300px width)
- **Center Panel**: Live preview area (flexible width)
- **Right Panel**: Status and results (250px width)

### Visual Design
- **Dark Theme**: Consistent dark color scheme throughout
- **Material Effects**: Translucent backgrounds using `.ultraThinMaterial`
- **Gradient Accents**: Blue-to-purple gradients for interactive elements
- **Typography Hierarchy**: Clear text sizing and weight differentiation

### Interactive Elements
- **Mode Toggle**: Segmented control for switching between single/batch modes
- **Directory Selection**: Native macOS file picker integration
- **Drag & Drop**: Support for image files in single image mode
- **Clickable Previews**: Interactive aspect ratio selection in batch mode
- **Real-time Sliders**: Border percentage adjustment with live preview

## File Naming Conventions

### Single Image Mode
- Input: `original_image.jpg`
- Output: `original_image_framiq.jpg` (same directory as source)

### Batch Processing Mode
- Input directory: Contains source images
- Output directory: User-specified destination
- Naming: Preserves original filenames in output directory

## Performance Considerations

### Asynchronous Processing
- All image processing occurs on background threads
- UI updates are dispatched to main thread using `@MainActor`
- Progress tracking enables responsive user interface during processing

### Memory Management
- Images are processed individually to minimize memory footprint
- Large images are handled efficiently through CoreGraphics
- Automatic memory cleanup after processing completion

### Error Handling
- Graceful handling of unsupported file formats
- Directory access permission management
- User feedback for processing errors

## Recent Updates & Improvements

### Version 1.1 - Enhanced Reactivity (Latest)

#### 🚀 Major Improvements
- **Real-time Preview System**: Complete redesign of preview components with instant reactivity
- **Reactive State Management**: Implemented UUID-based refresh triggers for immediate UI updates
- **Smooth Animations**: Added elegant easeInOut transitions for all UI interactions
- **Auto-Selection Enhancement**: Streamlined batch preview auto-selection logic
- **Status Display Improvements**: Enhanced right sidebar with computed properties and preserved results

#### ✅ Issues Resolved
1. **Single Image Status Display**: ~~Right sidebar may not consistently show completion status~~ → **FIXED**
   - Enhanced RightSidebar with @ObservedObject and computed properties
   - Added clearActiveProcessing() method to preserve completed results during mode switching
   - Improved display conditions with hasCompletedProcessing logic

2. **Batch Preview Auto-Selection**: ~~Aspect ratio preview may not automatically select first detected type~~ → **FIXED**
   - Simplified auto-selection to direct, synchronous logic
   - Removed complex async patterns that were fighting SwiftUI's update cycle
   - Added animated selection transitions with withAnimation

3. **Preview Reactivity**: ~~Some preview updates may require manual interaction to trigger~~ → **FIXED**
   - Implemented comprehensive refreshTrigger system using UUID
   - All preview components now use computed properties that auto-recalculate
   - Added smooth animations for dimension changes (.easeInOut duration: 0.2)
   - Enhanced onChange handlers for immediate setting updates

#### 🔧 Technical Enhancements
- **Reactive Architecture**: Replaced id() modifiers with proper refreshTrigger system
- **Performance Optimizations**: Computed properties only recalculate when needed
- **Animation System**: Comprehensive animation framework for all UI transitions
- **State Preservation**: Mode switching preserves processing results while clearing active state
- **Memory Efficiency**: Improved image loading and preview generation

### Technical Limitations
- **macOS Only**: Application is designed specifically for macOS
- **File Size**: Very large images (>100MB) may experience slower processing
- **Concurrent Processing**: Currently processes images sequentially, not in parallel

## Development Environment

### Requirements
- **Xcode**: Version 14.0 or later
- **macOS**: Version 12.0 or later for development
- **Swift**: Version 5.7 or later
- **SwiftUI**: iOS 16.0+ / macOS 13.0+ target

### Build Configuration
- **Target**: macOS 13.0
- **Architecture**: Universal (Apple Silicon + Intel)
- **Bundle Identifier**: `com.example.framiq`

## Future Enhancement Opportunities

### Feature Additions
- **Parallel Processing**: Implement concurrent image processing for batch operations
- **Additional Formats**: Support for more image formats (WebP, AVIF)
- **Batch Preview**: Thumbnail grid for batch processing preview
- **Export Options**: Additional output format options and quality settings
- **Metadata Preservation**: Maintain EXIF data in processed images

### Performance Improvements
- **Image Caching**: Cache processed previews for faster UI updates
- **Progressive Loading**: Stream preview updates during batch processing
- **Memory Optimization**: Implement image streaming for very large files

### User Experience Enhancements
- **Undo/Redo**: Operation history management
- **Presets**: Save and load aspect ratio and border combinations
- **Drag & Drop Batch**: Support for dropping multiple files or folders
- **Preview Zoom**: Detailed preview inspection capabilities

## Troubleshooting

### Common Issues

#### App Won't Launch
- Verify macOS version compatibility (13.0+)
- Check Xcode build configuration
- Ensure proper code signing

#### Images Not Processing
- Verify file format support
- Check directory permissions
- Ensure sufficient disk space for output

#### Preview Not Updating
- Switch between modes to refresh state
- Adjust border slider to trigger updates
- Restart application if persistent

#### Performance Issues
- Close other memory-intensive applications
- Process smaller batches for very large images
- Ensure adequate free disk space

### Debug Information
The application logs processing information to the console, accessible through:
- Xcode console during development
- Console.app for installed applications

## Contributing

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices for reactive UI
- Maintain consistent indentation and formatting
- Include inline documentation for complex algorithms

### Testing Guidelines
- Test with various image formats and sizes
- Verify UI responsiveness during processing
- Test edge cases (empty directories, invalid files)
- Validate preview accuracy across different aspect ratios

---

*Documentation last updated: [Current Date]*
*Version: 1.0.0* 