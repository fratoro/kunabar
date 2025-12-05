import Cocoa

@MainActor
extension NSVisualEffectView {
    func applyLiquidGlass() {
        self.material = .popover
        self.blendingMode = .behindWindow
        self.state = .active
        self.wantsLayer = true
        self.layer?.cornerRadius = 12
        self.layer?.masksToBounds = true
    }
}

extension Date {
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: self)
    }
}

extension Int {
    var hoursAndMinutes: (hours: Int, minutes: Int) {
        return (self / 3600, (self % 3600) / 60)
    }
    
    func toTimeString() -> String {
        let (h, m) = self.hoursAndMinutes
        return String(format: "%d:%02d", h, m)
    }
    
    func toVerboseTimeString() -> String {
        let (h, m) = self.hoursAndMinutes
        if h > 0 {
            return "\(h) Std. \(m) Min."
        } else {
            return "\(m) Min."
        }
    }
}

extension NSColor {
    static let liquidGlassBackground = NSColor.windowBackgroundColor.withAlphaComponent(0.6)
}
