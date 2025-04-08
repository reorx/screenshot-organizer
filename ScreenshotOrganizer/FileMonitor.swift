import Foundation

class FileMonitor {
    private let directoryURL: URL
    private var directoryMonitor: DispatchSourceFileSystemObject?
    private let screenshotRegex = try! NSRegularExpression(pattern: "Screenshot (\\d{4})-(\\d{2})-(\\d{2}) at .+\\.png", options: [])
    private var fileSystemEventStream: FSEventStreamRef?
    private let fileSystemEventCallback: FSEventStreamCallback = { (stream, contextInfo, numEvents, eventPaths, eventFlags, eventIds) in
        let fileMonitor = Unmanaged<FileMonitor>.fromOpaque(contextInfo!).takeUnretainedValue()
        fileMonitor.checkForNewScreenshots()
    }

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    func startMonitoring() throws {
        print("Starting to monitor directory: \(directoryURL.path)")
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
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
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
                    organizeScreenshot(fileURL: fileURL)
                }
            }
        } catch {
            print("Error scanning directory: \(error)")
        }
    }

    private func isScreenshot(fileURL: URL) -> Bool {
        let filename = fileURL.lastPathComponent
        let range = NSRange(location: 0, length: filename.utf16.count)
        let matches = screenshotRegex.matches(in: filename, options: [], range: range)
        return !matches.isEmpty
    }

    private func organizeScreenshot(fileURL: URL) {
        let filename = fileURL.lastPathComponent
        let range = NSRange(location: 0, length: filename.utf16.count)

        guard let match = screenshotRegex.firstMatch(in: filename, options: [], range: range) else {
            return
        }

        let yearRange = Range(match.range(at: 1), in: filename)!
        let monthRange = Range(match.range(at: 2), in: filename)!

        let year = String(filename[yearRange])
        let month = String(filename[monthRange])

        let destinationFolderURL = directoryURL.appendingPathComponent(year).appendingPathComponent(month)
        let destinationFileURL = destinationFolderURL.appendingPathComponent(filename)

        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)
            try fileManager.moveItem(at: fileURL, to: destinationFileURL)
            print("Moved \(filename) to \(year)/\(month)/")
        } catch {
            print("Error organizing screenshot: \(error)")
        }
    }

    func stopMonitoring() {
        if let stream = fileSystemEventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            fileSystemEventStream = nil
        }
    }
}
