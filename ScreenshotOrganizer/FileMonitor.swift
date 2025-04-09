import Foundation


enum FileMonitorError: Error {
    case directoryNotFound
    case fileSystemError(String)
    case invalidScreenshot
    case moveFailed(String)
}

class FileMonitor {
    private let directoryURL: URL
    private var directoryMonitor: DispatchSourceFileSystemObject?
    private let screenshotRegex = try! NSRegularExpression(pattern: "Screenshot (\\d{4})-(\\d{2})-(\\d{2}) at .+\\.png", options: [])
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

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: targetURL.path) else {
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
                }
            }
            AppLogger.shared.info("Finished organizing directory")
        } catch {
            throw FileMonitorError.fileSystemError(error.localizedDescription)
        }
    }

    func startMonitoring() throws {
        guard !isMonitoring else { return }
        AppLogger.shared.info("Starting to monitor directory: \(directoryURL.path)")
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

        let destinationFolderURL = directoryURL.appendingPathComponent(year).appendingPathComponent(month)
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
            AppLogger.shared.info("Moved \(filename) to \(year)/\(month)/")
        } catch {
            throw FileMonitorError.moveFailed(error.localizedDescription)
        }
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
}
