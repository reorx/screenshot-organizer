import Foundation
import OSLog

public class AppLogger {
    public static let shared = AppLogger()
    private let fileLogger: FileLogger
    private let systemLogger = os.Logger(subsystem: "com.screenshotorganizer", category: "app")

    private init() {
        fileLogger = FileLogger()
    }

    public func setup(logDirectory: URL) {
        fileLogger.setup(logDirectory: logDirectory)
    }

    public func info(_ message: String) {
        systemLogger.info("\(message)")
        fileLogger.log(message, level: .info)
    }

    public func error(_ message: String) {
        systemLogger.error("\(message)")
        fileLogger.log(message, level: .error)
    }

    public func debug(_ message: String) {
        systemLogger.debug("\(message)")
        fileLogger.log(message, level: .debug)
    }
}

private class FileLogger {
    private var logFileURL: URL?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func setup(logDirectory: URL) {
        // Create the log directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create log directory: \(error)")
        }

        let timestamp = DateFormatter.logFileName.string(from: Date())
        logFileURL = logDirectory.appendingPathComponent("screenshot-organizer-\(timestamp).log")
    }

    func log(_ message: String, level: LogLevel) {
        guard let logFileURL = logFileURL else { return }

        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)\n"

        do {
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                try logMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
            } else {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logMessage.data(using: .utf8)!)
                fileHandle.closeFile()
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
}

private enum LogLevel: String {
    case info = "INFO"
    case error = "ERROR"
    case debug = "DEBUG"
}

extension DateFormatter {
    static let logFileName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
