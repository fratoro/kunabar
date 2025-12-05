# kunabar

A beautiful, lightweight macOS menu bar app for time tracking with [Hakuna](https://hakuna.ch).

![macOS 26.0+](https://img.shields.io/badge/macOS-26.0+-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)

![Screenshot](https://raw.githubusercontent.com/fratoro/kunabar/refs/heads/main/screenshot/screenshot-20251205-qLgzvZDG%402x.png)

## Features

- 🎯 **Menu Bar Only** - No dock icon, stays out of your way
- ⏱️ **Smart Timer Detection** - Automatically syncs with running timers
- 🔄 **Offline-First** - Local counting with minimal API calls
- 💤 **Sleep Aware** - Pauses timer when Mac sleeps
- 🎨 **Native macOS Design** - Liquid Glass aesthetic with vibrancy effects
- 🔔 **Daily Target Notifications** - Get notified when you reach your goal
- 📊 **Real-time Display** - Shows current time balance in menu bar

## Installation

### Building from Source

1. **Clone the repository**
   ```bash
   git clone 
   ```

2. **Open in Xcode**
   ```bash
   open kunabar.xcodeproj
   ```
   
   Or create a new Xcode project:
   - File > New > Project > macOS > App
   - Product Name: `kunabar`
   - Interface: SwiftUI
   - Language: Swift
   - Delete default files and add all source files from this directory

3. **Configure the project**
   - Set deployment target to macOS 26.0
   - Ensure `Info.plist` has `LSUIElement = true`
   - Disable App Sandbox (or enable "Outgoing Connections")

4. **Build and Run** (⌘R)

## Setup

### First Launch

1. The Settings window will open automatically
2. Click "Get your API key →" to open Hakuna settings
3. Copy your API token from https://app.hakuna.ch/my_settings
4. Enter your **Task ID** (required) and **Project ID** (optional)
5. Set your daily target hours (default: 8.4)
6. Click "Save & Close"

### Finding Your Task/Project IDs

```
curl -X "GET" "https://app.hakuna.ch/api/v1/timer" \
 -H "Accept-Version: v1" \
 -H "X-Auth-Token: your-token"
```
Project and Task ID can then be found in API response:
```
{"date":"2024-09-24","start_time":"07:59","duration":"4:04","duration_in_seconds":14640.0,"note":null,"user":{"id":10,"name":"Firstname Lastname","email":"user@domain.tld","status":"active","groups":["Group ABC"],"teams":["Team ABC"]},"task":{"id":2,"name":"Arbeit","archived":false,"default":true},"project":1}%
```

## Usage

### Menu Bar

- **Time Display**: Shows current daily worked time (e.g., `5:23`)
- **Red Background**: Appears when you've reached your daily target
- Click the time to open the menu

### Menu Options

- **Start Timer** / **Stop Timer**: Control your timer
- **Today**: Current worked time (e.g., `5 Std. 23 Min.`)
- **Target**: Your daily goal (e.g., `Target: 8 Std. 24 Min.`)
- **Difference**: Over/under target (green/red, e.g., `+45 Min.`)
- **Settings…**: Open settings window
- **Quit kunabar**: Exit the app

## API Usage

The app is designed to be **extremely thrifty** with API calls:

- ✅ **On launch**: Fetches today's balance + running timer
- ✅ **On wake**: Fetches today's balance + running timer
- ✅ **On stop**: Stops timer, then fetches balance
- ✅ **Background sync**: Maximum once per hour
- ✅ **While running**: Minimum API calls (pure local counting, just one API call per hour)

## Debug Logging

The app includes helpful console logging for debugging:

- `📥 GET /timer response: {...}` - Raw API responses
- `✅ Timer detected: ...` - Timer state changes
- `ℹ️ No timer running` - Timer status
- `❌ Failed to ...` - Error messages

View logs in Xcode console or Console.app (filter by "kunabar").

## Project Structure

```
kunabar/
├── AppDelegate.swift              # App lifecycle
├── main.swift                     # Entry point
├── Info.plist                     # App configuration
├── Controllers/
│   ├── StatusBarController.swift  # Menu bar UI & logic
│   └── SettingsWindowController.swift
│   └── AboutWindowController.swift
├── Services/
│   ├── HakunaAPI.swift           # API client
│   └── TimeTracker.swift         # Timer logic & state
├── Utils/
│   └── Extensions.swift          # Helper extensions
└── Views/
    └── SettingsView.swift        # Settings UI
    └── AboutView.swift           # About UI
```

## Requirements

- macOS 26.1 (Tahoe) or later
- Xcode 15.0 or later
- Swift 6.0 or later
- Active Hakuna account with API access

**Swift 6 Features:**
- Full concurrency support with actors and async/await
- Strict data race safety at compile time
- Modern Swift concurrency patterns throughout

## Troubleshooting

### Timer not detected on startup
- Check console logs for API responses
- Verify your API key is valid
- Ensure Task ID is correct

### "Failed to start timer: 422"
- A timer is already running - the app will auto-sync
- Check the Hakuna web interface

## License

This project is provided as-is for personal use.

## Credits

Built with ❤️ in Switzerland for the Hakuna community.
