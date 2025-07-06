import SwiftUI

@main
struct FramiqApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
                .background(Color.clear)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Framiq") {
                    showAbout()
                }
            }
            
            CommandGroup(after: .newItem) {
                Button("Open Image...") {
                    // This could be enhanced to trigger file picker
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
            }
            
            CommandGroup(after: .help) {
                Button("Framiq Help") {
                    if let url = URL(string: "https://github.com/your-repo/framiq") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("/", modifiers: .command)
            }
        }
    }
    
    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Framiq"
        alert.informativeText = "Professional Image Framing Application\nVersion 1.1\n\nBuilt with ❤️ using SwiftUI\n© 2024 All rights reserved."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
} 