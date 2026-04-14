import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: SpeedTestViewModel
    @Binding var selectedServer: String
    @AppStorage("selectedSpeedUnit") private var selectedUnits: SpeedUnit = .mbps
    @Binding var selectedTheme: String
    @Binding var useSystemTheme: Bool
    
    let themes = ["System", "Light", "Dark"]
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ServerSelectionView(selectedServer: $selectedServer).environmentObject(viewModel)) {
                    HStack {
                        Text("Server")
                        Spacer()
                        Text(selectedServer)
                            .foregroundColor(.gray)
                    }
                }
                
                Picker("Units", selection: $selectedUnits) {
                    ForEach(SpeedUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(.headline)
                        Picker("Theme", selection: $selectedTheme) {
                            Text("Light").tag("Light")
                            Text("Dark").tag("Dark")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .disabled(useSystemTheme)

                        Toggle("Use system theme", isOn: $useSystemTheme)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button{
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(
        selectedServer: .constant("Default Server"),
        selectedTheme: .constant("Light"),
        useSystemTheme: .constant(false)
    )
}
