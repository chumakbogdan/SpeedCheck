import Combine
import SwiftUI
import SpeedcheckerSDK
import CoreLocation
import Network

enum SpeedTestState: Equatable {
    case idle
    case checkingConnection
    case needsCellularPermission
    case measuringPing
    case measuringDownload
    case measuringUpload
    case completed
    case cancelled
    case error(String)
}

enum LocationPermissionState{
    case unknown
    case requesting
    case decided
}

struct TestMetrics{
    var pingMs: Double? = nil
    var downloadMbps: Double? = nil
    var uploadMbps: Double? = nil
    var city: String? = ""
    var downloadedMb: Double? = nil
    var uploadedMb: Double? = nil
    var ipAddress: String? = ""
    var ispName: String? = ""
    var jitter: Int? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var networkType: String? = ""
    var packetLoss: Double? = nil
    var serverCity: String? = ""
    var serverCountry: String? = ""
    var serverHost: String? = ""
    var downloadProgress: Double = 0
    var uploadProgress: Double = 0
    var cellularTechnology: String = ""
}

final class SpeedTestViewModel: NSObject, ObservableObject {
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    @Published var state: SpeedTestState = .idle
    @Published var currentMetrics = TestMetrics()
    
    @Published var connectionType: String = "Unknown"
    @Published var isConnected: Bool = true
    @Published var isRunning: Bool = false

    @Published var showCellularPermissionAlert: Bool = false
    @Published var showConnectivityAlert: Bool = false
    @Published var connectivityAlertMessage: String = ""
    @Published var locationPermissionState: LocationPermissionState = .unknown

    // MARK: - Configuration
    @AppStorage("hasGivenCellularPermission") var hasGivenCellularPermission: Bool = false
    @AppStorage("selectedSpeedUnit") var selectedSpeedUnit: SpeedUnit = .mbps

    // MARK: - Servers
    @Published var availableServers: [SpeedcheckerSDK.SpeedTestServer] = []
    @Published var selectedServerName: String = "Auto"

    // MARK: - Unit conversion

    var displayDownloadSpeed: Double { selectedSpeedUnit.convert(speedInMbps: currentMetrics.downloadMbps ?? 0) }
    var displayUploadSpeed: Double { selectedSpeedUnit.convert(speedInMbps: currentMetrics.uploadMbps ?? 0) }

