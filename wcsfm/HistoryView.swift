import SwiftUI
import SwiftData
import AppKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var items: [ClipboardItem]
    
    var onDismiss: () -> Void
    
    @State private var searchText: String = ""
    @State private var selection: UUID?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var lastSelectionIndex: Int = 0

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                if item.type == "text", let content = item.content {
                    return content.localizedCaseInsensitiveContains(searchText)
                }
                return false
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                SearchField(
                    text: $searchText,
                    onUpArrow: { moveSelection(direction: -1) },
                    onDownArrow: { moveSelection(direction: 1) },
                    onReturn: {
                        if let selectedId = selection, let item = filteredItems.first(where: { $0.id == selectedId }) {
                            confirmSelection(item: item)
                        } else if let firstItem = filteredItems.first {
                            confirmSelection(item: firstItem)
                        }
                    },
                    onEscape: { onDismiss() }
                )
            }
            .padding()
            
            Divider()
            
            if filteredItems.isEmpty {
                Spacer()
                Text(items.isEmpty ? "No items in history" : "No matches found")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List(selection: $selection) {
                        ForEach(filteredItems) { item in
                            HistoryItemRow(item: item)
                                .tag(item.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    confirmSelection(item: item)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: selection) { _ in
                        if let id = selection,
                           let newIndex = filteredItems.firstIndex(where: { $0.id == id }) {
                            let anchor: UnitPoint = newIndex >= lastSelectionIndex ? .bottom : .top
                            proxy.scrollTo(id, anchor: anchor)
                            lastSelectionIndex = newIndex
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .background(WindowEffectView())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            selection = filteredItems.first?.id
        }
        .onChange(of: searchText) { _ in
            selection = filteredItems.first?.id
        }
    }
    
    private func moveSelection(direction: Int) {
        guard !filteredItems.isEmpty else { return }
        let currentIndex = filteredItems.firstIndex(where: { $0.id == selection }) ?? -1
        var newIndex = currentIndex + direction
        if newIndex < 0 { newIndex = 0 }
        if newIndex >= filteredItems.count { newIndex = filteredItems.count - 1 }
        selection = filteredItems[newIndex].id
    }
    
    private func confirmSelection(item: ClipboardItem) {
        copyToPasteboard(item: item)
        HistoryWindowManager.shared.dismissAndPaste()
    }
    
    private func copyToPasteboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if item.type == "text", let content = item.content {
            pasteboard.setString(content, forType: .string)
        } else if item.type == "image", let imageData = item.imageData, let image = NSImage(data: imageData) {
            pasteboard.writeObjects([image])
        }
    }
}

// MARK: - Search Field

private class AutoFocusTextField: NSTextField {
    private var hasAutoFocused = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && !hasAutoFocused {
            hasAutoFocused = true
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(self)
            }
        }
    }
}

struct SearchField: NSViewRepresentable {
    @Binding var text: String
    var onUpArrow: () -> Void
    var onDownArrow: () -> Void
    var onReturn: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = AutoFocusTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.placeholderString = "Search..."
        field.focusRingType = .none
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.cell?.sendsActionOnEndEditing = false
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SearchField

        init(_ parent: SearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                parent.onUpArrow()
                return true
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                parent.onDownArrow()
                return true
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onReturn()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }
            return false
        }
    }
}

struct HistoryItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack {
            if item.type == "text", let content = item.content {
                VStack(alignment: .leading, spacing: 4) {
                    Text(content)
                        .lineLimit(3)
                        .font(.body)
                    Text(item.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if item.type == "image", let imageData = item.imageData, let image = NSImage(data: imageData) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .cornerRadius(8)
                    Text("Image • " + item.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
