import SwiftUI

struct ContentView: View {
    @AppStorage("monitoredDirectory") private var monitoredDirectory: String = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.path
    @AppStorage("enableMonitoringOnStart") private var enableMonitoringOnStart: Bool = true
    @State private var isDirectoryPickerShown = false
    @State private var showConfirmationDialog = false
    @State private var selectedDirectory: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screenshot Organizer")
                .font(.headline)
                .padding(.bottom, 8)

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

            Toggle("Monitor directory on app start", isOn: $enableMonitoringOnStart)
                .padding(.top, 8)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .alert("Organize folder now?", isPresented: $showConfirmationDialog) {
            Button("Yes") {
                if let url = selectedDirectory {
                    monitoredDirectory = url.path
                    NotificationCenter.default.post(
                        name: Notification.Name("MonitoredDirectoryChanged"),
                        object: nil,
                        userInfo: ["directory": url]
                    )
                    NotificationCenter.default.post(
                        name: Notification.Name("OrganizeNow"),
                        object: nil,
                        userInfo: ["directory": url]
                    )
                }
            }
            Button("No", role: .cancel) {
                if let url = selectedDirectory {
                    monitoredDirectory = url.path
                    NotificationCenter.default.post(
                        name: Notification.Name("MonitoredDirectoryChanged"),
                        object: nil,
                        userInfo: ["directory": url]
                    )
                }
            }
        } message: {
            Text("Would you like to organize the selected folder now?")
        }
    }

    private func handleDirectorySelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if url.startAccessingSecurityScopedResource() {
                selectedDirectory = url
                showConfirmationDialog = true
                url.stopAccessingSecurityScopedResource()
            }
        case .failure(let error):
            print("Directory selection failed: \(error)")
        }
    }
}
