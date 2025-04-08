import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var fileMonitor: FileMonitor!
    private var statusMenu: NSMenu!
    @AppStorage("isMonitoringEnabled") private var isMonitoringEnabled: Bool = true

    private func findDesktopDirectory() -> URL? {
        // First try the regular Desktop directory
        let regularDesktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        if FileManager.default.fileExists(atPath: regularDesktop.path) {
            return regularDesktop
        }
        return nil
    }

    private func startFileMonitoring() {
        do {
            try fileMonitor.startMonitoring()
        } catch {
            showDirectoryNotFoundAlert(error: error)
            isMonitoringEnabled = false
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Use a simple template image instead of a system symbol
            let image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Screenshot Organizer")
            image?.isTemplate = true // Ensures proper appearance in menubar
            button.image = image
        }

        // Initialize the file monitor with the saved or default directory
        let monitoredDirectoryPath = UserDefaults.standard.string(forKey: "monitoredDirectory")
            ?? findDesktopDirectory()?.path ?? ""
        let monitoredDirectoryURL = URL(fileURLWithPath: monitoredDirectoryPath)

        fileMonitor = FileMonitor(directoryURL: monitoredDirectoryURL)

        // Check if directory exists and start monitoring if enabled
        if isMonitoringEnabled {
            startFileMonitoring()
        }

        // Set up notification for directory changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDirectoryChange),
            name: Notification.Name("MonitoredDirectoryChanged"),
            object: nil
        )

        // Set up the menu for the status item
        setupStatusMenu()

        // Print confirmation to console
        print("Screenshot Organizer is running in the menubar")
    }

    private func showDirectoryNotFoundAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Directory Not Found"
        alert.informativeText = "Could not monitor the directory.  Monitoring has been disabled. Error: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func handleDirectoryChange(notification: Notification) {
        if let userInfo = notification.userInfo,
           let directoryURL = userInfo["directory"] as? URL {
            fileMonitor.stopMonitoring()
            fileMonitor = FileMonitor(directoryURL: directoryURL)
            if isMonitoringEnabled {
                startFileMonitoring()
            }
        }
    }

    private func setupStatusMenu() {
        statusMenu = NSMenu()

        // App name (disabled item)
        let appNameItem = NSMenuItem(title: "Screenshot Organizer", action: nil, keyEquivalent: "")
        appNameItem.isEnabled = false
        statusMenu.addItem(appNameItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separator())

        // Monitoring status item
        let monitoringStatusItem = NSMenuItem(title: "Monitoring: \(isMonitoringEnabled ? "Enabled" : "Disabled")", action: #selector(toggleMonitoring), keyEquivalent: "")
        statusMenu.addItem(monitoringStatusItem)

        // Settings item
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        statusMenu.addItem(settingsItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separator())

        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusMenu.addItem(quitItem)

        // Assign the menu to the status item
        statusItem.menu = statusMenu
    }

    @objc private func toggleMonitoring() {
        isMonitoringEnabled.toggle()

        if isMonitoringEnabled {
            startFileMonitoring()
        } else {
            fileMonitor.stopMonitoring()
        }

        // Update menu item title
        if let monitoringItem = statusMenu.item(withTitle: "Monitoring: \(!isMonitoringEnabled ? "Enabled" : "Disabled")") {
            monitoringItem.title = "Monitoring: \(isMonitoringEnabled ? "Enabled" : "Disabled")"
        }
    }

    @objc private func showSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.center()
        settingsWindow.title = "Screenshot Organizer Settings"
        settingsWindow.contentView = NSHostingView(rootView: ContentView())

        let windowController = NSWindowController(window: settingsWindow)
        windowController.showWindow(nil)
        settingsWindow.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        fileMonitor.stopMonitoring()
    }
}
