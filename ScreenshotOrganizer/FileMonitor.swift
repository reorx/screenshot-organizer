import Foundation
import Cocoa

enum FileMonitorError: Error {
    case directoryNotFound
    case fileSystemError(String)
    case invalidScreenshot
    case moveFailed(String)
    case permissionDenied(String)
}

class FileMonitor {
    private let directoryURL: URL
    private var directoryMonitor: DispatchSourceFileSystemObject?
    private let screenshotRegex = try! NSRegularExpression(pattern: "Screenshot (\\d{4})-(\\d{2})-(\\d{2}) at .+\\.png", options: [])
    private let recordingRegex = try! NSRegularExpression(pattern: "Screen Recording (\\d{4})-(\\d{2})-(\\d{2}) at .+\\.mov", options: [])
    private var fileSystemEventStream: FSEventStreamRef?
    var isMonitoring: Bool = false
    private let fileSystemEventCallback: FSEventStreamCallback = { (stream, contextInfo, numEvents, eventPaths, eventFlags, eventIds) in
        let fileMonitor = Unmanaged<FileMonitor>.fromOpaque(contextInfo!).takeUnretainedValue()
        fileMonitor.checkForNewScreenshots()
    }

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    func organizeNow(directoryURL: URL? = nil) throws {
        let targetURL = directoryURL ?? self.directoryURL
        AppLogger.shared.info("Starting to organize directory: \(targetURL.path)")

        try checkDirectoryAccess(for: targetURL)

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: targetURL.path) else {
            print("Directory does not exist: \(targetURL.path)")
            throw FileMonitorError.directoryNotFound
        }
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: targetURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            for fileURL in fileURLs {
                if isScreenshot(fileURL: fileURL) {
                    try organizeScreenshot(fileURL: fileURL)
                } else if isScreenRecording(fileURL: fileURL) {
                    try organizeScreenRecording(fileURL: fileURL)
                }
            }
            AppLogger.shared.info("Finished organizing directory")
        } catch {
            print("Error organizing directory: \(error)")
            throw FileMonitorError.fileSystemError(error.localizedDescription)
        }
    }

    func startMonitoring() throws {
        guard !isMonitoring else { return }
        AppLogger.shared.info("Starting to monitor directory: \(directoryURL.path)")

        try checkDirectoryAccess(for: directoryURL)

        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            throw NSError(domain: "FileMonitor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Directory does not exist"])
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        fileSystemEventStream = FSEventStreamCreate(
            nil,
            fileSystemEventCallback,
            &context,
            [directoryURL.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        )

        if let stream = fileSystemEventStream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
            FSEventStreamStart(stream)
            isMonitoring = true
        } else {
            throw NSError(domain: "FileMonitor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create file system event stream"])
        }
    }

    private func checkForNewScreenshots() {
        let fileManager = FileManager.default

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            for fileURL in fileURLs {
                if isScreenshot(fileURL: fileURL) {
                    try organizeScreenshot(fileURL: fileURL)
                } else if isScreenRecording(fileURL: fileURL) {
                    try organizeScreenRecording(fileURL: fileURL)
                }
            }
        } catch {
            AppLogger.shared.error("Error scanning directory: \(error)")
        }
    }

    private func isScreenshot(fileURL: URL) -> Bool {
        let filename = fileURL.lastPathComponent
        let range = NSRange(location: 0, length: filename.utf16.count)
        let matches = screenshotRegex.matches(in: filename, options: [], range: range)
        return !matches.isEmpty
    }

    private func isScreenRecording(fileURL: URL) -> Bool {
        let filename = fileURL.lastPathComponent
        let range = NSRange(location: 0, length: filename.utf16.count)
        let matches = recordingRegex.matches(in: filename, options: [], range: range)
        return !matches.isEmpty
    }

    private func organizeFileByDate(fileURL: URL, baseURL: URL, year: String, month: String, logPrefix: String = "") throws {
        let filename = fileURL.lastPathComponent
        let destinationFolderURL = baseURL.appendingPathComponent(year).appendingPathComponent(month)
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)
            AppLogger.shared.info("Created directory: \(destinationFolderURL.path)")

            var destinationFileURL = destinationFolderURL.appendingPathComponent(filename)
            var counter = 1

            while fileManager.fileExists(atPath: destinationFileURL.path) {
                let nameWithoutExt = (filename as NSString).deletingPathExtension
                let ext = (filename as NSString).pathExtension
                destinationFileURL = destinationFolderURL.appendingPathComponent("\(nameWithoutExt) (\(counter)).\(ext)")
                counter += 1
            }

            try fileManager.moveItem(at: fileURL, to: destinationFileURL)
            AppLogger.shared.info("Moved \(filename) to \(logPrefix)\(year)/\(month)/")
        } catch {
            throw FileMonitorError.moveFailed(error.localizedDescription)
        }
    }

    private func organizeScreenRecording(fileURL: URL) throws {
        let filename = fileURL.lastPathComponent
        let range = NSRange(location: 0, length: filename.utf16.count)

        guard let match = recordingRegex.firstMatch(in: filename, options: [], range: range) else {
            throw FileMonitorError.invalidScreenshot
        }

        let yearRange = Range(match.range(at: 1), in: filename)!
        let monthRange = Range(match.range(at: 2), in: filename)!

        let year = String(filename[yearRange])
        let month = String(filename[monthRange])

        // Create recordings directory under the main directory
        let recordingsBaseURL = directoryURL.appendingPathComponent("recordings")
        try organizeFileByDate(fileURL: fileURL, baseURL: recordingsBaseURL, year: year, month: month, logPrefix: "recordings/")
    }

    private func organizeScreenshot(fileURL: URL) throws {
        let filename = fileURL.lastPathComponent
        let range = NSRange(location: 0, length: filename.utf16.count)

        guard let match = screenshotRegex.firstMatch(in: filename, options: [], range: range) else {
            throw FileMonitorError.invalidScreenshot
        }

        let yearRange = Range(match.range(at: 1), in: filename)!
        let monthRange = Range(match.range(at: 2), in: filename)!

        let year = String(filename[yearRange])
        let month = String(filename[monthRange])

        try organizeFileByDate(fileURL: fileURL, baseURL: directoryURL, year: year, month: month)
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        if let stream = fileSystemEventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            fileSystemEventStream = nil
            isMonitoring = false
        }
    }

    /// Checks for and requests access to the given directory
    private func checkDirectoryAccess(for directoryURL: URL) throws {
        // Check if we can access the directory
        do {
            // Try to list contents as a simple access test
            let _ = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        } catch let error as NSError {
            // If access is denied, try to request permission
            if error.domain == NSCocoaErrorDomain &&
               (error.code == 257 || error.code == 260 || error.code == 1) {

                AppLogger.shared.info("Requesting access permission for: \(directoryURL.path)")

                // Request access using NSOpenPanel as a workaround
                let openPanel = NSOpenPanel()
                openPanel.message = "Grant access to \(directoryURL.lastPathComponent) folder to organize screenshots"
                openPanel.prompt = "Grant Access"
                openPanel.directoryURL = directoryURL
                openPanel.canChooseDirectories = true
                openPanel.canChooseFiles = false
                openPanel.canCreateDirectories = false
                openPanel.allowsMultipleSelection = false

                let response = openPanel.runModal()
                if response == .OK, let selectedURL = openPanel.url {
                    // Access granted, try the operation again
                    // The security scoped bookmark may be needed for future sessions
                    let _ = selectedURL.startAccessingSecurityScopedResource()
                    AppLogger.shared.info("Access granted for: \(selectedURL.path)")
                } else {
                    AppLogger.shared.error("Access denied for: \(directoryURL.path)")
                    throw FileMonitorError.permissionDenied("Permission denied to access \(directoryURL.path). Please grant access in System Settings > Privacy & Security > Files and Folders.")
                }
            } else {
                throw FileMonitorError.fileSystemError(error.localizedDescription)
            }
        }
    }
}
