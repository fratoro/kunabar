import Foundation
import Cocoa
import UserNotifications

@MainActor
protocol TimeTrackerDelegate: AnyObject {
    func timeTrackerDidUpdate(_ tracker: TimeTracker)
    func timeTrackerDidReachTarget(_ tracker: TimeTracker)
}

@MainActor
class TimeTracker {
    static let shared = TimeTracker()
    
    weak var delegate: TimeTrackerDelegate?
    
    // State
    private(set) var currentSeconds: Int = 0
    private(set) var isRunning: Bool = false
    
    var dailyTargetSeconds: Int = Int(8.4 * 3600) { // Default 8.4h
        didSet {
            UserDefaults.standard.set(dailyTargetSeconds, forKey: kDailyTarget)
            delegate?.timeTrackerDidUpdate(self)
        }
    }
    
    private var timer: Timer?
    private var lastSyncDate: Date?
    private let syncInterval: TimeInterval = 3600 // 1 hour
    
    // Persistence keys
    private let kProjectId = "projectId"
    private let kTaskId = "taskId"
    private let kDailyTarget = "dailyTarget"
    
    var projectId: String {
        get { UserDefaults.standard.string(forKey: kProjectId) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: kProjectId) }
    }
    
    var taskId: String {
        get { UserDefaults.standard.string(forKey: kTaskId) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: kTaskId) }
    }
    
    var dailyTarget: Double { // In hours for UI convenience
        get { Double(dailyTargetSeconds) / 3600.0 }
        set {
            dailyTargetSeconds = Int(newValue * 3600)
        }
    }
    
    init() {
        if let savedTarget = UserDefaults.standard.value(forKey: kDailyTarget) as? Int {
            dailyTargetSeconds = savedTarget
        }
        
        // Setup notification for sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    func startInitialFetch() {
        // Called after delegate is set to avoid deadlock
        Task {
            await fetchTodayBalance()
        }
    }
    
    func startTimer() {
        guard !taskId.isEmpty else {
            // Alert user? handled by UI
            return
        }
        
        // Optimistic UI update
        isRunning = true
        startLocalTimer()
        delegate?.timeTrackerDidUpdate(self)
        
        Task {
            do {
                try await HakunaAPI.shared.startTimer(taskId: taskId, projectId: projectId.isEmpty ? nil : projectId)
                // Confirmed
            } catch let error as HakunaError {
                print("Failed to start timer: \(error)")
                
                // If 422, it means timer is already running. Sync state.
                if case .apiError(let code) = error, code == 422 {
                    await fetchTodayBalance()
                } else {
                    isRunning = false
                    stopLocalTimer()
                    delegate?.timeTrackerDidUpdate(self)
                }
            } catch {
                print("Failed to start timer: \(error)")
                isRunning = false
                stopLocalTimer()
                delegate?.timeTrackerDidUpdate(self)
            }
        }
    }
    
    func stopTimer() {
        // Optimistic UI
        isRunning = false
        stopLocalTimer()
        delegate?.timeTrackerDidUpdate(self)
        
        Task {
            do {
                try await HakunaAPI.shared.stopTimer()
            } catch {
                print("Failed to stop timer: \(error)")
            }
            // After stop, sync immediately
            await fetchTodayBalance()
        }
    }
    
    private func startLocalTimer() {
        stopLocalTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentSeconds += 1
                self.checkTarget()
                self.delegate?.timeTrackerDidUpdate(self)
                self.checkBackgroundSync()
            }
        }
    }
    
    private func stopLocalTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkTarget() {
        if currentSeconds == dailyTargetSeconds {
            sendNotification()
            delegate?.timeTrackerDidReachTarget(self)
        }
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily target reached"
        content.body = "You have reached your daily target of \(dailyTargetSeconds.toVerboseTimeString()) today."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "targetReached", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func fetchTodayBalance() async {
        do {
            // 1. Fetch today's finished entries
            let finishedSeconds = try await HakunaAPI.shared.getTodayTimeEntries()
            
            // 2. Fetch running timer
            let runningTimer = try await HakunaAPI.shared.getRunningTimer()
            
            if let timer = runningTimer, let startDate = timer.startDate {
                // Timer is running
                print("✅ Timer detected: started at \(startDate), task_id: \(timer.task_id ?? "nil"), project_id: \(timer.project_id ?? "nil")")
                isRunning = true
                let elapsed = Int(Date().timeIntervalSince(startDate))
                currentSeconds = finishedSeconds + elapsed
                startLocalTimer()

                if let pid = timer.project_id { projectId = pid }
                if let tid = timer.task_id { taskId = tid }
                
            } else {
                // No timer running
                print("ℹ️ No timer running (runningTimer is nil or no startDate)")
                isRunning = false
                currentSeconds = finishedSeconds
                stopLocalTimer()
            }
            lastSyncDate = Date()
            delegate?.timeTrackerDidUpdate(self)
            
        } catch {
            print("Failed to fetch balance: \(error)")
        }
    }
    
    private func checkBackgroundSync() {
        guard let lastSync = lastSyncDate else { return }
        if Date().timeIntervalSince(lastSync) >= syncInterval {
            Task {
                await fetchTodayBalance()
            }
        }
    }
    
    @objc private func handleSleep() {
        if isRunning {
            // Requirement: "pause timer automatically on sleep"
            stopTimer()
        }
    }
    
    @objc private func handleWake() {
        Task {
            await fetchTodayBalance()
        }
    }
}
