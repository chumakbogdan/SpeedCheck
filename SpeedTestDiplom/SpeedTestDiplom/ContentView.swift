import SwiftUI
import Combine
import CoreData

struct ContentView: View {
    // MARK: - Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TestResult.date, ascending: false)],
        animation: .default
    )
    private var results: FetchedResults<TestResult>

    // MARK: - ViewModel
    @StateObject private var viewModel = SpeedTestViewModel()

    // MARK: - UI State
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isMeasuring = false
    @State private var selectedServer: String = "Auto"
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var selectedTheme: String = "System"
    @State private var useSystemTheme: Bool = true
    @State private var showLiveTest: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.connectionType == "WiFi" ? "wifi" : "cellularbars")
                            .foregroundColor(.green)

                        Text(viewModel.connectionType)
                            .font(.subheadline)

                        if viewModel.connectionType == "Cellular" {
                            Text(viewModel.currentMetrics.cellularTechnology)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Text("No internet connection")
                        .font(.subheadline)
                }
                Spacer()


                // MARK: - Start button
                Button(action: {
                    if !viewModel.isRunning {
                        viewModel.prepareTestWithLocationCheck()
                    }
                }) {
                    Text("Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 50)
                        .background(viewModel.isConnected ? Color.blue : Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(.horizontal, 120)
                }
                .disabled(!viewModel.isConnected)
                    

                Spacer()

                // MARK: - Server & Units info
                HStack(spacing: 4) {
                    Text("Server: \(selectedServer)")
                        .font(.subheadline)
                    Text("Units: \(viewModel.selectedSpeedUnit.rawValue)")
                        .font(.subheadline)
                }
                .foregroundColor(.gray)
                .padding(.top, 10)
                .frame(maxWidth: .infinity)

                NavigationLink(destination: {
                    if let lastResult = results.first {
                        TestDetailView(result: lastResult)
                    }
                }) {
                    if let lastResult = results.first {
                        ResultCardView(result: lastResult)
                    }
                }
            }
            .animation(.easeInOut, value: isMeasuring)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("SpeedCheck")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showSettings = true }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        Button(action: { showHistory = true }) {
                            Label("History", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "line.horizontal.3")
                            .font(.title3)
                            .imageScale(.medium)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            cancellables.removeAll()
            viewModel.updateNetworkInfo()
            viewModel.$state
                .receive(on: DispatchQueue.main)
                .sink { state in
                    switch state {
                    case .measuringPing, .measuringDownload, .measuringUpload:
                        isMeasuring = true
                    case .completed, .cancelled, .error:
                        isMeasuring = false
                    default:
                        break
                    }
                }
                .store(in: &cancellables)
        }
        .onChange(of: viewModel.locationPermissionState) {
            if viewModel.locationPermissionState == .decided {
                showLiveTest = true
                viewModel.startTest()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                selectedServer: $selectedServer,
                selectedTheme: $selectedTheme,
                useSystemTheme: $useSystemTheme
            ).environmentObject(viewModel)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
        .fullScreenCover(isPresented: $showLiveTest){
            LiveTestView(viewModel: viewModel)
                .preferredColorScheme(
                    useSystemTheme ? nil : (selectedTheme == "Light" ? .light : .dark)
                )
        }
        .preferredColorScheme(
            useSystemTheme
            ? nil
            : (selectedTheme == "Light" ? .light : .dark)
        )
        .alert("Use Cellular Data?", isPresented: $viewModel.showCellularPermissionAlert) {
            Button("Allow", role: .none) { viewModel.allowCellularAndContinue() }
            Button("Don’t Allow", role: .cancel) { viewModel.denyCellularPermission() }
        } message: {
            Text("The app wants to use your cellular connection for measuring speed.")
        }
        .alert("No Internet Connection", isPresented: $viewModel.showConnectivityAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.connectivityAlertMessage)
        }
    }
}

#Preview {
    ContentView()
}
