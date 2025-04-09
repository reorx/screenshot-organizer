import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var fileMonitor: FileMonitor!
    private var statusMenu: NSMenu!
    @AppStorage(SettingsKey.enableMonitoringOnStart) private var enableMonitoringOnStart: Bool = SettingsDefault.enableMonitoringOnStart
    @AppStorage(SettingsKey.monitoredDirectory) private var monitoredDirectory: String = SettingsDefault.monitoredDirectory
    @AppStorage(SettingsKey.logDirectory) private var logDirectory: String = SettingsDefault.logDirectory

    private enum Window {
        static let width: CGFloat = 400
        static let height: CGFloat = 400
    }

    // private func findDesktopDirectory() -> URL? {
    //     // First try the regular Desktop directory
    //     let regularDesktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    //     if FileManager.default.fileExists(atPath: regularDesktop.path) {
    //         return regularDesktop
    //     }
    //     return nil
    // }

    private func startFileMonitoring() {
        do {
            try fileMonitor.startMonitoring()
            // Update status item icon and title
            if let button = statusItem.button {
                let image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Screenshot Organizer")
                image?.isTemplate = true
                button.image = image
                button.imagePosition = .imageLeft
                button.title = ""
            }
            // Update menu item
            if let menu = statusMenu, menu.items.count > 2 {
                menu.item(at: 2)?.title = "Turn off"
            }
            AppLogger.shared.info("File monitoring started")
        } catch {
            showDirectoryNotFoundAlert(error: error)
            AppLogger.shared.error("Failed to start file monitoring: \(error.localizedDescription)")
            return
        }
    }

    private func stopFileMonitoring() {
        fileMonitor.stopMonitoring()
        // Update status item icon and title
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Screenshot Organizer")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeft
            button.title = ""
            button.alphaValue = 0.5 // Dim the button
        }
        // Update menu item
        if let menu = statusMenu, menu.items.count > 2 {
            menu.item(at: 2)?.title = "Turn on"
        }
        AppLogger.shared.info("File monitoring stopped")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the logger
        setupAppLogger(logDirectory: URL(fileURLWithPath: logDirectory))
        AppLogger.shared.info("Screenshot Organizer started")

        // Set up the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Initialize the file monitor with the saved or default directory
        fileMonitor = FileMonitor(directoryURL: URL(fileURLWithPath: monitoredDirectory))

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Screenshot Organizer")
            image?.isTemplate = true
            button.image = image
        }

        // Check if directory exists and start monitoring if enabled
        if enableMonitoringOnStart {
            startFileMonitoring()
        }

        // Set up notification for directory changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMonitoredDirectoryChange),
            name: Notification.Name("MonitoredDirectoryChanged"),
            object: nil
        )

        // Set up notification for log directory changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogDirectoryChange),
            name: Notification.Name("LogDirectoryChanged"),
            object: nil
        )

        // Set up the menu for the status item
        setupStatusMenu()
    }

    private func showDirectoryNotFoundAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Directory Not Found"
        alert.informativeText = "Could not monitor the directory.  Monitoring has been disabled. Error: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func handleMonitoredDirectoryChange(notification: Notification) {
        if let userInfo = notification.userInfo,
           let directoryURL = userInfo["directory"] as? URL {
            fileMonitor.stopMonitoring()
            fileMonitor = FileMonitor(directoryURL: directoryURL)
            startFileMonitoring()
        }
    }

    @objc private func handleLogDirectoryChange(notification: Notification) {
        if let userInfo = notification.userInfo,
           let directoryURL = userInfo["directory"] as? URL {
            setupAppLogger(logDirectory: directoryURL)
            AppLogger.shared.info("Log directory changed to: \(directoryURL.path)")
        }
    }

    private func setupStatusMenu() {
        statusMenu = NSMenu()

        // App name (disabled item)
        let appNameItem = NSMenuItem(title: "Screenshot Organizer \(fileMonitor.isMonitoring ? "ON" : "OFF")", action: nil, keyEquivalent: "")
        appNameItem.isEnabled = false
        statusMenu.addItem(appNameItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separator())

        // Monitoring status item
        let monitoringStatusItem = NSMenuItem(
            title: fileMonitor.isMonitoring ? "Turn off" : "Turn on",
            action: #selector(toggleMonitoring),
            keyEquivalent: ""
        )
        statusMenu.addItem(monitoringStatusItem)

        // Organize now item
        let organizeNowItem = NSMenuItem(title: "Organize now", action: #selector(organizeNow), keyEquivalent: "")
        statusMenu.addItem(organizeNowItem)

        // Settings item
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        statusMenu.addItem(settingsItem)

        // Show log item
        let showLogItem = NSMenuItem(title: "Show log", action: #selector(showLog), keyEquivalent: "l")
        statusMenu.addItem(showLogItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separator())

        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusMenu.addItem(quitItem)

        // Assign the menu to the status item
        statusItem.menu = statusMenu

        // Set up notification for organize now
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrganizeNow),
            name: Notification.Name("OrganizeNow"),
            object: nil
        )
    }

    @objc private func toggleMonitoring() {
        if fileMonitor.isMonitoring {
            stopFileMonitoring()
        } else {
            startFileMonitoring()
        }
    }

    @objc private func showSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Window.width, height: Window.height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.setFrame(NSRect(x: 0, y: 0, width: Window.width, height: Window.height), display: true)
        settingsWindow.center()
        settingsWindow.title = "Screenshot Organizer Settings"
        settingsWindow.contentView = NSHostingView(rootView: ContentView())

        let windowController = NSWindowController(window: settingsWindow)
        windowController.showWindow(nil)
        settingsWindow.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func handleOrganizeNow(notification: Notification) {
        organizeNow()
    }

    @objc private func organizeNow() {
        do {
            try fileMonitor.organizeNow()
        } catch FileMonitorError.directoryNotFound {
            showErrorAlert(title: "Directory Not Found", message: "The target directory does not exist.")
        } catch FileMonitorError.fileSystemError(let message) {
            showErrorAlert(title: "File System Error", message: "An error occurred while accessing the file system: \(message)")
        } catch FileMonitorError.invalidScreenshot {
            showErrorAlert(title: "Invalid Screenshot", message: "One or more files could not be identified as screenshots.")
        } catch FileMonitorError.moveFailed(let message) {
            showErrorAlert(title: "Move Failed", message: "Failed to move screenshot: \(message)")
        } catch FileMonitorError.permissionDenied(let message) {
            showErrorAlert(title: "Permission Error", message: message)
        } catch {
            showErrorAlert(title: "Error", message: "An unexpected error occurred: \(error.localizedDescription)")
        }
    }

    @objc private func showLog() {
        NSWorkspace.shared.open(AppLogger.shared.logFileURL)
    }

    func applicationWillTerminate(_ notification: Notification) {
        fileMonitor.stopMonitoring()
    }
}
