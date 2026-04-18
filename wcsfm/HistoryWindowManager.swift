import SwiftUI
import SwiftData
import KeyboardShortcuts
import AppKit

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

@MainActor
class HistoryWindowManager: NSObject, NSWindowDelegate {
    static let shared = HistoryWindowManager()
    
    private var panel: NSPanel?
    var modelContext: ModelContext?
    private var previousApp: NSRunningApplication?

    override private init() {
        super.init()
        setupHotkey()
    }
    
    private func setupHotkey() {
        KeyboardShortcuts.onKeyDown(for: .toggleHistoryWindow) { [weak self] in
            self?.togglePanel()
        }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func togglePanel() {
        if panel?.isVisible == true {
            dismissAndReturn()
        } else {
            showPanel()
        }
    }
    
    func showPanel() {
        previousApp = NSWorkspace.shared.frontmostApplication

        if panel == nil {
            guard let context = modelContext else { return }
            
            let view = HistoryView(onDismiss: { [weak self] in
                self?.dismissAndReturn()
            }).modelContext(context)
            
            let hostingController = NSHostingController(rootView: view)
            
            let newPanel = FloatingPanel(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            
            newPanel.isFloatingPanel = true
            newPanel.isMovableByWindowBackground = true
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.backgroundColor = .clear
            newPanel.isOpaque = false
            newPanel.hasShadow = true
            newPanel.contentViewController = hostingController
            newPanel.delegate = self
            newPanel.isReleasedWhenClosed = false

            if let contentView = newPanel.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = 12
                contentView.layer?.masksToBounds = true
            }

            newPanel.center()
            
            self.panel = newPanel
        }
        
        NSApp.activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(nil)
    }
    
    func hidePanel() {
        panel?.orderOut(nil)
        panel = nil
    }

    func dismissAndReturn() {
        hidePanel()
        activatePreviousApp()
    }

    func dismissAndPaste() {
        hidePanel()
        activatePreviousApp()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let source = CGEventSource(stateID: .hidSystemState)
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown?.flags = .maskCommand
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

            cmdDown?.post(tap: .cgSessionEventTap)
            vDown?.post(tap: .cgSessionEventTap)
            vUp?.post(tap: .cgSessionEventTap)
            cmdUp?.post(tap: .cgSessionEventTap)
        }
    }

    private func activatePreviousApp() {
        if let prevApp = previousApp {
            prevApp.activate()
            previousApp = nil
        }
    }
    
    // NSWindowDelegate
    func windowDidResignKey(_ notification: Notification) {
        hidePanel()
    }
}
