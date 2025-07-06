import SwiftUI
import UniformTypeIdentifiers
import AppKit

enum AspectRatio: String, CaseIterable, Identifiable {
    case square = "Square (1:1)"
    case portrait45 = "Portrait 4:5"
    case portrait23 = "Portrait 2:3"
    case portrait35 = "Portrait 3:5"
    case landscape54 = "Landscape 5:4"
    case landscape32 = "Landscape 3:2"
    case landscape169 = "Landscape 16:9"
    case story916 = "Story 9:16"
    case custom = "Custom Ratio"
    
    var id: String { self.rawValue }
    
    var ratio: (width: Double, height: Double) {
        switch self {
        case .square:
            return (1.0, 1.0)
        case .portrait45:
            return (4.0, 5.0)
        case .portrait23:
            return (2.0, 3.0)
        case .portrait35:
            return (3.0, 5.0)
        case .landscape54:
            return (5.0, 4.0)
        case .landscape32:
            return (3.0, 2.0)
        case .landscape169:
            return (16.0, 9.0)
        case .story916:
            return (9.0, 16.0)
        case .custom:
            return (4.0, 5.0) // Default
        }
    }
}

struct ContentView: View {
    @StateObject private var imageProcessor = ImageProcessor()
    @State private var selectedMode = 0 // 0 = Single Image, 1 = Batch Processing
    
    var body: some View {
        Group {
            if selectedMode == 0 {
                SingleImageView(imageProcessor: imageProcessor, selectedMode: $selectedMode)
            } else {
                BatchProcessingView(imageProcessor: imageProcessor, selectedMode: $selectedMode)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SingleImageView: View {
    @ObservedObject var imageProcessor: ImageProcessor
    @Binding var selectedMode: Int
    @State private var selectedImage: URL?
    @State private var selectedAspectRatio: AspectRatio = .portrait45
    @State private var customWidthRatio: String = "4"
    @State private var customHeightRatio: String = "5"
    @State private var borderPercentage: Double = 0.0
    @State private var showingFilePicker = false
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left Sidebar - Controls
                SingleImageLeftSidebar(
                    selectedMode: $selectedMode,
                    selectedImage: $selectedImage,
                    selectedAspectRatio: $selectedAspectRatio,
                    customWidthRatio: $customWidthRatio,
                    customHeightRatio: $customHeightRatio,
                    borderPercentage: $borderPercentage,
                    showingFilePicker: $showingFilePicker,
                    onProcessImage: processSingleImage,
                    imageProcessor: imageProcessor
                )
                .frame(width: 380)
                
                // Center - Preview Area
                SingleImagePreviewArea(
                    selectedImage: selectedImage,
                    selectedAspectRatio: selectedAspectRatio,
                    customWidthRatio: customWidthRatio,
                    customHeightRatio: customHeightRatio,
                    borderPercentage: borderPercentage
                )
                .frame(maxWidth: .infinity)
                
                // Right Sidebar - Status & Results
                RightSidebar(imageProcessor: imageProcessor)
                    .frame(width: 320)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result: result)
        }
    }
    
    private func processSingleImage() {
        guard let imageURL = selectedImage else { return }
        
        let aspectRatio = getAspectRatio()
        imageProcessor.processSingleImage(
            inputURL: imageURL,
            aspectRatio: aspectRatio,
            borderPercentage: borderPercentage
        )
    }
    
    private func getAspectRatio() -> (width: Double, height: Double) {
        if selectedAspectRatio == .custom {
            let width = Double(customWidthRatio) ?? 4.0
            let height = Double(customHeightRatio) ?? 5.0
            return (width, height)
        } else {
            return selectedAspectRatio.ratio
        }
    }
    
    private func handleImageSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedImage = url
            }
        case .failure(let error):
            print("Error selecting image: \(error)")
        }
    }
}

struct BatchProcessingView: View {
    @ObservedObject var imageProcessor: ImageProcessor
    @Binding var selectedMode: Int
    @State private var inputDirectory: URL?
    @State private var outputDirectory: URL?
    @State private var showingOutputPicker = false
    @State private var selectedAspectRatio: AspectRatio = .portrait45
    @State private var customWidthRatio: String = "4"
    @State private var customHeightRatio: String = "5"
    @State private var borderPercentage: Double = 0.0
    @State private var selectedPreviewAspectRatio: DetectedAspectRatio?
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left Sidebar - Controls
                LeftSidebar(
                    selectedMode: $selectedMode,
                    inputDirectory: $inputDirectory,
                    outputDirectory: $outputDirectory,
                    showingOutputPicker: $showingOutputPicker,
                    selectedAspectRatio: $selectedAspectRatio,
                    customWidthRatio: $customWidthRatio,
                    customHeightRatio: $customHeightRatio,
                    borderPercentage: $borderPercentage,
                    onSelectInput: selectInputDirectory,
                    canStartProcessing: canStartProcessing,
                    onStartProcessing: startProcessing,
                    imageProcessor: imageProcessor
                )
                .frame(width: 380)
                
