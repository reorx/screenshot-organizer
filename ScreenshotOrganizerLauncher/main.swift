import Foundation
import AppKit

let mainAppIdentifier = "com.reorx.ScreenshotOrganizer"
let mainAppPath = Bundle.main.bundlePath.replacingOccurrences(of: "/Contents/Library/LoginItems/ScreenshotOrganizerLauncher.app", with: "")

let runningApps = NSWorkspace.shared.runningApplications
let isRunning = runningApps.contains { $0.bundleIdentifier == mainAppIdentifier }
print("isRunning: \(isRunning)")

if !isRunning {
    print("Not running, opening main app")
    let url = URL(fileURLWithPath: mainAppPath)
    let configuration = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in }
}