    // MARK: - SDK & Location
    private var internetTest: InternetSpeedTest?
    private let locationManager = CLLocationManager()

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        startNetworkMonitoring()
    }
    
    private var connectionLost = false
    
    //MARK: - Netowrk Monitoring
    func startNetworkMonitoring(){
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else {return}
            DispatchQueue.main.async{
                if path.status == .satisfied{
                    self.isConnected = true
                } else {
                    self.isConnected = false
                }
                self.updateNetworkInfo()
                
                if !self.isConnected && self.isRunning{
                    self.handleConnectionLost()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    //MARK: - Network info
    func updateNetworkInfo() {
        let network = SpeedcheckerSDK.SCNetwork.currentNetwork()

        guard let active = network.getActiveConnection() else {
            connectionType = "Unknown"
            currentMetrics.cellularTechnology = ""
            return
        }

        switch active {
        case .wifi:
            connectionType = "WiFi"
            currentMetrics.cellularTechnology = ""

        case ._2G:
            connectionType = "Cellular"
            currentMetrics.cellularTechnology = "2G"

        case ._3G:
            connectionType = "Cellular"
            currentMetrics.cellularTechnology = "3G"

        case ._4G:
            connectionType = "Cellular"
            currentMetrics.cellularTechnology = "4G"

        case ._5G:
            connectionType = "Cellular"
            currentMetrics.cellularTechnology = "5G"
            
        @unknown default:
            connectionType = "Unknown"
            currentMetrics.cellularTechnology = ""
        }
    }
    
    private func handleConnectionLost() {
        guard isRunning else { return }

        connectionLost = true
        state = .cancelled
        isRunning = false

        internetTest?.forceFinish { _ in }
        internetTest = nil

        showConnectivityAlert = true
        connectivityAlertMessage = "Internet connection was lost. Test cancelled."
    }
    
    func prepareTestWithLocationCheck(){
        let status = locationManager.authorizationStatus
        switch status{
        case .notDetermined:
            locationPermissionState = .requesting
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways, .denied, .restricted:
            locationPermissionState = .decided
        @unknown default:
            locationPermissionState = .decided
        }
    }

    // MARK: - Start test
    func startTest() {
        guard !isRunning else { return }
        
        resetLiveStateForRetry()

        isRunning = true
        state = .measuringPing

        internetTest = InternetSpeedTest(delegate: self)
        internetTest?.startFreeTest { error in
            if error != .ok {
                DispatchQueue.main.async {
                    self.state = .error("SpeedTest error: \(error.userMessage)")
                    self.isRunning = false
                }
            }
        }
    }

    // MARK: - Stop test
    func stopTest() {
        guard isRunning else { return }
        internetTest?.forceFinish{ error in
            DispatchQueue.main.async {
                print("Force-finished test with status: \(error.rawValue)")
                self.state = .cancelled
                self.isRunning = false
                self.currentMetrics.pingMs = nil
                self.currentMetrics.downloadMbps = nil
                self.currentMetrics.uploadMbps = nil
                self.currentMetrics.city = ""
                self.currentMetrics.downloadedMb = nil
                self.currentMetrics.uploadedMb = nil
                self.currentMetrics.ipAddress = ""
                self.currentMetrics.ispName = ""
                self.currentMetrics.jitter = nil
                self.currentMetrics.latitude = nil
                self.currentMetrics.longitude = nil
                self.currentMetrics.networkType = ""
                self.currentMetrics.packetLoss = nil
                self.currentMetrics.serverCity = ""
                self.currentMetrics.serverCountry = ""
                self.currentMetrics.serverHost = ""
                self.internetTest = nil
            }}
    }
    
    func resetLiveStateForRetry(){
        DispatchQueue.main.async {
            self.currentMetrics.pingMs = nil
            self.currentMetrics.downloadMbps = nil
            self.currentMetrics.uploadMbps = nil
            self.currentMetrics.downloadedMb = nil
            self.currentMetrics.uploadedMb = nil
            self.currentMetrics.jitter = nil
            self.currentMetrics.packetLoss = nil
            self.currentMetrics.uploadProgress = 0
            self.currentMetrics.downloadProgress = 0
        }
    }
    
    func allowCellularAndContinue() {
        hasGivenCellularPermission = true
        showCellularPermissionAlert = false
        
        startTest()
    }

    func denyCellularPermission() {
        hasGivenCellularPermission = false
        showCellularPermissionAlert = false
        isRunning = false
        state = .idle
    }
}

// MARK: - InternetSpeedTestDelegate
extension SpeedTestViewModel: InternetSpeedTestDelegate {

    func internetTestFinish(result: SpeedTestResult) {
        DispatchQueue.main.async {
            self.currentMetrics.pingMs = Double(result.latencyInMs)
            self.currentMetrics.packetLoss = result.packetLoss?.packetLoss ?? 0.0
            self.currentMetrics.downloadMbps = result.downloadSpeed.mbps
            self.currentMetrics.uploadMbps = result.uploadSpeed.mbps
            self.currentMetrics.downloadedMb = result.downloadTransferredMb
            self.currentMetrics.uploadedMb = result.uploadTransferredMb
            self.currentMetrics.city = result.userCityName
            self.currentMetrics.latitude = result.locationLatitude
            self.currentMetrics.longitude = result.locationLongitude
            self.currentMetrics.serverCity = result.server.cityName
            self.currentMetrics.serverCountry = result.server.country
            self.currentMetrics.serverHost = result.server.domain
            self.currentMetrics.ipAddress = result.ipAddress
            self.currentMetrics.ispName = result.ispName
            self.currentMetrics.networkType = self.connectionType
            
            StorageManager.shared.saveResult(metrics: self.currentMetrics, unit: self.selectedSpeedUnit)
            
            self.state = .completed
            self.isRunning = false
        }
    }

    func internetTestDownload(progress: Double, speed: SpeedTestSpeed) {
        DispatchQueue.main.async {
            if self.state == .measuringPing{
                self.state = .measuringDownload
            }
            self.currentMetrics.downloadMbps = speed.mbps
            self.currentMetrics.downloadProgress = progress
        }
    }

    func internetTestUpload(progress: Double, speed: SpeedTestSpeed) {
        DispatchQueue.main.async {
            if self.state == .measuringDownload{
                self.state = .measuringUpload
            }
            self.currentMetrics.uploadMbps = speed.mbps
            self.currentMetrics.uploadProgress = progress
        }
    }

    func internetTestError(error: SpeedTestError) {
        DispatchQueue.main.async {
            if self.state != .cancelled{
                self.state = .error(String(error.userMessage))
            }
            self.isRunning = false
        }
    }

    func internetTestReceived(servers: [SpeedcheckerSDK.SpeedTestServer]) { }

    func internetTestSelected(server: SpeedcheckerSDK.SpeedTestServer, latency: Int, jitter: Int) {
        DispatchQueue.main.async {
            self.currentMetrics.pingMs = Double(latency)
            self.currentMetrics.jitter = jitter
            self.state = .measuringPing
            self.currentMetrics.serverCity = server.cityName
            self.currentMetrics.serverHost = server.domain
            self.currentMetrics.serverCountry = server.country
        }
    }
    
    func internetTestDownloadStart() {
        DispatchQueue.main.async {
            self.state = .measuringDownload
        }
    }
    func internetTestDownloadFinish() { }
    func internetTestUploadStart() {
        DispatchQueue.main.async {
            self.state = .measuringUpload
        }
    }
    func internetTestUploadFinish() { }
    
}

// MARK: - CLLocationManagerDelegate
extension SpeedTestViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if locationPermissionState == .requesting {
            locationPermissionState = .decided
        }
    }
}

extension SpeedTestError {
    var userMessage: String {
        switch self {
        case .invalidSettings:
            return "Invalid test configuration. Please check your settings."

        case .invalidServers:
            return "No valid test servers available. Please try again later."

        case .failed:
            return "Speed test failed. Please check your internet connection."

        case .locationUndefined:
            return "Location could not be determined. Please enable location services."

        case .cancelled:
            return "Speed test was cancelled."

        case .inProgress:
            return "A speed test is already running."

        case .notSaved:
            return "Test result could not be saved."

        case .appISPMismatch:
            return "ISP mismatch detected. Please verify your network."

        case .invalidlicenseKey:
            return "Invalid or missing license key."

        case .ok:
            return "No error."

        @unknown default:
            return "An unknown error occurred."
        }
    }
}
