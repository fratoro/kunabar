import SwiftUI

struct AboutView: View {
    var onClose: @MainActor @Sendable () -> Void
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage(named: NSImage.applicationIconName)!)
                .resizable()
                .frame(width: 64, height: 64)
            
            Text("kunabar")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 5) {
                Text("Version \(appVersion)")
                Text("Build \(buildNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Link("View on GitHub", destination: URL(string: "https://github.com/fratoro/kunabar")!)
                .foregroundColor(.blue)
            
            Button("Close") {
                onClose()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(30)
        .frame(width: 300)
    }
}
