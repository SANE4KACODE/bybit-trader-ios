import Foundation
import os.log

class LoggingService: ObservableObject {
    static let shared = LoggingService()
    
    private let logger = Logger(subsystem: "com.bybittrader.app", category: "main")
    private let fileLogger = FileLogger()
    
    @Published var logs: [LogEntry] = []
    @Published var errorCount: Int = 0
    @Published var warningCount: Int = 0
    
    private init() {
        setupLogging()
    }
    
    // MARK: - Logging Methods
    func info(_ message: String, category: String = "general", metadata: [String: Any]? = nil) {
        let entry = LogEntry(level: .info, message: message, category: category, metadata: metadata, timestamp: Date())
        addLog(entry)
        logger.info("\(message)")
        
        if let metadata = metadata {
            logger.info("Metadata: \(String(describing: metadata))")
        }
    }
    
    func warning(_ message: String, category: String = "general", metadata: [String: Any]? = nil) {
        let entry = LogEntry(level: .warning, message: message, category: category, metadata: metadata, timestamp: Date())
        addLog(entry)
        logger.warning("\(message)")
        warningCount += 1
        
        if let metadata = metadata {
            logger.warning("Metadata: \(String(describing: metadata))")
        }
    }
    
    func error(_ message: String, category: String = "general", error: Error? = nil, metadata: [String: Any]? = nil) {
        let entry = LogEntry(level: .error, message: message, category: category, error: error, metadata: metadata, timestamp: Date())
        addLog(entry)
        logger.error("\(message)")
        errorCount += 1
        
        if let error = error {
            logger.error("Error details: \(error.localizedDescription)")
        }
        
        if let metadata = metadata {
            logger.error("Metadata: \(String(describing: metadata))")
        }
    }
    
    func debug(_ message: String, category: String = "general", metadata: [String: Any]? = nil) {
        #if DEBUG
        let entry = LogEntry(level: .debug, message: message, category: category, metadata: metadata, timestamp: Date())
        addLog(entry)
        logger.debug("\(message)")
        
        if let metadata = metadata {
            logger.debug("Metadata: \(String(describing: metadata))")
        }
        #endif
    }
    
    // MARK: - API Logging
    func logAPIRequest(_ request: URLRequest, category: String = "api") {
        let metadata: [String: Any] = [
            "url": request.url?.absoluteString ?? "unknown",
            "method": request.httpMethod ?? "unknown",
            "headers": request.allHTTPHeaderFields ?? [:],
            "body": request.httpBody?.base64EncodedString() ?? "none"
        ]
        
        info("API Request: \(request.httpMethod ?? "unknown") \(request.url?.absoluteString ?? "unknown")", category: category, metadata: metadata)
    }
    
    func logAPIResponse(_ response: URLResponse, data: Data?, error: Error?, category: String = "api") {
        let metadata: [String: Any] = [
            "statusCode": (response as? HTTPURLResponse)?.statusCode ?? 0,
            "url": response.url?.absoluteString ?? "unknown",
            "dataSize": data?.count ?? 0,
            "error": error?.localizedDescription ?? "none"
        ]
        
        if let error = error {
            self.error("API Response Error", category: category, error: error, metadata: metadata)
        } else {
            info("API Response: \(response.url?.absoluteString ?? "unknown")", category: category, metadata: metadata)
        }
    }
    
    // MARK: - Trade Logging
    func logTrade(_ trade: Trade, action: String, category: String = "trading") {
        let metadata: [String: Any] = [
            "symbol": trade.symbol,
            "side": trade.side,
            "quantity": trade.quantity,
            "price": trade.price,
            "action": action
        ]
        
        info("Trade \(action): \(trade.symbol) \(trade.side) \(trade.quantity)@\(trade.price)", category: category, metadata: metadata)
    }
    
    // MARK: - User Action Logging
    func logUserAction(_ action: String, category: String = "user", metadata: [String: Any]? = nil) {
        info("User Action: \(action)", category: category, metadata: metadata)
    }
    
