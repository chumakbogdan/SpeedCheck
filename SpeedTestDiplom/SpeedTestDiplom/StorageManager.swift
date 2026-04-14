import CoreData
import SwiftUI

final class StorageManager {
    static let shared = StorageManager()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func saveResult(metrics: TestMetrics, unit: SpeedUnit) {
        let testResult = TestResult(context: context)
        testResult.id = UUID()
        testResult.date = Date()
        
        testResult.ping = metrics.pingMs ?? 0
        testResult.jitter = Double(metrics.jitter ?? 0)
        testResult.packetLoss = metrics.packetLoss ?? 0
        
        testResult.downloadSpeed = unit.convert(speedInMbps: metrics.downloadMbps ?? 0)
        testResult.uploadSpeed = unit.convert(speedInMbps: metrics.uploadMbps ?? 0)
        testResult.unit = unit.rawValue
        
        testResult.downloadedMb = metrics.downloadedMb ?? 0
        testResult.uploadedMb = metrics.uploadedMb ?? 0
        
        testResult.networkType = metrics.networkType
        testResult.ipAddress = metrics.ipAddress
        testResult.ispName = metrics.ispName
        testResult.city = metrics.city
        
        if let lat = metrics.latitude, let lon = metrics.longitude {
            testResult.latitude = lat
            testResult.longitude = lon
        }
        
        testResult.serverCity = metrics.serverCity
        testResult.serverCountry = metrics.serverCountry
        testResult.serverHost = metrics.serverHost
        
        do {
            try context.save()
            print("Successfully saved test result.")
        } catch {
            print("Failed to save test result: \(error.localizedDescription)")
        }
    }
    
    func deleteAllHistory(results: FetchedResults<TestResult>) {
        withAnimation{
            results.forEach(context.delete)
            save()
        }
    }
    
    func deleteResult(at offsets: IndexSet, in results: FetchedResults<TestResult>) {
        withAnimation{
            offsets.map { results[$0] }.forEach(context.delete)
            save()
        }
    }
    
    func delete(result: TestResult) {
        context.delete(result)
        save()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context after delete: \(error.localizedDescription)")
        }
    }
}
