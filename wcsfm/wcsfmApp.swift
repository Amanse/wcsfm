import SwiftUI
import SwiftData
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleHistoryWindow = Self("toggleHistoryWindow", default: .init(.v, modifiers: [.command, .option]))
}

struct MenuBarContentView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings...") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Divider()
        
        Button("Quit wcsfm") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

@main
struct wcsfmApp: App {
    let container: ModelContainer
    let monitor: ClipboardMonitor

    init() {
        do {
            container = try ModelContainer(for: ClipboardItem.self)
            monitor = ClipboardMonitor(modelContext: container.mainContext)
            
            HistoryWindowManager.shared.setup(modelContext: container.mainContext)
            
            NSApplication.shared.setActivationPolicy(.accessory)
            
            // Check Accessibility permissions on startup
            if !AXIsProcessTrusted() {
                print("Accessibility permissions missing. Auto-typing will not work.")
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                AXIsProcessTrustedWithOptions(options as CFDictionary)
            }
        } catch {
            fatalError("Failed to create ModelContainer for ClipboardItem.")
        }
    }

    var body: some Scene {
        MenuBarExtra("wcsfm", systemImage: "clipboard") {
            MenuBarContentView()
        }
        
        Settings {
            SettingsView()
        }
        .modelContainer(container)
    }
}
