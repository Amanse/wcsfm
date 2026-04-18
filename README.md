# wcsfm

**Windows Clipboard Subsystem For MacOS** — A lightweight clipboard manager for macOS.

> A playful nod to WSL (Windows Subsystem for Linux), but for clipboard management on macOS.

## Features

- **Global Hotkey Access** — Press `⌘⌥V` to instantly access your clipboard history
- **Search History** — Quickly find past clipboard items with live search
- **Image Support** — Store and manage both text and images
- **Configurable Retention** — Keep history for 1 day, 1 week, 1 month, or forever
- **Native macOS UI** — Seamless integration with macOS design language
  - Vibrancy/glass morphism effects
  - Rounded floating panel
  - Auto-focus on activation
  - Arrow key navigation
- **Menu Bar Integration** — Lightweight menu bar app that doesn't clutter your dock

## Installation

### Requirements
- macOS 12+
- Swift 5.9+
- Xcode 15+

### Build & Run

```bash
git clone <repository-url>
cd wcsfm
xcodebuild -scheme wcsfm -configuration Release
```

Then run the built app from `/Build/Products/Release/wcsfm.app`

Or use Xcode:
```bash
open wcsfm.xcodeproj
# Press Cmd+R to build and run
```

## Usage

1. **Launch the app** — It runs in the menu bar
2. **Open history** — Press `⌘⌥V` (customizable in Settings)
3. **Navigate** — Use arrow keys (↑/↓) to browse, type to search
4. **Select** — Press Enter to copy and auto-paste to the active app, or click an item
5. **Dismiss** — Press Escape or click outside the window

## Settings

Access settings from the menu bar app:
- **Global Hotkey** — Customize the keyboard shortcut
- **Retention Policy** — Choose how long to keep history
- **Clear on Reboot** — Optionally wipe history on system restart
- **Save Images** — Enable/disable image history

## Privacy

- All clipboard data is stored locally in SwiftData
- No network requests or data collection
- History can be cleared anytime from Settings

## Technical Details

- Built with SwiftUI and SwiftData
- Uses `NSPanel` for floating window behavior
- Custom search field with keyboard event interception
- CGEventTap for auto-paste functionality
- Requires Accessibility permissions for auto-paste

## Accessibility Permissions

On first launch, the app will request Accessibility permissions. This is required for the auto-paste feature (automatically pasting to the previously active application when you select an item).

To manually grant permissions:
1. Open **System Preferences** → **Security & Privacy** → **Accessibility**
2. Add `wcsfm` to the allowed apps list

## License

[Choose your license here]

---

Made with ❤️ for clipboard enthusiasts
