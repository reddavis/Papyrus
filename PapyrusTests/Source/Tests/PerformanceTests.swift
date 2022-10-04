import XCTest
@testable import Papyrus

class PerformanceTests: XCTestCase {
    private let fileManager = FileManager.default
    private var store: PapyrusStore!
    private var directory: URL!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        let temporaryDirectoryURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        
        self.directory = temporaryDirectoryURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        
        self.store = PapyrusStore(url: self.directory)
        self.store.logLevel = .off
    }

    // MARK: Tests
    
    func testSimpleObjectWrites() throws {
        let objects = (0..<2000).map { _ in
            ExampleB(id: UUID().uuidString)
        }
        
        self.measure {
            let group = DispatchGroup()
            group.enter()
            
            Task {
                await self.store.save(objects: objects)
                group.leave()
            }
            
            group.wait()
        }
    }
    
    func testComplexObjectWrites() throws {
        let objects = (0..<2000).map { _ in
            ExampleA(
                id: UUID().uuidString,
                test: ExampleB(id: UUID().uuidString)
            )
        }
        
        self.measure {
            let group = DispatchGroup()
            group.enter()
            
            Task {
                await self.store.save(objects: objects)
                group.leave()
            }
            
            group.wait()
        }
    }
    

    func testObjectCreationAndDeletionDeletion() async {
        let objects = (0..<2000).map { _ in
            ExampleB(id: UUID().uuidString)
        }
        
        self.measure {
            let group = DispatchGroup()
            group.enter()
            
            Task {
                // There is no way to run setup code for each measurement iteration(?)
                // Therefore we will also need to create the objects in the measure loop.
                await self.store.save(objects: objects)
                await self.store.delete(objects: objects)
                group.leave()
            }
            
            group.wait()
        }
    }
}
