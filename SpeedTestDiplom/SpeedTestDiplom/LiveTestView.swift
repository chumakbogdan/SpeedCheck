import SwiftUI
import SpeedcheckerSDK
import CoreData

struct LiveTestView: View {
    @Environment(\.dismiss) var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TestResult.date, ascending: false)],
        animation: .default
    )
    private var results: FetchedResults<TestResult>

    @ObservedObject var viewModel: SpeedTestViewModel

    @State private var showCancelAlert = false
    @State private var frozenDownload: Double? = nil
    @State private var frozenUpload: Double? = nil
    

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    HStack {
                        Text("Test Info")
                            .font(.title)
                            .fontWeight(.bold)
                            .accessibilityIdentifier("LiveTestTitle")
                        Spacer()
                        Text("Server: \(serverDisplay)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(stateTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if viewModel.isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Ping", systemImage: "waveform.path.ecg")
                            .font(.headline)
                        Spacer()
                        Text(pingDisplay)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    if let jitter = viewModel.currentMetrics.jitter {
                        Text("Jitter: \(jitter) ms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.horizontal)

                if viewModel.state != .measuringPing{
                    sectionView(
                        title: "Download",
                        systemImage: "arrow.down.circle",
                        currentValue: viewModel.displayDownloadSpeed,
                        frozenValue: $frozenDownload,
                        unit: viewModel.selectedSpeedUnit
                    )
                }

                if viewModel.state != .measuringPing && viewModel.state != .measuringDownload{
                    sectionView(
                        title: "Upload",
                        systemImage: "arrow.up.circle",
                        currentValue: viewModel.displayUploadSpeed,
                        frozenValue: $frozenUpload,
                        unit: viewModel.selectedSpeedUnit
                    )
                }

                Spacer()

                HStack {
                    Text("Data used:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Downloaded: \(downloadedDisplay)\nUploaded:      \(uploadedDisplay)")
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 28)

                if viewModel.state == .completed{
                    HStack(spacing: 16) {
                        Button(action: {
                            frozenDownload = nil
                            frozenUpload = nil
                            viewModel.resetLiveStateForRetry()
                            viewModel.startTest()
                        }) {
                            Label("Run Again", systemImage: "arrow.clockwise.circle")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.9))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        NavigationLink(destination: {
                            if let lastResult = results.first {
                                TestDetailView(result: lastResult)
                                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                            }
                        }) {
                            Label("Details", systemImage: "list.bullet.rectangle")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.top)
            .navigationBarBackButtonHidden(true)
            .animation(.easeInOut(duration: 1.0), value: viewModel.state)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if viewModel.isRunning {
                            showCancelAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Cancel test?", isPresented: $showCancelAlert){
                Button("Abort Test", role: .destructive){
                    viewModel.stopTest()
                    dismiss()
                }
                Button("Continue", role: .cancel){}
            } message: {
                Text("Are you sure you want to cancel the running test?")
            }
            .onReceive(viewModel.$state) { newState in
                switch newState {
                case .measuringDownload:
                    frozenUpload = nil
                case .measuringUpload:
                    if frozenDownload == nil {
                        frozenDownload = viewModel.displayDownloadSpeed
                    }
                case .completed:
                    frozenDownload = frozenDownload ?? viewModel.displayDownloadSpeed
                    frozenUpload = frozenUpload ?? viewModel.displayUploadSpeed
                case .cancelled:
                    frozenDownload = nil
                    frozenUpload = nil
                default:
                    break
                }
            }
            .onReceive(viewModel.$currentMetrics) { _ in
                switch viewModel.state {
                case .measuringUpload:
                    if frozenDownload == nil {
                        frozenDownload = viewModel.displayDownloadSpeed
                    }
                case .completed:
                    if frozenUpload == nil {
                        frozenUpload = viewModel.displayUploadSpeed
                    }
                default:
                    break
                }
            }
        }
    }

    private var stateTitle: String {
        switch viewModel.state {
        case .idle: return "Idle"
        case .checkingConnection: return "Checking connection"
        case .needsCellularPermission: return "Waiting for cellular permission"
        case .measuringPing: return "Measuring ping..."
        case .measuringDownload: return "Measuring download..."
        case .measuringUpload: return "Measuring upload..."
        case .completed: return "Test completed"
        case .cancelled: return "Cancelled"
        case .error(let s): return "Error: \(s)"
        }
    }

    private func sectionView(title: String, systemImage: String, currentValue: Double, frozenValue: Binding<Double?>, unit: SpeedUnit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Spacer()
                if let frozen = frozenValue.wrappedValue {
                    Text("\(frozen, specifier: displayFormat(for: unit)) \(unit.rawValue)")
                        .font(.title3)
                        .fontWeight(.semibold)
                } else {
                    if viewModel.isRunning && (viewModel.state == .measuringDownload && title == "Download" || viewModel.state == .measuringUpload && title == "Upload") {
                        Text("\(currentValue, specifier: displayFormat(for: unit)) \(unit.rawValue)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    } else {
                        Text("\(currentValue, specifier: displayFormat(for: unit)) \(unit.rawValue)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .opacity(viewModel.isRunning ? 0.9 : 1.0)
                    }
                }
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 10)
                    .overlay(
                        GeometryReader { geo in
                            let width = geo.size.width
                            let progress =
                            title == "Download" ? viewModel.currentMetrics.downloadProgress :
                            title == "Upload"   ? viewModel.currentMetrics.uploadProgress : 0

                            RoundedRectangle(cornerRadius: 4)
                                .frame(width: width * progress, height: 10)
                                .foregroundColor(title == "Download" ? .blue : .purple)
                                .animation(.linear(duration: 0.2), value: progress)
                        }
                    )
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var serverDisplay: String{
        if let server = viewModel.currentMetrics.serverCity{
            return "\(server)"
        } else {
            return "Auto"
        }
    }

    private var pingDisplay: String {
        if let ping = viewModel.currentMetrics.pingMs {
            return "\(Int(ping)) ms"
        } else {
            return "-- ms"
        }
    }

    private var downloadedDisplay: String {
        if let d = viewModel.currentMetrics.downloadedMb {
            return String(format: "%.2f MB", d)
        } else {
            return "-- MB"
        }
    }

    private var uploadedDisplay: String {
        if let u = viewModel.currentMetrics.uploadedMb {
            return String(format: "%.2f MB", u)
        } else {
            return "-- MB"
        }
    }

    private func displayFormat(for unit: SpeedUnit) -> String {
        if unit == .kbps {
            return "%.0f"
        }
        if unit == .mbs {
            return "%.2f"
        }
        return "%.2f"
    }
}

struct LiveTestView_Previews: PreviewProvider {
    static var previews: some View {
        LiveTestView(viewModel: SpeedTestViewModel())
    }
}
