import SwiftUI

enum SettingsKey {
    static let monitoredDirectory = "monitoredDirectory"
    static let logDirectory = "logDirectory"
    static let enableMonitoringOnStart = "enableMonitoringOnStart"
    static let launchAtLogin = "launchAtLogin"
}

struct SettingsDefault {
    static let monitoredDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.path
    static let logDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
    static let enableMonitoringOnStart = true
    static let launchAtLogin = false
}