                // Center - Preview Area
                CenterPreviewArea(
                    selectedAspectRatio: selectedAspectRatio,
                    customWidthRatio: customWidthRatio,
                    customHeightRatio: customHeightRatio,
                    borderPercentage: borderPercentage,
                    imageProcessor: imageProcessor,
                    inputDirectory: inputDirectory,
                    selectedPreviewAspectRatio: $selectedPreviewAspectRatio
                )
                .frame(maxWidth: .infinity)
                
                // Right Sidebar - Status & Results
                RightSidebar(imageProcessor: imageProcessor)
                    .frame(width: 320)
            }
        }
        .fileImporter(
            isPresented: $showingOutputPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleDirectorySelection(result: result)
        }
    }
    
    private var canStartProcessing: Bool {
        inputDirectory != nil && outputDirectory != nil && !imageProcessor.isProcessing
    }
    
    private func selectInputDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.title = "Select Input Directory"
        panel.message = "Choose the folder containing your images"
        
        if panel.runModal() == .OK {
            inputDirectory = panel.url
        }
    }
    
    private func startProcessing() {
        guard let inputDir = inputDirectory,
              let outputDir = outputDirectory else { return }
        
        let aspectRatio = getAspectRatio()
        imageProcessor.processImages(
            inputDirectory: inputDir,
            outputDirectory: outputDir,
            aspectRatio: aspectRatio,
            borderPercentage: borderPercentage
        )
    }
    
    private func getAspectRatio() -> (width: Double, height: Double) {
        if selectedAspectRatio == .custom {
            let width = Double(customWidthRatio) ?? 4.0
            let height = Double(customHeightRatio) ?? 5.0
            return (width, height)
        } else {
            return selectedAspectRatio.ratio
        }
    }
    
    private func handleDirectorySelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                outputDirectory = url
            }
        case .failure(let error):
            print("Error selecting directory: \(error)")
        }
    }
}

// MARK: - Single Image Components
struct SingleImageLeftSidebar: View {
    @Binding var selectedMode: Int
    @Binding var selectedImage: URL?
    @Binding var selectedAspectRatio: AspectRatio
    @Binding var customWidthRatio: String
    @Binding var customHeightRatio: String
    @Binding var borderPercentage: Double
    @Binding var showingFilePicker: Bool
    let onProcessImage: () -> Void
    let imageProcessor: ImageProcessor
    
