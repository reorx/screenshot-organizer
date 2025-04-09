import SwiftUI
import Foundation

struct ContentView: View {
    @AppStorage("monitoredDirectory") private var monitoredDirectory: String = ""
    @AppStorage("logDirectory") private var logDirectory: String = ""
    @State private var isSelectingDirectory = false
    @State private var isSelectingLogDirectory = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Screenshot Organizer Settings")
                .font(.headline)
                .padding(.top)

            VStack(alignment: .leading, spacing: 10) {
                Text("Monitored Directory")
                    .font(.subheadline)

                HStack {
                    TextField("Directory path", text: $monitoredDirectory)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Select") {
                        isSelectingDirectory = true
                    }
                }
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("Log Directory")
                    .font(.subheadline)

                HStack {
                    TextField("Log directory path", text: $logDirectory)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Select") {
                        isSelectingLogDirectory = true
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(width: 400, height: 300)
        .fileImporter(
            isPresented: $isSelectingDirectory,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    monitoredDirectory = url.path
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
        .fileImporter(
            isPresented: $isSelectingLogDirectory,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    logDirectory = url.path
                    AppLogger.shared.setup(logDirectory: url)
                }
            case .failure(let error):
                print("Error selecting log directory: \(error)")
            }
        }
    }
}
