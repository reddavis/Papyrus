import Foundation
import os.log


final class Logger
{
    var logLevel: LogLevel = .info
    
    // Private
    private let log: OSLog
    
    // MARK: Initialziation
    
    required init(subsystem: String, category: String)
    {
        self.log = OSLog(subsystem: subsystem, category: category)
    }
    
    // MARK: API
    
    func info(_ message: String)
    {
        self.log("ℹ️ \(message)", level: .info)
    }
    
    func debug(_ message: String)
    {
        self.log("🔎 \(message)", level: .debug)
    }
    
    func error(_ message: String)
    {
        self.log("⚠️ \(message)", level: .error)
    }

    func fault(_ message: String)
    {
        self.log("🔥 \(message)", level: .fault)
    }
    
    // MARK: Log
    
    private func log(_ message: String, level: LogLevel)
    {
        guard level >= self.logLevel,
              let type = level.logType else { return }
        os_log("%@", log: self.log, type: type, message)
    }
}



// MARK: Log level

public enum LogLevel: Int
{
    case info
    case debug
    case error
    case fault
    case off
    
    var logType: OSLogType? {
        switch self
        {
        case .info:
            return .info
        case .debug:
            return .debug
        case .error:
            return .error
        case .fault:
            return .fault
        case .off:
            return nil
        }
    }
}


// MARK: Comparable

extension LogLevel: Comparable
{
    public static func <(lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}
