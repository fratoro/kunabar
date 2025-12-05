import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Status Bar
        statusBarController = StatusBarController()
        
        // Check for API Key
        if UserDefaults.standard.string(forKey: "apiKey") == nil {
            // Open Settings if no key
            statusBarController?.perform(#selector(StatusBarController.openSettings))
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
