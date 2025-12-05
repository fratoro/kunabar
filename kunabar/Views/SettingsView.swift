import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var projectId: String = ""
    @State private var taskId: String = ""
    @State private var targetHoursString: String = "8.4"
    
    var onClose: @MainActor @Sendable () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Settings")
                .font(.title)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 16) {
                // Hakuna API Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hakuna API")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("Enter your API key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Link("Get your API key →", destination: URL(string: "https://app.hakuna.ch/my_settings")!)
                                .font(.caption)
                                .padding(.top, 2)
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Task ID (Required)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g. 2", text: $taskId)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Project ID (Optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g. 3", text: $projectId)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Daily Target Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Target")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("e.g. 8.4", text: $targetHoursString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("hours")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Button("Save & Close") {
                saveSettings()
                onClose()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let key = UserDefaults.standard.string(forKey: "apiKey") {
            apiKey = key
        }
        projectId = TimeTracker.shared.projectId
        taskId = TimeTracker.shared.taskId
        
        let seconds = TimeTracker.shared.dailyTargetSeconds
        let hours = Double(seconds) / 3600.0
        // Format to sensible decimal places
        targetHoursString = String(format: "%.2g", hours)
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        TimeTracker.shared.projectId = projectId
        TimeTracker.shared.taskId = taskId
        
        if let hours = Double(targetHoursString.replacingOccurrences(of: ",", with: ".")) {
            let totalSeconds = Int(hours * 3600)
            TimeTracker.shared.dailyTargetSeconds = totalSeconds
        }
        
        // Trigger a fetch to ensure we have valid data if key changed
        Task {
            await TimeTracker.shared.fetchTodayBalance()
        }
    }
}
