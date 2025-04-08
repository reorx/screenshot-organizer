import SwiftUI

struct ContentView: View {
    @AppStorage("monitoredDirectory") private var monitoredDirectory: String = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.path
    @AppStorage("isMonitoringEnabled") private var isMonitoringEnabled: Bool = true
    @State private var isDirectoryPickerShown = false

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

            Toggle("Enable monitoring on app start", isOn: $isMonitoringEnabled)
                .padding(.top, 8)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 300)
    }

    private func handleDirectorySelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if url.startAccessingSecurityScopedResource() {
                monitoredDirectory = url.path

                // Notify the FileMonitor to update the monitored directory
                NotificationCenter.default.post(
                    name: Notification.Name("MonitoredDirectoryChanged"),
                    object: nil,
                    userInfo: ["directory": url]
                )

                url.stopAccessingSecurityScopedResource()
            }
        case .failure(let error):
            print("Directory selection failed: \(error)")
        }
    }
}
