import XCTest
@testable import Papyrus

final class PapyrusStoreTests: XCTestCase {
    private let fileManager = FileManager.default
    private var store: PapyrusStore!
    private var directory: URL!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.directory = URL.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        self.store = PapyrusStore(url: self.directory)
    }
    
    override func tearDown() {
        try? self.fileManager.removeItem(at: self.directory)
    }
    
    // MARK: Reseting
    
    func test_reset() async throws {
        let model = ExampleB(id: "1")
        try await self.store.save(model)
        
        var count = try self.store.objects(type: ExampleB.self).execute().count
        XCTAssertEqual(count, 1)
        XCTAssertNoThrow(try self.store.reset())
        count = try self.store.objects(type: ExampleB.self).execute().count
        XCTAssertEqual(count, 0)
    }
    
    // MARK: Saving
    
    func test_directoriesAndFilesAreCreated() async throws {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        try await self.store.save(objectB)
        
        // Object B's type directory created
        let objectTypeBDirectory = self.directory.appendingPathComponent(
            String(describing: type(of: objectB))
        )
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectTypeBDirectory.path))
        
        // Object B's data file created
        let objectBDataFile = self.directory.appendingPathComponent(
            String(describing: type(of: objectB))
        ).appendingPathComponent(idB)
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectBDataFile.path))
    }
    
    func test_savingMultipleObjects() async throws {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        try await self.store.save(objects: [objectA, objectB])
        
        XCTAssertNotNil(self.store.object(id: idA, of: ExampleB.self))
        XCTAssertNotNil(self.store.object(id: idB, of: ExampleB.self))
    }
    
    func test_updatesReceivedOnSaving() async throws {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 1

        self.store.objects(type: ExampleB.self)
            .observe()
            .sink { _ in expectation.fulfill() }

        try await self.store.save(ExampleB(id: UUID().uuidString))
        await self.fulfillment(of: [expectation], timeout: 0.2)
    }
    
    // MARK: Fetching
    
    func test_fetchingObjectByID() async throws {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        try await self.store.save(objectB)
        
        let fetchedObject: ExampleB = try self.store.object(id: idB).execute()
        XCTAssertEqual(fetchedObject.id, objectB.id)
    }
    
    func test_fetchingObjects() async throws {
        let objects = (0..<3).map { _ in
            ExampleD()
        }
        try await self.store.save(objects: objects)
        
        let fetchedObjects = try self.store.objects(type: ExampleD.self).execute()
        XCTAssertEqual(fetchedObjects.count, 3)
    }
    
    // MARK: Deleting
    
    func test_deletingObject() async throws {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        try await self.store.save(object)
        
        let fetchedObject = try self.store.object(id: id, of: ExampleB.self).execute()
        try await self.store.delete(fetchedObject)
        
        do {
            _ = try self.store.object(id: id, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        } catch { }
    }
    
    func test_deletingObjects() async throws {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        try await self.store.save(objectA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        try await self.store.save(objectB)
        
        let fetchedObjectA: ExampleB = try self.store.object(id: idA).execute()
        let fetchedObjectB: ExampleB = try self.store.object(id: idB).execute()
        try await self.store.delete(objects: [fetchedObjectA, fetchedObjectB])
        
        do {
            _ = try self.store.object(id: idA, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        } catch { }
        
        do {
            _ = try self.store.object(id: idB, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        } catch { }
    }
    
    func test_deleteAll() async throws {
        try await self.store.save(ExampleB(id: "1"))
        try await self.store.save(ExampleB(id: "2"))
        try store.deleteAll(ExampleB.self)
        
        let results = try self.store.objects(type: ExampleB.self).execute()
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: Merging
    
    func test_merge() async throws {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        try await self.store.save(objects: [objectA, objectB, objectC])
        try await self.store.merge(with: [objectA, objectB])
        
        XCTAssertNoThrow { try self.store.object(id: idA, of: ExampleB.self).execute() }
        XCTAssertNoThrow { try self.store.object(id: idB, of: ExampleB.self).execute() }
        
        do {
            _ = try self.store.object(id: idC, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        } catch { }
        
        let exampleBs = try self.store.objects(type: ExampleB.self).execute()
        XCTAssertEqual(2, exampleBs.count)
    }
    
    func test_merge_withSubset() async throws {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        let idD = UUID().uuidString
        let objectD = ExampleB(id: idD)
        
        try await self.store.save(objects: [objectA, objectB, objectC, objectD])
        try await self.store.merge(
            objects: [objectA, objectB],
            into: { [idA, idB, idC].contains($0.id) }
        )
        
        XCTAssertNoThrow { try self.store.object(id: idA, of: ExampleB.self).execute() }
        XCTAssertNoThrow { try self.store.object(id: idB, of: ExampleB.self).execute() }
        XCTAssertNoThrow { try self.store.object(id: idD, of: ExampleB.self).execute() }
        
        do {
            _ = try self.store.object(id: idC, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        } catch { }
        
        let exampleBs = try self.store.objects(type: ExampleB.self).execute()
        XCTAssertEqual(3, exampleBs.count)
    }
}
