import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var fileMonitor: FileMonitor!
    private var statusMenu: NSMenu!

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
            ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.path
        let monitoredDirectoryURL = URL(fileURLWithPath: monitoredDirectoryPath)

        fileMonitor = FileMonitor(directoryURL: monitoredDirectoryURL)
        fileMonitor.startMonitoring()

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

    @objc private func handleDirectoryChange(notification: Notification) {
        if let userInfo = notification.userInfo,
           let directoryURL = userInfo["directory"] as? URL {
            fileMonitor.stopMonitoring()
            fileMonitor = FileMonitor(directoryURL: directoryURL)
            fileMonitor.startMonitoring()
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
