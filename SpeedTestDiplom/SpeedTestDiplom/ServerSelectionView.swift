import SwiftUI
import SpeedcheckerSDK

struct ServerSelectionView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedServer: String
    
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    @State private var tempServer: String = ""
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Automatic Selection (Best Server)")
                    Spacer()
                    if selectedServer == "Auto" {
                        Image(systemName: "checkmark").foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    tempServer = "Auto"
                    viewModel.selectedServerName = "Auto"
                }
            }
            
            //MARK: - Enabling server choosing in future
            Section(header: Text("Manual Selection")) {
                if viewModel.availableServers.isEmpty {
                    Text("Server list unavailable in this version.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.availableServers, id: \.ID) { server in
                       // List of available servers
                    }
                }
            }
        }
        .navigationTitle("Select Server")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    selectedServer = tempServer
                    dismiss()
                }
                .disabled(tempServer.isEmpty)
            }
        }
        .onAppear {
            tempServer = selectedServer
        }
    }
}

#Preview {
    ServerSelectionView(selectedServer: .constant("Warsaw Server"))
        .environmentObject(SpeedTestViewModel())
}
