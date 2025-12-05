import Cocoa

@MainActor
class StatusBarController: NSObject, TimeTrackerDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var settingsWindowController: SettingsWindowController?
    private var aboutWindowController: AboutWindowController?
    
    // Menu items
    private var timerMenuItem: NSMenuItem!
    private var todayTimeMenuItem: NSMenuItem!
    private var targetTimeMenuItem: NSMenuItem!
    private var differenceMenuItem: NSMenuItem!
    
    override init() {
        super.init()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "--:--"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        }
        
        setupMenu()
        TimeTracker.shared.delegate = self
        
        // Initial update
        updateStatusItem()
        
        // Start initial fetch after delegate is set
        TimeTracker.shared.startInitialFetch()
    }
    
    private func setupMenu() {
        menu = NSMenu()
        menu.delegate = self

        // Timer Action
        timerMenuItem = NSMenuItem(title: "Start Timer", action: #selector(toggleTimer), keyEquivalent: "s")
        timerMenuItem.target = self
        menu.addItem(timerMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Info Items (Disabled or Custom View)
        todayTimeMenuItem = NSMenuItem(title: "Today: --", action: nil, keyEquivalent: "")
        todayTimeMenuItem.isEnabled = false
        menu.addItem(todayTimeMenuItem)
        
        targetTimeMenuItem = NSMenuItem(title: "Target: --", action: nil, keyEquivalent: "")
        targetTimeMenuItem.isEnabled = false
        menu.addItem(targetTimeMenuItem)
        
        differenceMenuItem = NSMenuItem(title: "Diff: --", action: nil, keyEquivalent: "")
        differenceMenuItem.isEnabled = false
        menu.addItem(differenceMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings & Quit
        let settingsItem = NSMenuItem(title: "Setting", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit kunabar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    nonisolated func timeTrackerDidUpdate(_ tracker: TimeTracker) {
        Task { @MainActor in
            self.updateStatusItem()
            self.updateMenu()
        }
    }
    
    nonisolated func timeTrackerDidReachTarget(_ tracker: TimeTracker) {
        Task { @MainActor in
            self.updateStatusItem()
        }
    }
    
    private func updateStatusItem() {
        let tracker = TimeTracker.shared
        let timeString = tracker.currentSeconds.toTimeString()
        
        // Choose icon based on timer state
        let iconName = tracker.isRunning ? "pause.circle.fill" : "play.circle.fill"
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
        
        if let button = statusItem.button {
            // Set the icon
            button.image = icon
            button.imagePosition = .imageLeading
            
            let baselineOffset: CGFloat = -0.5
            
            // "When IST >= daily target -> red background with white text"
            if tracker.currentSeconds >= tracker.dailyTargetSeconds {

                let attributes: [NSAttributedString.Key: Any] = [
                    .backgroundColor: NSColor.systemRed,
                    .foregroundColor: NSColor.white,
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
                    .baselineOffset: baselineOffset
                ]
                button.attributedTitle = NSAttributedString(string: " \(timeString) ", attributes: attributes)
            } else {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
                    .baselineOffset: baselineOffset
                ]
                button.attributedTitle = NSAttributedString(string: timeString, attributes: attributes)
            }
        }
    }
    
    private func updateMenu() {
        let tracker = TimeTracker.shared
        
        // Timer Item
        if tracker.isRunning {
            timerMenuItem.title = "Stop Timer"
        } else {
            timerMenuItem.title = "Start Timer"
        }
        
        // Info Items
        todayTimeMenuItem.title = "Today: \(tracker.currentSeconds.toVerboseTimeString())"
        targetTimeMenuItem.title = "Target: \(tracker.dailyTargetSeconds.toVerboseTimeString())"
        
        let diff = tracker.currentSeconds - tracker.dailyTargetSeconds
        let diffString = diff >= 0 ? "+\(diff.toVerboseTimeString())" : "-\(abs(diff).toVerboseTimeString())"
        
        // Color for difference
        let color: NSColor = diff >= 0 ? .systemGreen : .systemRed
        let diffAttr = NSAttributedString(string: diffString, attributes: [.foregroundColor: color])
        differenceMenuItem.attributedTitle = diffAttr
    }
    
    @objc private func toggleTimer() {
        if TimeTracker.shared.isRunning {
            TimeTracker.shared.stopTimer()
        } else {
            TimeTracker.shared.startTimer()
        }
    }
    
    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
