import SwiftUI
import SwiftData
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipboardItem]

    @AppStorage("retentionPolicy") private var retentionPolicy: Int = 1
    @AppStorage("clearOnReboot") private var clearOnReboot: Bool = false
    @AppStorage("keepImages") private var keepImages: Bool = true
    
    @State private var showingClearConfirmation = false

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
        .frame(width: 450, height: 260)
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
