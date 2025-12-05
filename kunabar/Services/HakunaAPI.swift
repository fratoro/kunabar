import Foundation

enum HakunaError: Error, Sendable {
    case invalidURL
    case noAPIKey
    case networkError(Error)
    case decodingError(Error)
    case apiError(Int)
}

struct TimeEntry: Decodable, Sendable {
    let id: Int
    let duration: Int // in seconds
    
    enum CodingKeys: String, CodingKey {
        case id
        case duration
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        
        if let durationInt = try? container.decode(Int.self, forKey: .duration) {
            duration = durationInt
        } else if let durationString = try? container.decode(String.self, forKey: .duration) {
            // Try to parse "HH:MM:SS" or just stringified int
            if let seconds = Int(durationString) {
                duration = seconds
            } else {
                // Parse HH:MM:SS
                let components = durationString.split(separator: ":").compactMap { Int($0) }
                if components.count == 3 {
                    duration = (components[0] * 3600) + (components[1] * 60) + components[2]
                } else if components.count == 2 {
                    duration = (components[0] * 3600) + (components[1] * 60)
                } else if components.count == 1 {
                    duration = components[0]
                } else {
                    duration = 0
                }
            }
        } else {
            duration = 0
        }
    }
}

struct TimerStartResponse: Decodable, Sendable {
    let id: Int
}

actor HakunaAPI {
    static let shared = HakunaAPI()
    private let baseURL = "https://app.hakuna.ch/api/v1"
    
    private init() {}
    
    private func getHeaders() throws -> [String: String] {
        guard let apiKey = UserDefaults.standard.string(forKey: "apiKey"), !apiKey.isEmpty else {
            throw HakunaError.noAPIKey
        }
        return [
            "X-Auth-Token": apiKey,
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    func getTodayTimeEntries() async throws -> Int {
        guard let url = URL(string: "\(baseURL)/time_entries?date=\(Date().iso8601DateString)") else {
            throw HakunaError.invalidURL
        }

        let data = try await performRequest(url: url, method: "GET")
        let entries = try JSONDecoder().decode([TimeEntry].self, from: data)
        let totalSeconds = entries.reduce(0) { $0 + $1.duration }
        return totalSeconds
    }
    
    func startTimer(taskId: String, projectId: String?) async throws {
        guard let url = URL(string: "\(baseURL)/timer") else {
            throw HakunaError.invalidURL
        }
        
        var body: [String: Any] = [
            "task_id": taskId
        ]
        
        if let projectId = projectId {
            body["project_id"] = projectId
        }
        
        _ = try await performRequest(url: url, method: "POST", body: body)
    }
    
    func stopTimer() async throws {
        guard let url = URL(string: "\(baseURL)/timer") else {
            throw HakunaError.invalidURL
        }
        
        _ = try await performRequest(url: url, method: "PUT")
    }
    
    private func performRequest(url: URL, method: String, body: [String: Any]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let headers = try getHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HakunaError.networkError(NSError(domain: "InvalidResponse", code: 0))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw HakunaError.apiError(httpResponse.statusCode)
        }
        
        return data
    }
    
    func getRunningTimer() async throws -> RunningTimer? {
        guard let url = URL(string: "\(baseURL)/timer") else {
            throw HakunaError.invalidURL
        }
        
        do {
            let data = try await performRequest(url: url, method: "GET")
            
            // Log raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 GET /timer response: \(jsonString)")
            }
            
            let timer = try JSONDecoder().decode(RunningTimer.self, from: data)
            print("✅ Decoded timer: id=\(timer.id ?? -1), start_time=\(timer.start_time ?? "nil"), task_id=\(timer.task_id ?? "nil")")
            return timer
        } catch let error as HakunaError {
            if case .apiError(let code) = error, code == 404 {
                print("ℹ️ GET /timer returned 404 - no timer running")
                return nil
            }
            throw error
        }
    }
}

struct RunningTimer: Decodable, Sendable {
    let id: Int?
    let date: String?
    let start_time: String?
    let duration_in_seconds: Double?
    let task: TaskInfo?
    let project: ProjectInfo?
    
    struct TaskInfo: Decodable, Sendable {
        let id: Int
        let name: String?
    }
    
    struct ProjectInfo: Decodable, Sendable {
        let id: Int
        let name: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, start_time, duration_in_seconds, task, project
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(Int.self, forKey: .id)
        date = try? container.decode(String.self, forKey: .date)
        start_time = try? container.decode(String.self, forKey: .start_time)
        duration_in_seconds = try? container.decode(Double.self, forKey: .duration_in_seconds)
        task = try? container.decode(TaskInfo.self, forKey: .task)
        project = try? container.decode(ProjectInfo.self, forKey: .project)
    }
    
    nonisolated var task_id: String? {
        guard let task = task else { return nil }
        return String(task.id)
    }
    
    nonisolated var project_id: String? {
        guard let project = project else { return nil }
        return String(project.id)
    }
    
    nonisolated var startDate: Date? {
        guard let date = date, let start_time = start_time else { return nil }
        
        // Combine date (YYYY-MM-DD) and start_time (HH:MM) into a full datetime
        let dateTimeString = "\(date)T\(start_time):00"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current // Use local timezone
        
        return formatter.date(from: dateTimeString)
    }
}

extension Date {
    nonisolated var iso8601DateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
