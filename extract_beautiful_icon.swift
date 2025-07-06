#!/usr/bin/env swift

import SwiftUI
import AppKit
import Foundation

// Extracted from your app's beautiful FramiqLogo
struct BeautifulIcon: View {
    var body: some View {
        ZStack {
            // Outer frame with beautiful gradient stroke
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 6  // Slightly thicker for high-res icon
                )
                .frame(width: 120, height: 120)
            
            // Inner frame with subtle gradient fill
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
            
            // Center white dot
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
        }
        .frame(width: 160, height: 160)
        .background(Color.clear)
    }
}

@available(macOS 13.0, *)
@MainActor
func generateBeautifulIcon() async {
    let icon = BeautifulIcon()
    
    // Create ultra-high-resolution renderer for crisp results
    let renderer = ImageRenderer(content: icon)
    renderer.scale = 10.0  // Ultra high resolution (1600x1600 output)
    
    // Render to NSImage
    if let nsImage = renderer.nsImage {
        // Convert to PNG data
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert image to PNG")
            return
        }
        
        // Save to file
        let url = URL(fileURLWithPath: "BeautifulIcon.png")
        do {
            try pngData.write(to: url)
            print("✅ Generated beautiful icon: \(url.path)")
            print("📏 Image size: \(nsImage.size)")
            print("🎨 Features: Blue→Purple→Pink gradient stroke, subtle inner fill, white center dot")
            print("💫 Ready to use as app icon or anywhere you need a beautiful logo!")
        } catch {
            print("❌ Failed to save icon: \(error)")
        }
    } else {
        print("❌ Failed to render icon")
    }
}

// Alternative AppKit version for compatibility
func generateBeautifulIconAppKit() {
    let size = CGSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Clear background
    NSColor.clear.set()
    NSRect(origin: .zero, size: size).fill()
    
    // Create beautiful gradient colors (matching your app exactly)
    let blueColor = NSColor.systemBlue
    let purpleColor = NSColor.systemPurple  
    let pinkColor = NSColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0)
    
    // Outer frame with beautiful gradient stroke
    let outerFrame = NSRect(x: 192, y: 192, width: 640, height: 640)
    let outerPath = NSBezierPath(roundedRect: outerFrame, xRadius: 85, yRadius: 85)
    outerPath.lineWidth = 32
    
    // Create the beautiful gradient for stroke (blue→purple→pink)
    let gradient = NSGradient(colors: [blueColor, purpleColor, pinkColor])!
    
    // Save graphics state and draw gradient stroke
    NSGraphicsContext.current!.saveGraphicsState()
    outerPath.addClip()
    gradient.draw(from: CGPoint(x: 192, y: 832), to: CGPoint(x: 832, y: 192), options: [])
    NSGraphicsContext.current!.restoreGraphicsState()
    
    // Stroke the path
    outerPath.stroke()
    
    // Inner frame with subtle gradient fill
    let innerFrame = NSRect(x: 384, y: 384, width: 256, height: 256)
    let innerPath = NSBezierPath(roundedRect: innerFrame, xRadius: 43, yRadius: 43)
    
    // Subtle inner gradient (matching app's opacity)
    let innerGradient = NSGradient(colors: [
        blueColor.withAlphaComponent(0.3),
        purpleColor.withAlphaComponent(0.3)
    ])!
    innerGradient.draw(in: innerPath, angle: 135)
    
    // Center white dot
    let dotFrame = NSRect(x: 448, y: 448, width: 128, height: 128)
    let dotPath = NSBezierPath(ovalIn: dotFrame)
    NSColor.white.set()
    dotPath.fill()
    
    image.unlockFocus()
    
    // Save to PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("❌ Failed to convert image to PNG")
        return
    }
    
    let url = URL(fileURLWithPath: "BeautifulIcon_AppKit.png")
    do {
        try pngData.write(to: url)
        print("✅ Generated beautiful icon (AppKit): \(url.path)")
        print("📏 Image size: \(image.size)")
        print("🎨 Features: Blue→Purple→Pink gradient stroke, subtle inner fill, white center dot")
        print("💫 Perfect for use as app icon or branding material!")
    } catch {
        print("❌ Failed to save icon: \(error)")
    }
}

// Main execution
print("🎨 Extracting your beautiful icon from the app...")
print("════════════════════════════════════════════════")

// Try SwiftUI version first (requires macOS 13.0+)
if #available(macOS 13.0, *) {
    print("📱 Using SwiftUI ImageRenderer for ultra-crisp results...")
    Task { @MainActor in
        await generateBeautifulIcon()
        
        // Also generate AppKit version for comparison
        print("\n🎨 Also generating AppKit version...")
        generateBeautifulIconAppKit()
        
        print("\n✨ Both versions generated successfully!")
        print("📁 Files created:")
        print("   • BeautifulIcon.png (SwiftUI version)")
        print("   • BeautifulIcon_AppKit.png (AppKit version)")
        
        exit(0)
    }
    RunLoop.main.run()
} else {
    print("🎨 Using AppKit for compatibility...")
    generateBeautifulIconAppKit()
    print("\n✨ Icon generated successfully!")
    print("📁 File created: BeautifulIcon_AppKit.png")
} 