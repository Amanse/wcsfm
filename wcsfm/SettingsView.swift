import SwiftUI
import SwiftData
import KeyboardShortcuts
import ApplicationServices

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipboardItem]

    @AppStorage("retentionPolicy") private var retentionPolicy: Int = 1
    @AppStorage("clearOnReboot") private var clearOnReboot: Bool = false
    @AppStorage("keepImages") private var keepImages: Bool = true
    
    @State private var showingClearConfirmation = false
    @State private var accessibilityGranted: Bool = AXIsProcessTrusted()

    var body: some View {
        TabView {
            Form {
                Section {
                    HStack {
                        Text("Global Hotkey:")
                        Spacer()
                        KeyboardShortcuts.Recorder(for: .toggleHistoryWindow)
                    }
                }

                Section {
                    HStack(spacing: 10) {
                        Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(accessibilityGranted ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Type Permission")
                                .font(.body)
                            Text(accessibilityGranted
                                 ? "Accessibility access granted."
                                 : "Required to auto-type selected text.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !accessibilityGranted {
                            Button("Grant Access") {
                                requestAccessibility()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                Section {
                    Picker("Keep History For:", selection: $retentionPolicy) {
                        Text("1 Day").tag(1)
                        Text("1 Week").tag(7)
                        Text("1 Month").tag(30)
                        Text("Forever").tag(0)
                    }
                    
                    Toggle("Clear History on Reboot", isOn: $clearOnReboot)
                }

                Section {
                    Button("Clear History Now") {
                        showingClearConfirmation = true
                    }
                    .foregroundColor(.red)
                    .confirmationDialog("Are you sure?", isPresented: $showingClearConfirmation) {
                        Button("Clear Now", role: .destructive) {
                            clearHistory()
                        }
                    } message: {
                        Text("This will permanently delete all clipboard history.")
                    }
                }
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            .onAppear {
                accessibilityGranted = AXIsProcessTrusted()
            }
            
            Form {
                Section {
                    Toggle("Save images and videos in history", isOn: $keepImages)
                }
            }
            .padding()
            .tabItem {
                Label("Advanced", systemImage: "slider.horizontal.3")
            }
        }
        .frame(width: 450, height: 310)
    }

    private func requestAccessibility() {
        // Try the system prompt first
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // Also open System Settings directly to Accessibility (works on macOS 13+)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        // Poll for status updates after user returns
        for delay in [1.0, 3.0, 6.0, 10.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                accessibilityGranted = AXIsProcessTrusted()
            }
        }
    }
    
    private func clearHistory() {
        do {
            try modelContext.delete(model: ClipboardItem.self)
            try modelContext.save()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
}
