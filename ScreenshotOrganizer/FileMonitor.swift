import Foundation

class FileMonitor {
    private let directoryURL: URL
    private var directoryMonitor: DispatchSourceFileSystemObject?
    private let screenshotRegex = try! NSRegularExpression(pattern: "Screenshot (\\d{4})-(\\d{2})-(\\d{2}) at .+\\.png", options: [])

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    func startMonitoring() {
        let directoryDescriptor = open(directoryURL.path, O_EVTONLY)

        if directoryDescriptor < 0 {
            print("Error: Could not open directory for monitoring")
            return
        }

        directoryMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryDescriptor,
            eventMask: .write,
            queue: .global()
        )

        directoryMonitor?.setEventHandler { [weak self] in
            self?.checkForNewScreenshots()
        }

        directoryMonitor?.setCancelHandler {
            close(directoryDescriptor)
        }

        directoryMonitor?.resume()
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
            // Create directory if it doesn't exist
            try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)

            // Move the file
            try fileManager.moveItem(at: fileURL, to: destinationFileURL)

            print("Moved \(filename) to \(year)/\(month)/")
        } catch {
            print("Error organizing screenshot: \(error)")
        }
    }

    func stopMonitoring() {
        directoryMonitor?.cancel()
        directoryMonitor = nil
    }
}