    // MARK: - Performance Logging
    func logPerformance(_ operation: String, duration: TimeInterval, category: String = "performance") {
        let metadata: [String: Any] = [
            "duration": duration,
            "operation": operation
        ]
        
        if duration > 1.0 {
            warning("Slow operation: \(operation) took \(String(format: "%.2f", duration))s", category: category, metadata: metadata)
        } else {
            debug("Performance: \(operation) took \(String(format: "%.2f", duration))s", category: category, metadata: metadata)
        }
    }
    
    // MARK: - Private Methods
    private func addLog(_ entry: LogEntry) {
        DispatchQueue.main.async {
            self.logs.append(entry)
            
            // Keep only last 1000 logs
            if self.logs.count > 1000 {
                self.logs.removeFirst(self.logs.count - 1000)
            }
        }
        
        // Save to file
        fileLogger.write(entry)
    }
    
    private func setupLogging() {
        info("LoggingService initialized", category: "system")
        
        // Log system info
        let systemInfo: [String: Any] = [
            "device": UIDevice.current.model,
            "system": UIDevice.current.systemName,
            "version": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        ]
        
        info("System Information", category: "system", metadata: systemInfo)
    }
    
    // MARK: - Public Methods
    func clearLogs() {
        logs.removeAll()
        errorCount = 0
        warningCount = 0
        fileLogger.clear()
    }
    
    func exportLogs() -> String {
        var export = "=== Bybit Trader Logs ===\n"
        export += "Generated: \(Date())\n"
        export += "Total Logs: \(logs.count)\n"
        export += "Errors: \(errorCount)\n"
        export += "Warnings: \(warningCount)\n\n"
        
        for log in logs {
            export += "[\(log.timestamp.formatted())] [\(log.level.rawValue.uppercased())] [\(log.category)] \(log.message)\n"
            
            if let error = log.error {
                export += "  Error: \(error.localizedDescription)\n"
            }
            
            if let metadata = log.metadata {
                export += "  Metadata: \(metadata)\n"
            }
            
            export += "\n"
        }
        
        return export
    }
    
    func getLogsByCategory(_ category: String) -> [LogEntry] {
        return logs.filter { $0.category == category }
    }
    
    func getLogsByLevel(_ level: LogLevel) -> [LogEntry] {
        return logs.filter { $0.level == level }
    }
}

// MARK: - Models
struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let level: LogLevel
    let message: String
    let category: String
    let error: Error?
    let metadata: [String: Any]?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case level, message, category, timestamp
    }
    
    init(level: LogLevel, message: String, category: String, error: Error? = nil, metadata: [String: Any]? = nil, timestamp: Date) {
        self.level = level
        self.message = message
        self.category = category
        self.error = error
        self.metadata = metadata
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(LogLevel.self, forKey: .level)
        message = try container.decode(String.self, forKey: .message)
        category = try container.decode(String.self, forKey: .category)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        error = nil
        metadata = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(message, forKey: .message)
        try container.encode(category, forKey: .category)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

enum LogLevel: String, CaseIterable, Codable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    var color: String {
        switch self {
        case .debug: return "#6c757d"
        case .info: return "#007bff"
        case .warning: return "#ffc107"
        case .error: return "#dc3545"
        }
    }
    
    var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// MARK: - File Logger
class FileLogger {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "filelogger", qos: .utility)
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("bybit_trader.log")
    }
    
    func write(_ entry: LogEntry) {
        queue.async {
            let logLine = "[\(entry.timestamp.formatted())] [\(entry.level.rawValue.uppercased())] [\(entry.category)] \(entry.message)\n"
            
            if let data = logLine.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.fileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: self.fileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: self.fileURL)
                }
            }
        }
    }
    
    func clear() {
        queue.async {
            try? "".write(to: self.fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    func getLogFileContent() -> String {
        return (try? String(contentsOf: fileURL)) ?? "No log file found"
    }
}
