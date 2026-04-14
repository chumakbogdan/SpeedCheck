import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "SpeedTestDiplom")
        container.loadPersistentStores { _, error in
            if let error = error as NSError?{
                fatalError("Unresolved CoreData error: \(error)")
            }
        }
    }
}
