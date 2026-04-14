import Foundation

enum SpeedUnit: String, CaseIterable, Identifiable {
    case mbps = "Mbps"
    case mbs = "MB/s"
    case kbps = "Kbps"
    
    var id: String { rawValue }
    
    func convert(speedInMbps: Double) -> Double {
        switch self {
        case .mbps: return speedInMbps
        case .mbs: return speedInMbps / 8.0
        case .kbps: return speedInMbps * 1000.0
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
}
