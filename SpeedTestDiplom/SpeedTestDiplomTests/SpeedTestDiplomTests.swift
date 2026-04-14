import Testing
import CoreData
import XCTest
@testable import SpeedTestDiplom

final class SpeedUnitTests: XCTestCase {
    func testMbpsConversion() {
        let value = SpeedUnit.mbps.convert(speedInMbps: 80)
        XCTAssertEqual(value, 80)
    }

    func testMBpsConversion() {
        let value = SpeedUnit.mbs.convert(speedInMbps: 80)
        XCTAssertEqual(value, 10)
    }

    func testKbpsConversion() {
        let value = SpeedUnit.kbps.convert(speedInMbps: 1.5)
        XCTAssertEqual(value, 1500)
    }

    func testAllUnitsAvailable() {
        XCTAssertEqual(SpeedUnit.allCases.count, 3)
    }
}

@MainActor
final class SpeedTestStateTests: XCTestCase{
    func testInitialStateIsIdle() {
        let vm = SpeedTestViewModel()
        XCTAssertEqual(vm.state, .idle)
    }

    func testCancelledStateEquality() {
        XCTAssertEqual(SpeedTestState.cancelled, SpeedTestState.cancelled)
    }

    func testErrorStateNotEqual() {
        let a = SpeedTestState.error("A")
        let b = SpeedTestState.error("B")
        XCTAssertNotEqual(a, b)
    }
}


final class DisplaySpeedComputationTests: XCTestCase {

    func testDisplayDownloadSpeedUsesSelectedUnit() {
        let vm = SpeedTestViewModel()
        vm.selectedSpeedUnit = .mbs
        vm.currentMetrics.downloadMbps = 80

        XCTAssertEqual(vm.displayDownloadSpeed, 10)
    }

    func testDisplayUploadSpeedZeroWhenNil() {
        let vm = SpeedTestViewModel()
        XCTAssertEqual(vm.displayUploadSpeed, 0)
    }
}


final class StorageManagerTests: XCTestCase {
    
    func testSavingTestResultCreatesEntity() {
        let metrics = TestMetrics(
            pingMs: 20,
            downloadMbps: 100,
            uploadMbps: 40,
            city: "Warsaw"
        )

        StorageManager.shared.saveResult(metrics: metrics, unit: .mbps)

        let fetch = NSFetchRequest<TestResult>(entityName: "TestResult")
        let results = try? PersistenceController.shared.container.viewContext.fetch(fetch)

        XCTAssertNotNil(results)
        XCTAssertTrue(results!.count > 0)
    }
}

@MainActor
final class SpeedTestLifecycleTests: XCTestCase {

    func testStartTestSetsRunningState() {
        let vm = SpeedTestViewModel()
        vm.startTest()

        XCTAssertTrue(vm.isRunning)
        XCTAssertEqual(vm.state, .measuringPing)
    }

    func testStopTestCancelsAndResets() {
        let vm = SpeedTestViewModel()
        vm.startTest()
        XCTAssertTrue(vm.isRunning)
        XCTAssertEqual(vm.state, .measuringPing)
        
        DispatchQueue.main.async {
            vm.stopTest()

            XCTAssertFalse(vm.isRunning)
            XCTAssertEqual(vm.state, .cancelled)
            XCTAssertNil(vm.currentMetrics.downloadMbps)
        }
    }
}