    private var canProcess: Bool {
        selectedImage != nil && !imageProcessor.isProcessing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Logo
            VStack(spacing: 16) {
                // Logo
                FramiqLogo()
                
                Text("Professional Image Framing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Mode Selector
                ModeSelector(selectedMode: $selectedMode)
                    .onChange(of: selectedMode) { newMode in
                        // Only clear active processing, preserve completed results
                        imageProcessor.clearActiveProcessing()
                    }
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Image Selection
                    VStack(spacing: 16) {
                        SectionHeader(title: "Image Selection", icon: "photo.fill")
                        
                        Button(action: { showingFilePicker = true }) {
                            VStack(spacing: 12) {
                                if let selectedImage = selectedImage {
                                    HStack(spacing: 12) {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Selected Image")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Text(selectedImage.lastPathComponent)
                                                .font(.system(size: 12))
                                                .foregroundColor(.blue)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                        
                                        Text("Click to select image")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("Or drag and drop an image here")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 20)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                                    .background(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onDrop(of: [.image], isTargeted: nil) { providers in
                            guard let provider = providers.first else { return false }
                            
                            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                                guard let url = item as? URL else { return }
                                
                                DispatchQueue.main.async {
                                    selectedImage = url
                                }
                            }
                            return true
                        }
                        
                        if let selectedImage = selectedImage {
                            Text("Output: \(selectedImage.deletingPathExtension().lastPathComponent)_framiq.\(selectedImage.pathExtension)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Canvas Settings
                    VStack(spacing: 16) {
                        SectionHeader(title: "Frame Settings", icon: "viewfinder")
                        
                        ModernCanvasSettings(
                            selectedAspectRatio: $selectedAspectRatio,
                            customWidthRatio: $customWidthRatio,
                            customHeightRatio: $customHeightRatio,
                            borderPercentage: $borderPercentage
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Action Button
                    VStack(spacing: 12) {
                        Button(action: onProcessImage) {
                            HStack {
                                Image(systemName: imageProcessor.isProcessing ? "stop.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(imageProcessor.isProcessing ? "Stop Processing" : "Process Image")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: imageProcessor.isProcessing ? 
                                        [Color.red.opacity(0.8), Color.red] :
                                        [Color.blue.opacity(0.8), Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!canProcess && !imageProcessor.isProcessing)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            
            Spacer()
        }
        .background(
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
        )
    }
}

struct SingleImagePreviewArea: View {
    let selectedImage: URL?
    let selectedAspectRatio: AspectRatio
    let customWidthRatio: String
    let customHeightRatio: String
    let borderPercentage: Double
    
    // Add reactive state
    @State private var refreshTrigger = UUID()
    
    private func getCurrentAspectRatio() -> (width: Double, height: Double) {
        if selectedAspectRatio == .custom {
            let width = Double(customWidthRatio) ?? 4.0
            let height = Double(customHeightRatio) ?? 5.0
            return (width, height)
        } else {
            return selectedAspectRatio.ratio
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Live Preview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let selectedImage = selectedImage {
                // Show preview with actual selected image
                RealImagePreview(
                    imageURL: selectedImage,
                    canvasAspectRatio: getCurrentAspectRatio(),
                    borderPercentage: borderPercentage,
                    refreshTrigger: refreshTrigger
                )
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("No Image Selected")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Select an image to see the preview")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.white.opacity(0.05)
                .background(.ultraThinMaterial)
        )
        .onChange(of: selectedAspectRatio) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: customWidthRatio) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: customHeightRatio) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: borderPercentage) { _ in
            refreshTrigger = UUID()
        }
    }
}

struct RealImagePreview: View {
    let imageURL: URL
    let canvasAspectRatio: (width: Double, height: Double)
    let borderPercentage: Double
    let refreshTrigger: UUID
    
    @State private var image: NSImage?
    
    // Make dimensions computed so they update automatically
    private var dimensions: (canvas: CGSize, finalCanvas: CGSize, image: CGSize) {
        guard let image = image else {
            return (canvas: CGSize(width: 200, height: 200), finalCanvas: CGSize(width: 200, height: 200), image: CGSize(width: 200, height: 200))
        }
        
        let baseSize: CGFloat = 300
        let canvasRatio = canvasAspectRatio.width / canvasAspectRatio.height
        
        let canvasSize: CGSize
        if canvasRatio > 1 {
            canvasSize = CGSize(width: baseSize, height: baseSize / canvasRatio)
        } else {
            canvasSize = CGSize(width: baseSize * canvasRatio, height: baseSize)
        }
        
        let borderMultiplier = 1.0 + (borderPercentage / 100.0)
        let finalCanvasSize = CGSize(
            width: canvasSize.width * borderMultiplier,
            height: canvasSize.height * borderMultiplier
        )
        
        let imageRatio = image.size.width / image.size.height
        let canvasAspectRatioValue = canvasSize.width / canvasSize.height
        
        let imageSize: CGSize
        if imageRatio > canvasAspectRatioValue {
            imageSize = CGSize(width: canvasSize.width, height: canvasSize.width / imageRatio)
        } else {
            imageSize = CGSize(width: canvasSize.height * imageRatio, height: canvasSize.height)
        }
        
        return (canvas: canvasSize, finalCanvas: finalCanvasSize, image: imageSize)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Preview
            ZStack {
                // Drop shadow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .frame(
                        width: dimensions.finalCanvas.width + 8,
                        height: dimensions.finalCanvas.height + 8
                    )
                    .blur(radius: 8)
                    .offset(y: 4)
                
                // Final canvas with border
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: dimensions.finalCanvas.width, height: dimensions.finalCanvas.height)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                // Canvas area
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: dimensions.canvas.width, height: dimensions.canvas.height)
                
                // Actual image
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: dimensions.image.width, height: dimensions.image.height)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: dimensions.finalCanvas)
            .animation(.easeInOut(duration: 0.2), value: dimensions.canvas)
            .animation(.easeInOut(duration: 0.2), value: dimensions.image)
            
            // Info
            VStack(spacing: 4) {
                Text("Canvas: \(String(format: "%.1f", canvasAspectRatio.width)):\(String(format: "%.1f", canvasAspectRatio.height))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if borderPercentage > 0 {
                    Text("Border: \(Int(borderPercentage))%")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .onAppear {
            loadImage()
        }
        .onChange(of: imageURL) { _ in
            loadImage()
        }
        .onChange(of: refreshTrigger) { _ in
            // This triggers a view update when settings change
        }
    }
    
    private func loadImage() {
        image = NSImage(contentsOf: imageURL)
    }
}

// MARK: - Left Sidebar
struct LeftSidebar: View {
    @Binding var selectedMode: Int
    @Binding var inputDirectory: URL?
    @Binding var outputDirectory: URL?
    @Binding var showingOutputPicker: Bool
    @Binding var selectedAspectRatio: AspectRatio
    @Binding var customWidthRatio: String
    @Binding var customHeightRatio: String
    @Binding var borderPercentage: Double
    let onSelectInput: () -> Void
    let canStartProcessing: Bool
    let onStartProcessing: () -> Void
    let imageProcessor: ImageProcessor
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Logo
            VStack(spacing: 16) {
                // Logo
                FramiqLogo()
                
                Text("Professional Image Framing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Mode Selector
                ModeSelector(selectedMode: $selectedMode)
                    .onChange(of: selectedMode) { newMode in
                        // Only clear active processing, preserve completed results
                        imageProcessor.clearActiveProcessing()
                    }
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Directory Selection
                    VStack(spacing: 16) {
                        SectionHeader(title: "Source & Destination", icon: "folder.fill")
                        
                        ModernDirectoryRow(
                            title: "Input Folder",
                            subtitle: "Source images",
                            icon: "square.and.arrow.down.fill",
                            directory: inputDirectory,
                            onSelect: onSelectInput
                        )
                        
                        ModernDirectoryRow(
                            title: "Output Folder", 
                            subtitle: "Processed images",
                            icon: "square.and.arrow.up.fill",
                            directory: outputDirectory,
                            onSelect: { showingOutputPicker = true }
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Canvas Settings
                    VStack(spacing: 16) {
                        SectionHeader(title: "Frame Settings", icon: "viewfinder")
                        
                        ModernCanvasSettings(
                            selectedAspectRatio: $selectedAspectRatio,
                            customWidthRatio: $customWidthRatio,
                            customHeightRatio: $customHeightRatio,
                            borderPercentage: $borderPercentage
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Action Button
                    VStack(spacing: 12) {
                        Button(action: onStartProcessing) {
                            HStack {
                                Image(systemName: imageProcessor.isProcessing ? "stop.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(imageProcessor.isProcessing ? "Stop Processing" : "Start Processing")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: imageProcessor.isProcessing ? 
                                        [Color.red.opacity(0.8), Color.red] :
                                        [Color.blue.opacity(0.8), Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!canStartProcessing && !imageProcessor.isProcessing)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            
            Spacer()
        }
        .background(
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Center Preview Area
struct CenterPreviewArea: View {
    let selectedAspectRatio: AspectRatio
    let customWidthRatio: String
    let customHeightRatio: String
    let borderPercentage: Double
    let imageProcessor: ImageProcessor
    let inputDirectory: URL?
    @Binding var selectedPreviewAspectRatio: DetectedAspectRatio?
    
    // Add reactive state for real-time updates
    @State private var refreshTrigger = UUID()
    
    private func getCurrentAspectRatio() -> (width: Double, height: Double) {
        if selectedAspectRatio == .custom {
            let width = Double(customWidthRatio) ?? 4.0
            let height = Double(customHeightRatio) ?? 5.0
            return (width, height)
        } else {
            return selectedAspectRatio.ratio
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Live Preview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let inputDirectory = inputDirectory, !imageProcessor.detectedAspectRatios.isEmpty {
                // Show multiple previews based on detected aspect ratios
                AutomaticPreviewArea(
                    canvasAspectRatio: getCurrentAspectRatio(),
                    borderPercentage: borderPercentage,
                    detectedAspectRatios: imageProcessor.detectedAspectRatios,
                    selectedPreviewAspectRatio: $selectedPreviewAspectRatio,
                    refreshTrigger: refreshTrigger
                )
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("No Images Detected")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Select an input directory to see image previews")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.white.opacity(0.05)
                .background(.ultraThinMaterial)
        )
        .onChange(of: inputDirectory) { newDirectory in
            if let directory = newDirectory {
                selectedPreviewAspectRatio = nil
                imageProcessor.detectAspectRatios(inputDirectory: directory)
            } else {
                imageProcessor.detectedAspectRatios = []
                selectedPreviewAspectRatio = nil
            }
        }
        .onChange(of: imageProcessor.detectedAspectRatios) { aspectRatios in
            // Simple and direct auto-selection - no async needed
            if !aspectRatios.isEmpty && selectedPreviewAspectRatio == nil {
                selectedPreviewAspectRatio = aspectRatios.first
            }
        }
        .onChange(of: selectedAspectRatio) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: customWidthRatio) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: customHeightRatio) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: borderPercentage) { _ in
            refreshTrigger = UUID()
        }
    }
}

// MARK: - Right Sidebar
struct RightSidebar: View {
    @ObservedObject var imageProcessor: ImageProcessor
    
    // Computed property to determine what to show
    private var shouldShowResults: Bool {
        !imageProcessor.processedImages.isEmpty || !imageProcessor.skippedImages.isEmpty
    }
    
    private var hasCompletedProcessing: Bool {
        shouldShowResults && !imageProcessor.isProcessing
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                SectionHeader(title: "Processing Status", icon: "chart.bar.fill")
                
                Group {
                    if imageProcessor.isProcessing {
                        DetailedProcessingStatus(processor: imageProcessor)
                    } else if hasCompletedProcessing {
                        ProcessingResults(processor: imageProcessor)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        EmptyStateView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: imageProcessor.isProcessing)
                .animation(.easeInOut(duration: 0.2), value: hasCompletedProcessing)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
        .background(
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
        )
    }
}

struct DirectorySelectionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let directory: URL?
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let directory = directory {
                    Text(directory.path)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Select") {
                onSelect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ProcessingStatusView: View {
    @ObservedObject var processor: ImageProcessor
    
    var body: some View {
        VStack(spacing: 15) {
            ProgressView(value: processor.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            VStack(spacing: 5) {
                Text("Processing Images...")
                    .font(.headline)
                
                if !processor.currentFile.isEmpty {
                    Text("Current: \(processor.currentFile)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(processor.processedCount) of \(processor.totalCount) images processed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ResultsSummaryView: View {
    @ObservedObject var processor: ImageProcessor
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Processing Complete!")
                .font(.headline)
                .foregroundColor(.green)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(processor.processedImages.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Processed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(processor.skippedImages.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Skipped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct CanvasSizeSelectionView: View {
    @Binding var selectedAspectRatio: AspectRatio
    @Binding var customWidthRatio: String
    @Binding var customHeightRatio: String
    @Binding var borderPercentage: Double
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "viewfinder")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Canvas Settings")
                        .font(.headline)
                    
                    Text("Choose aspect ratio and border for your images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                // Aspect Ratio Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aspect Ratio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                        ForEach(AspectRatio.allCases) { ratio in
                            Text(ratio.rawValue).tag(ratio)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedAspectRatio) { newValue in
                        if newValue != .custom {
                            let ratio = newValue.ratio
                            customWidthRatio = String(format: "%.0f", ratio.width)
                            customHeightRatio = String(format: "%.0f", ratio.height)
                        }
                    }
                }
                
                // Custom Ratio Input (only shown when custom is selected)
                if selectedAspectRatio == .custom {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Width Ratio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("4", text: $customWidthRatio)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: customWidthRatio) { newValue in
                                    customWidthRatio = newValue.filter { $0.isNumber || $0 == "." }
                                }
                        }
                        
                        Text(":")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Height Ratio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("5", text: $customHeightRatio)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: customHeightRatio) { newValue in
                                    customHeightRatio = newValue.filter { $0.isNumber || $0 == "." }
                                }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Border/Passepartout Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Border Size")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(borderPercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $borderPercentage, in: 0...50, step: 1) {
                        Text("Border Size")
                    }
                    .tint(.blue)
                    
                    Text("Add extra white space around the image for a passepartout effect")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Preview Section
            AspectRatioPreview(
                canvasAspectRatio: getCurrentAspectRatio(),
                borderPercentage: borderPercentage
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func getCurrentAspectRatio() -> (width: Double, height: Double) {
        if selectedAspectRatio == .custom {
            let width = Double(customWidthRatio) ?? 4.0
            let height = Double(customHeightRatio) ?? 5.0
            return (width, height)
        } else {
            return selectedAspectRatio.ratio
        }
    }
}

struct AspectRatioPreview: View {
    let canvasAspectRatio: (width: Double, height: Double)
    let borderPercentage: Double
    
    @State private var selectedSampleImage: SampleImageType = .portrait23
    
    enum SampleImageType: String, CaseIterable {
        case landscape32 = "3:2 Landscape"
        case landscape169 = "16:9 Landscape" 
        case square = "1:1 Square"
        case portrait23 = "2:3 Portrait"
        case portrait45 = "4:5 Portrait"
        
        var ratio: Double {
            switch self {
            case .landscape32: return 3.0/2.0
            case .landscape169: return 16.0/9.0
            case .square: return 1.0
            case .portrait23: return 2.0/3.0
            case .portrait45: return 4.0/5.0
            }
        }
    }
    
    private var canvasDimensions: (width: CGFloat, height: CGFloat) {
        let maxDimension: CGFloat = 100  // Base canvas size
        let aspectRatioValue = canvasAspectRatio.width / canvasAspectRatio.height
        
        if aspectRatioValue > 1 {
            // Landscape canvas
            return (maxDimension, maxDimension / aspectRatioValue)
        } else {
            // Portrait or square canvas
            return (maxDimension * aspectRatioValue, maxDimension)
        }
    }
    
    private var finalCanvasDimensions: (width: CGFloat, height: CGFloat) {
        let borderMultiplier = 1.0 + (borderPercentage / 100.0)
        return (
            canvasDimensions.width * borderMultiplier,
            canvasDimensions.height * borderMultiplier
        )
    }
    
    private var imageDimensions: (width: CGFloat, height: CGFloat) {
        // Calculate how the sample image fits within the canvas
        let canvasRatio = canvasDimensions.width / canvasDimensions.height
        let sampleImageRatio = selectedSampleImage.ratio
        
        let imageWidth: CGFloat
        let imageHeight: CGFloat
        
        if sampleImageRatio > canvasRatio {
            // Image is wider relative to canvas, fit to width
            imageWidth = canvasDimensions.width
            imageHeight = canvasDimensions.width / sampleImageRatio
        } else {
            // Image is taller relative to canvas, fit to height
            imageHeight = canvasDimensions.height
            imageWidth = canvasDimensions.height * sampleImageRatio
        }
        
        return (imageWidth, imageHeight)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Sample Image Type Picker
            Picker("Sample Image", selection: $selectedSampleImage) {
                ForEach(SampleImageType.allCases, id: \.self) { imageType in
                    Text(imageType.rawValue).tag(imageType)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(.caption)
            
            ZStack {
                // Final canvas with border (white background to show border)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: finalCanvasDimensions.width, height: finalCanvasDimensions.height)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                
                // Canvas without border (white background)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: canvasDimensions.width, height: canvasDimensions.height)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                
                // Image representation (blue rectangle showing fitted image)
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: imageDimensions.width, height: imageDimensions.height)
                    .overlay(
                        Text("Image")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    )
            }
            
            // Info text
            VStack(spacing: 2) {
                Text("Canvas: \(String(format: "%.1f", canvasAspectRatio.width)):\(String(format: "%.1f", canvasAspectRatio.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if borderPercentage > 0 {
                    Text("Border: \(Int(borderPercentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Supporting UI Components

struct FramiqLogo: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer frame
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                
                // Inner frame
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                // Center dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
            }
            
            Text("Framiq")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct ModernDirectoryRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let directory: URL?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let directory = directory {
                        Text(directory.lastPathComponent)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    } else {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .background(.ultraThinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernCanvasSettings: View {
    @Binding var selectedAspectRatio: AspectRatio
    @Binding var customWidthRatio: String
    @Binding var customHeightRatio: String
    @Binding var borderPercentage: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Aspect Ratio
            VStack(alignment: .leading, spacing: 8) {
                Text("Aspect Ratio")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                    ForEach(AspectRatio.allCases) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedAspectRatio) { newValue in
                    if newValue != .custom {
                        let ratio = newValue.ratio
                        customWidthRatio = String(format: "%.0f", ratio.width)
                        customHeightRatio = String(format: "%.0f", ratio.height)
                    }
                }
            }
            
            // Custom Ratio (if selected)
            if selectedAspectRatio == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Ratio")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        TextField("4", text: $customWidthRatio)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: customWidthRatio) { newValue in
                                customWidthRatio = newValue.filter { $0.isNumber || $0 == "." }
                            }
                        
                        Text(":")
                            .foregroundColor(.secondary)
                        
                        TextField("5", text: $customHeightRatio)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: customHeightRatio) { newValue in
                                customHeightRatio = newValue.filter { $0.isNumber || $0 == "." }
                            }
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
            
            // Border Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Border Size")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(borderPercentage))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Slider(value: $borderPercentage, in: 0...50, step: 1)
                    .tint(.blue)
                
                Text("Add white space around the image for a gallery frame effect")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CompactProgressView: View {
    @ObservedObject var processor: ImageProcessor
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: processor.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\(processor.processedCount)/\(processor.totalCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !processor.currentFile.isEmpty {
                    Text(processor.currentFile)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct EnhancedAspectRatioPreview: View {
    let canvasAspectRatio: (width: Double, height: Double)
    let borderPercentage: Double
    
    @State private var selectedSampleImage: SampleImageType = .portrait23
    
    enum SampleImageType: String, CaseIterable {
        case landscape32 = "3:2 Landscape"
        case landscape169 = "16:9 Landscape" 
        case square = "1:1 Square"
        case portrait23 = "2:3 Portrait"
        case portrait45 = "4:5 Portrait"
        
        var ratio: Double {
            switch self {
            case .landscape32: return 3.0/2.0
            case .landscape169: return 16.0/9.0
            case .square: return 1.0
            case .portrait23: return 2.0/3.0
            case .portrait45: return 4.0/5.0
            }
        }
    }
    
    private var canvasDimensions: (width: CGFloat, height: CGFloat) {
        let maxDimension: CGFloat = 300  // Larger preview
        let aspectRatioValue = canvasAspectRatio.width / canvasAspectRatio.height
        
        if aspectRatioValue > 1 {
            return (maxDimension, maxDimension / aspectRatioValue)
        } else {
            return (maxDimension * aspectRatioValue, maxDimension)
        }
    }
    
    private var finalCanvasDimensions: (width: CGFloat, height: CGFloat) {
        let borderMultiplier = 1.0 + (borderPercentage / 100.0)
        return (
            canvasDimensions.width * borderMultiplier,
            canvasDimensions.height * borderMultiplier
        )
    }
    
    private var imageDimensions: (width: CGFloat, height: CGFloat) {
        let canvasRatio = canvasDimensions.width / canvasDimensions.height
        let sampleImageRatio = selectedSampleImage.ratio
        
        let imageWidth: CGFloat
        let imageHeight: CGFloat
        
        if sampleImageRatio > canvasRatio {
            imageWidth = canvasDimensions.width
            imageHeight = canvasDimensions.width / sampleImageRatio
        } else {
            imageHeight = canvasDimensions.height
            imageWidth = canvasDimensions.height * sampleImageRatio
        }
        
        return (imageWidth, imageHeight)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Sample Image Picker
            Picker("Sample Image", selection: $selectedSampleImage) {
                ForEach(SampleImageType.allCases, id: \.self) { imageType in
                    Text(imageType.rawValue).tag(imageType)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            // Preview
            ZStack {
                // Drop shadow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .frame(
                        width: finalCanvasDimensions.width + 8,
                        height: finalCanvasDimensions.height + 8
                    )
                    .blur(radius: 8)
                    .offset(y: 4)
                
                // Final canvas with border
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: finalCanvasDimensions.width, height: finalCanvasDimensions.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Canvas without border
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: canvasDimensions.width, height: canvasDimensions.height)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                // Image representation
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: imageDimensions.width, height: imageDimensions.height)
                    .overlay(
                        Text("Image")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            
            // Info
            VStack(spacing: 4) {
                Text("Canvas: \(String(format: "%.1f", canvasAspectRatio.width)):\(String(format: "%.1f", canvasAspectRatio.height))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if borderPercentage > 0 {
                    Text("Border: \(Int(borderPercentage))%")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
    }
}

struct AutomaticPreviewArea: View {
    let canvasAspectRatio: (width: Double, height: Double)
    let borderPercentage: Double
    let detectedAspectRatios: [DetectedAspectRatio]
    @Binding var selectedPreviewAspectRatio: DetectedAspectRatio?
    let refreshTrigger: UUID
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Detected Image Types")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(detectedAspectRatios) { aspectRatio in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPreviewAspectRatio = aspectRatio
                            }
                        }) {
                            VStack(spacing: 8) {
                                // Mini preview
                                PreviewCard(
                                    imageAspectRatio: aspectRatio,
                                    canvasAspectRatio: canvasAspectRatio,
                                    borderPercentage: borderPercentage,
                                    isSelected: selectedPreviewAspectRatio?.id == aspectRatio.id,
                                    refreshTrigger: refreshTrigger
                                )
                                
                                Text(aspectRatio.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedPreviewAspectRatio?.id == aspectRatio.id ? .blue : .primary)
                                    .multilineTextAlignment(.center)
                                    .animation(.easeInOut(duration: 0.15), value: selectedPreviewAspectRatio?.id == aspectRatio.id)
                                
                                Text("\(aspectRatio.count) image\(aspectRatio.count == 1 ? "" : "s")")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 120)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Main preview with selected or most common aspect ratio
            if let mainAspectRatio = selectedPreviewAspectRatio ?? detectedAspectRatios.first {
                VStack(spacing: 8) {
                    Text("Main Preview: \(mainAspectRatio.displayName)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    LargePreviewCard(
                        imageAspectRatio: mainAspectRatio,
                        canvasAspectRatio: canvasAspectRatio,
                        borderPercentage: borderPercentage,
                        refreshTrigger: refreshTrigger
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.3), value: mainAspectRatio.id)
            }
        }
    }
}

struct PreviewCard: View {
    let imageAspectRatio: DetectedAspectRatio
    let canvasAspectRatio: (width: Double, height: Double)
    let borderPercentage: Double
    let isSelected: Bool
    let refreshTrigger: UUID
    
    private var dimensions: (canvas: CGSize, finalCanvas: CGSize, image: CGSize) {
        let baseSize: CGFloat = 80
        let canvasRatio = canvasAspectRatio.width / canvasAspectRatio.height
        
        let canvasSize: CGSize
        if canvasRatio > 1 {
            canvasSize = CGSize(width: baseSize, height: baseSize / canvasRatio)
        } else {
            canvasSize = CGSize(width: baseSize * canvasRatio, height: baseSize)
        }
        
        let borderMultiplier = 1.0 + (borderPercentage / 100.0)
        let finalCanvasSize = CGSize(
            width: canvasSize.width * borderMultiplier,
            height: canvasSize.height * borderMultiplier
        )
        
        let imageRatio = imageAspectRatio.ratio
        let canvasAspectRatioValue = canvasSize.width / canvasSize.height
        
        let imageSize: CGSize
        if imageRatio > canvasAspectRatioValue {
            imageSize = CGSize(width: canvasSize.width, height: canvasSize.width / imageRatio)
        } else {
            imageSize = CGSize(width: canvasSize.height * imageRatio, height: canvasSize.height)
        }
        
        return (canvas: canvasSize, finalCanvas: finalCanvasSize, image: imageSize)
    }
    
    var body: some View {
        ZStack {
            // Final canvas with border
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: dimensions.finalCanvas.width, height: dimensions.finalCanvas.height)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            // Canvas area
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: dimensions.canvas.width, height: dimensions.canvas.height)
            
            // Image
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: dimensions.image.width, height: dimensions.image.height)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .padding(-4)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .animation(.easeInOut(duration: 0.15), value: dimensions.finalCanvas)
        .animation(.easeInOut(duration: 0.15), value: dimensions.canvas)
        .animation(.easeInOut(duration: 0.15), value: dimensions.image)
        .onChange(of: refreshTrigger) { _ in
            // Trigger view update when settings change
        }
    }
}

struct LargePreviewCard: View {
    let imageAspectRatio: DetectedAspectRatio
    let canvasAspectRatio: (width: Double, height: Double)
    let borderPercentage: Double
    let refreshTrigger: UUID
    
    private var dimensions: (canvas: CGSize, finalCanvas: CGSize, image: CGSize) {
        let baseSize: CGFloat = 200
        let canvasRatio = canvasAspectRatio.width / canvasAspectRatio.height
        
        let canvasSize: CGSize
        if canvasRatio > 1 {
            canvasSize = CGSize(width: baseSize, height: baseSize / canvasRatio)
        } else {
            canvasSize = CGSize(width: baseSize * canvasRatio, height: baseSize)
        }
        
        let borderMultiplier = 1.0 + (borderPercentage / 100.0)
        let finalCanvasSize = CGSize(
            width: canvasSize.width * borderMultiplier,
            height: canvasSize.height * borderMultiplier
        )
        
        let imageRatio = imageAspectRatio.ratio
        let canvasAspectRatioValue = canvasSize.width / canvasSize.height
        
        let imageSize: CGSize
        if imageRatio > canvasAspectRatioValue {
            imageSize = CGSize(width: canvasSize.width, height: canvasSize.width / imageRatio)
        } else {
            imageSize = CGSize(width: canvasSize.height * imageRatio, height: canvasSize.height)
        }
        
        return (canvas: canvasSize, finalCanvas: finalCanvasSize, image: imageSize)
    }
    
    var body: some View {
        ZStack {
            // Drop shadow
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .frame(
                    width: dimensions.finalCanvas.width + 8,
                    height: dimensions.finalCanvas.height + 8
                )
                .blur(radius: 8)
                .offset(y: 4)
            
            // Final canvas with border
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: dimensions.finalCanvas.width, height: dimensions.finalCanvas.height)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            // Canvas area
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: dimensions.canvas.width, height: dimensions.canvas.height)
            
            // Image
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: dimensions.image.width, height: dimensions.image.height)
                .overlay(
                    Text("Image")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .animation(.easeInOut(duration: 0.2), value: dimensions.finalCanvas)
        .animation(.easeInOut(duration: 0.2), value: dimensions.canvas)
        .animation(.easeInOut(duration: 0.2), value: dimensions.image)
        .onChange(of: refreshTrigger) { _ in
            // Trigger view update when settings change
        }
    }
}

struct DetailedProcessingStatus: View {
    @ObservedObject var processor: ImageProcessor
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: processor.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: processor.progress)
                
                Text("\(Int(processor.progress * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                Text("Processing Images")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(processor.processedCount) of \(processor.totalCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if !processor.currentFile.isEmpty {
                    Text(processor.currentFile)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ProcessingResults: View {
    @ObservedObject var processor: ImageProcessor
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Processing Complete!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("\(processor.processedImages.count) Processed")
                        .font(.system(size: 14, weight: .medium))
                }
                
                if !processor.skippedImages.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("\(processor.skippedImages.count) Skipped")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Ready to Process")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Select your input and output folders, choose your frame settings, and start processing.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
    }
}

// MARK: - Mode Selector
struct ModeSelector: View {
    @Binding var selectedMode: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Single Image Mode
            Button(action: {
                selectedMode = 0
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 14, weight: .medium))
                    Text("Single Image")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    selectedMode == 0 ? 
                        LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(selectedMode == 0 ? .white : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Batch Processing Mode
            Button(action: {
                selectedMode = 1
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 14, weight: .medium))
                    Text("Batch Processing")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    selectedMode == 1 ? 
                        LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(selectedMode == 1 ? .white : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
} 