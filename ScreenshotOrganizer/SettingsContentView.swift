import SwiftUI
import KeyboardShortcuts

struct SettingsContentView: View {
    @AppStorage(SettingsKey.monitoredDirectory) private var monitoredDirectory: String = SettingsDefault.monitoredDirectory
    @AppStorage(SettingsKey.logDirectory) private var logDirectory: String = SettingsDefault.logDirectory
    @AppStorage(SettingsKey.launchAtLogin) private var launchAtLogin: Bool = SettingsDefault.launchAtLogin
    @State private var isDirectoryPickerShown = false
    @State private var isLogDirectoryPickerShown = false
    @State private var showConfirmationDialog = false
    @State private var selectedDirectory: URL?
    @State private var selectedLogDirectory: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image("icon")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .cornerRadius(8)

                Text("Screenshot Organizer")
                    .font(.headline)
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Monitored folder:")
                    .font(.subheadline)

                HStack {
                    Text(monitoredDirectory)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Change") {
                        isDirectoryPickerShown = true
                    }
                    .fileImporter(
                        isPresented: $isDirectoryPickerShown,
                        allowedContentTypes: [.folder],
                        onCompletion: handleDirectorySelection
                    )
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(4)

                Text(monitoredDirectory)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Log folder:")
                    .font(.subheadline)

                HStack {
                    Text(logDirectory)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Change") {
                        isLogDirectoryPickerShown = true
                    }
                    .fileImporter(
                        isPresented: $isLogDirectoryPickerShown,
                        allowedContentTypes: [.folder],
                        onCompletion: handleLogDirectorySelection
                    )
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(4)

                Text(logDirectory)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                Text("Keyboard Shortcuts:")
                    .font(.subheadline)
                    .padding(.top, 4)

                HStack {
                    Text("Open Screenshots Folder:")
                        .frame(width: 200, alignment: .leading)
                    KeyboardShortcuts.Recorder(for: .openScreenshotsFolder)
                }

                HStack {
                    Text("Open Screen Recordings Folder:")
                        .frame(width: 200, alignment: .leading)
                    KeyboardShortcuts.Recorder(for: .openScreenRecordingsFolder)
                }
            }
            .padding(.top, 12)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .alert("Organize folder now?", isPresented: $showConfirmationDialog) {
            Button("Yes") {
                NotificationCenter.default.post(
                    name: Notification.Name("OrganizeNow"),
                    object: nil
                )
            }
            Button("No", role: .cancel) {
            }
        } message: {
            Text("Would you like to organize the selected folder now?")
        }
    }

    private func handleDirectorySelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if url.startAccessingSecurityScopedResource() {
                monitoredDirectory = url.path
                showConfirmationDialog = true
                NotificationCenter.default.post(
                    name: Notification.Name("MonitoredDirectoryChanged"),
                    object: nil,
                    userInfo: ["directory": url]
                )
                url.stopAccessingSecurityScopedResource()
            }
        case .failure(let error):
            AppLogger.shared.error("Directory selection failed: \(error)")
        }
    }

    private func handleLogDirectorySelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if url.startAccessingSecurityScopedResource() {
                logDirectory = url.path
                NotificationCenter.default.post(
                    name: Notification.Name("LogDirectoryChanged"),
                    object: nil,
                    userInfo: ["directory": url]
                )
                url.stopAccessingSecurityScopedResource()
            }
        case .failure(let error):
            AppLogger.shared.error("Log directory selection failed: \(error)")
        }
    }
}
