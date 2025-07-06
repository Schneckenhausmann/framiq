import Foundation
import AppKit
import CoreImage
import UniformTypeIdentifiers

struct DetectedAspectRatio: Identifiable, Hashable {
    let id = UUID()
    let width: Double
    let height: Double
    let count: Int
    let sampleFileName: String
    
    var ratio: Double {
        width / height
    }
    
    var displayName: String {
        if abs(ratio - 1.0) < 0.05 {
            return "Square (1:1)"
        } else if abs(ratio - 3.0/2.0) < 0.1 {
            return "Landscape (3:2)"
        } else if abs(ratio - 4.0/3.0) < 0.1 {
            return "Landscape (4:3)"
        } else if abs(ratio - 16.0/9.0) < 0.1 {
            return "Landscape (16:9)"
        } else if abs(ratio - 2.0/3.0) < 0.1 {
            return "Portrait (2:3)"
        } else if abs(ratio - 3.0/4.0) < 0.1 {
            return "Portrait (3:4)"
        } else if abs(ratio - 4.0/5.0) < 0.1 {
            return "Portrait (4:5)"
        } else if abs(ratio - 9.0/16.0) < 0.1 {
            return "Portrait (9:16)"
        } else if ratio > 1.0 {
            return "Landscape (\(String(format: "%.1f", ratio)):1)"
        } else {
            return "Portrait (\(String(format: "%.1f", 1.0/ratio)):1)"
        }
    }
}

class ImageProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentFile = ""
    @Published var processedCount = 0
    @Published var totalCount = 0
    @Published var processedImages: [String] = []
    @Published var skippedImages: [String] = []
    @Published var detectedAspectRatios: [DetectedAspectRatio] = []
    
    private var isCancelled = false
    
    // Supported image file extensions
    private let supportedExtensions = Set(["jpg", "jpeg", "png", "tiff", "tif", "bmp", "gif", "heic", "heif"])
    
    func processImages(inputDirectory: URL, outputDirectory: URL, aspectRatio: (width: Double, height: Double), borderPercentage: Double) {
        guard !isProcessing else { return }
        
        Task { @MainActor in
            isProcessing = true
            progress = 0.0
            processedCount = 0
            processedImages = []
            skippedImages = []
            isCancelled = false
            
            await performImageProcessing(inputDirectory: inputDirectory, outputDirectory: outputDirectory, aspectRatio: aspectRatio, borderPercentage: borderPercentage)
            
            isProcessing = false
            currentFile = ""
        }
    }
    
    func processSingleImage(inputURL: URL, aspectRatio: (width: Double, height: Double), borderPercentage: Double) {
        guard !isProcessing else { return }
        
        Task { @MainActor in
            isProcessing = true
            progress = 0.0
            processedCount = 0
            processedImages = []
            skippedImages = []
            isCancelled = false
            totalCount = 1
            
            currentFile = inputURL.lastPathComponent
            
            // Create output URL with _framiq suffix
            let fileExtension = inputURL.pathExtension
            let fileName = inputURL.deletingPathExtension().lastPathComponent
            let outputFileName = "\(fileName)_framiq.\(fileExtension)"
            let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(outputFileName)
            
            do {
                if try await processImage(inputURL: inputURL, outputDirectory: inputURL.deletingLastPathComponent(), aspectRatio: aspectRatio, borderPercentage: borderPercentage, customOutputName: outputFileName) {
                    processedImages.append(inputURL.lastPathComponent)
                } else {
                    skippedImages.append(inputURL.lastPathComponent)
                }
            } catch {
                print("Error processing single image: \(error)")
                skippedImages.append(inputURL.lastPathComponent)
            }
            
            processedCount = 1
            progress = 1.0
            
            isProcessing = false
            currentFile = ""
        }
    }
    
    func cancelProcessing() {
        isCancelled = true
    }
    
    func resetProcessingState() {
        isProcessing = false
        progress = 0.0
        currentFile = ""
        processedCount = 0
        totalCount = 0
        processedImages = []
        skippedImages = []
        detectedAspectRatios = []
        isCancelled = false
    }
    
    func clearActiveProcessing() {
        // Only clear active processing state, preserve completed results
        isProcessing = false
        progress = 0.0
        currentFile = ""
        isCancelled = false
        // Don't clear: processedImages, skippedImages, processedCount, totalCount
    }
    
    func detectAspectRatios(inputDirectory: URL) {
        Task { @MainActor in
            detectedAspectRatios = []
            
            await performAspectRatioDetection(inputDirectory: inputDirectory)
        }
    }
    
    @MainActor
    private func performAspectRatioDetection(inputDirectory: URL) async {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: inputDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            
            let imageFiles = contents.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return supportedExtensions.contains(pathExtension)
            }
            
            var aspectRatioMap: [String: (ratio: (width: Double, height: Double), count: Int, sampleFile: String)] = [:]
            
            for imageFile in imageFiles {
                guard let image = NSImage(contentsOf: imageFile) else { continue }
                
                let imageSize = image.size
                let width = Double(imageSize.width)
                let height = Double(imageSize.height)
                let ratio = width / height
                
                // Round to common aspect ratios to group similar ones
                let roundedRatio = roundToCommonAspectRatio(ratio: ratio)
                let key = "\(roundedRatio.width):\(roundedRatio.height)"
                
                if var existing = aspectRatioMap[key] {
                    existing.count += 1
                    aspectRatioMap[key] = existing
                } else {
                    aspectRatioMap[key] = (ratio: roundedRatio, count: 1, sampleFile: imageFile.lastPathComponent)
                }
            }
            
            // Convert to DetectedAspectRatio objects
            detectedAspectRatios = aspectRatioMap.map { _, value in
                DetectedAspectRatio(
                    width: value.ratio.width,
                    height: value.ratio.height,
                    count: value.count,
                    sampleFileName: value.sampleFile
                )
            }.sorted { $0.count > $1.count } // Sort by count descending
            
        } catch {
            print("Error detecting aspect ratios: \(error)")
        }
    }
    
    private func roundToCommonAspectRatio(ratio: Double) -> (width: Double, height: Double) {
        let commonRatios: [(width: Double, height: Double)] = [
            (1.0, 1.0),    // Square
            (3.0, 2.0),    // 3:2 landscape
            (4.0, 3.0),    // 4:3 landscape
            (16.0, 9.0),   // 16:9 landscape
            (2.0, 3.0),    // 2:3 portrait
            (3.0, 4.0),    // 3:4 portrait
            (4.0, 5.0),    // 4:5 portrait
            (9.0, 16.0),   // 9:16 portrait
        ]
        
        var bestMatch = (width: 2.0, height: 3.0) // Default to 2:3
        var smallestDifference = Double.greatestFiniteMagnitude
        
        for commonRatio in commonRatios {
            let commonRatioValue = commonRatio.width / commonRatio.height
            let difference = abs(ratio - commonRatioValue)
            
            if difference < smallestDifference {
                smallestDifference = difference
                bestMatch = commonRatio
            }
        }
        
        // If no common ratio is close enough, use the actual ratio
        if smallestDifference > 0.1 {
            // Convert to simple ratio
            let gcd = greatestCommonDivisor(Int(ratio * 100), 100)
            let simplifiedWidth = (ratio * 100) / Double(gcd)
            let simplifiedHeight = 100.0 / Double(gcd)
            return (simplifiedWidth, simplifiedHeight)
        }
        
        return bestMatch
    }
    
    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        return b == 0 ? a : greatestCommonDivisor(b, a % b)
    }
    
    @MainActor
    private func performImageProcessing(inputDirectory: URL, outputDirectory: URL, aspectRatio: (width: Double, height: Double), borderPercentage: Double) async {
        do {
            // Get all image files from input directory
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: inputDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            
            let imageFiles = contents.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return supportedExtensions.contains(pathExtension)
            }
            
            totalCount = imageFiles.count
            
            guard totalCount > 0 else {
                print("No supported image files found in the input directory")
                return
            }
            
            // Create output directory if it doesn't exist
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            
            for (index, imageFile) in imageFiles.enumerated() {
                if isCancelled { break }
                
                currentFile = imageFile.lastPathComponent
                
                do {
                    if try await processImage(inputURL: imageFile, outputDirectory: outputDirectory, aspectRatio: aspectRatio, borderPercentage: borderPercentage, customOutputName: nil) {
                        processedImages.append(imageFile.lastPathComponent)
                    } else {
                        skippedImages.append(imageFile.lastPathComponent)
                    }
                } catch {
                    print("Error processing \(imageFile.lastPathComponent): \(error)")
                    skippedImages.append(imageFile.lastPathComponent)
                }
                
                processedCount = index + 1
                progress = Double(processedCount) / Double(totalCount)
            }
            
            print("Processing complete. Processed: \(processedImages.count), Skipped: \(skippedImages.count)")
            
        } catch {
            print("Error reading input directory: \(error)")
        }
    }
    
    private func processImage(inputURL: URL, outputDirectory: URL, aspectRatio: (width: Double, height: Double), borderPercentage: Double, customOutputName: String?) async throws -> Bool {
        // Load the image
        guard let image = NSImage(contentsOf: inputURL) else {
            print("Could not load image: \(inputURL.lastPathComponent)")
            return false
        }
        
        let imageSize = image.size
        
        // Calculate canvas dimensions based on longest side
        let longestSide = max(imageSize.width, imageSize.height)
        let canvasWidth: CGFloat
        let canvasHeight: CGFloat
        
        let aspectRatioValue = aspectRatio.width / aspectRatio.height
        
        if aspectRatioValue > 1 {
            // Landscape canvas
            canvasWidth = longestSide
            canvasHeight = longestSide / aspectRatioValue
        } else {
            // Portrait or square canvas
            canvasHeight = longestSide
            canvasWidth = longestSide * aspectRatioValue
        }
        
        // Add border (passepartout effect)
        let borderMultiplier = 1.0 + (borderPercentage / 100.0)
        let finalCanvasWidth = canvasWidth * borderMultiplier
        let finalCanvasHeight = canvasHeight * borderMultiplier
        
        // Calculate how to fit the image in the canvas (without border)
        let imageAspectRatio = imageSize.width / imageSize.height
        let canvasAspectRatio = canvasWidth / canvasHeight
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if imageAspectRatio > canvasAspectRatio {
            // Image is wider relative to canvas, fit to width
            newWidth = canvasWidth
            newHeight = canvasWidth / imageAspectRatio
        } else {
            // Image is taller relative to canvas, fit to height
            newHeight = canvasHeight
            newWidth = canvasHeight * imageAspectRatio
        }
        
        // Create the processed image
        let processedImage = createProcessedImage(
            originalImage: image,
            newSize: CGSize(width: newWidth, height: newHeight),
            canvasSize: CGSize(width: finalCanvasWidth, height: finalCanvasHeight)
        )
        
        guard let processedImage = processedImage else {
            print("Failed to process image: \(inputURL.lastPathComponent)")
            return false
        }
        
        // Save the processed image
        let outputFileName = customOutputName ?? inputURL.lastPathComponent
        let outputURL = outputDirectory.appendingPathComponent(outputFileName)
        try saveImage(processedImage, to: outputURL)
        
        print("Processed: \(inputURL.lastPathComponent) -> \(Int(finalCanvasWidth))x\(Int(finalCanvasHeight))")
        return true
    }
    
    private func createProcessedImage(originalImage: NSImage, newSize: CGSize, canvasSize: CGSize) -> NSImage? {
        // Create a new image representation with the target canvas size
        let targetImage = NSImage(size: canvasSize)
        
        targetImage.lockFocus()
        
        // Fill with white background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: canvasSize).fill()
        
        // Calculate position to center the resized image
        let x = (canvasSize.width - newSize.width) / 2
        let y = (canvasSize.height - newSize.height) / 2
        let destinationRect = NSRect(x: x, y: y, width: newSize.width, height: newSize.height)
        
        // Draw the resized image centered on the canvas
        originalImage.draw(in: destinationRect, from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
        
        targetImage.unlockFocus()
        
        return targetImage
    }
    
    private func saveImage(_ image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            throw NSError(domain: "ImageProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap representation"])
        }
        
        // Determine the file format based on the file extension
        let pathExtension = url.pathExtension.lowercased()
        let fileType: NSBitmapImageRep.FileType
        let properties: [NSBitmapImageRep.PropertyKey: Any]
        
        switch pathExtension {
        case "png":
            fileType = .png
            properties = [:]
        case "jpg", "jpeg":
            fileType = .jpeg
            properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 0.9]
        case "tiff", "tif":
            fileType = .tiff
            properties = [:]
        case "bmp":
            fileType = .bmp
            properties = [:]
        default:
            // Default to JPEG for unknown extensions
            fileType = .jpeg
            properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 0.9]
        }
        
        guard let imageData = bitmapRep.representation(using: fileType, properties: properties) else {
            throw NSError(domain: "ImageProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create image data"])
        }
        
        try imageData.write(to: url)
    }
} 