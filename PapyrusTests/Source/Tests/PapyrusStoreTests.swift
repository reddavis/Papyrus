import Combine
import XCTest
@testable import Papyrus


final class PapyrusStoreTests: XCTestCase
{
    // Private
    private let fileManager = FileManager.default
    private var store: PapyrusStore!
    private var storeDirectory: URL!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: Setup
    
    override func setUpWithError() throws
    {
        self.cancellables = []
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        self.store = PapyrusStore(url: self.storeDirectory)
    }
    
    // MARK: Saving
    
    func testDirectoriesAndFilesAreCreated() async throws
    {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        await self.store.save(objectB)
        
        // Object B's type directory created
        let objectTypeBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectTypeBDirectory.path))
        
        // Object B's data file created
        let objectBDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB))).appendingPathComponent(idB)
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectBDataFile.path))
    }
    
    func testHasOneRelationshipDirectoriesAndFilesAreCreated() async throws
    {
        let idA = UUID().uuidString
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        let objectA = ExampleA(id: idA, test: objectB)
        await self.store.save(objectA)
        
        // Object A's type directory created
        let objectTypeADirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectA)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectTypeADirectory.path))
        
        // Object A's data file created
        let objectADataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectA))).appendingPathComponent(idA)
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectADataFile.path))
        
        // Object B's type directory created
        let objectTypeBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectTypeBDirectory.path))
        
        // Object B's data file created
        let objectBDataFile = objectTypeBDirectory.appendingPathComponent(idB)
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectBDataFile.path))
    }
    
    func testHasManyRelationshipDirectoriesAndFilesAreCreated() async throws
    {
        let childAID = UUID().uuidString
        let childA = ExampleB(id: childAID)
        
        let childBID = UUID().uuidString
        let childB = ExampleB(id: childBID)
        
        let parentID = UUID().uuidString
        let parent = ExampleC(id: parentID, children: [childA, childB])
        await self.store.save(parent)
        
        // Parent's type directory created
        let parentDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: parent)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: parentDirectory.path))
        
        // Parent's data file created
        let parentDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: parent))).appendingPathComponent(parentID)
        XCTAssertTrue(self.fileManager.fileExists(atPath: parentDataFile.path))
        
        // Child A's type directory created
        let childADirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: childA)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: childADirectory.path))
        
        // Child A's data file created
        let childADataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: childA))).appendingPathComponent(childAID)
        XCTAssertTrue(self.fileManager.fileExists(atPath: childADataFile.path))
        
        // Child B's type directory created
        let childBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: childB)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: childBDirectory.path))
        
        // Child B's data file created
        let childBDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: childB))).appendingPathComponent(childBID)
        XCTAssertTrue(self.fileManager.fileExists(atPath: childBDataFile.path))
    }
    
    func testSavingMultipleObjects() async throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        await self.store.save(objects: [objectA, objectB])
        
        XCTAssertNotNil(self.store.object(id: idA, of: ExampleB.self))
        XCTAssertNotNil(self.store.object(id: idB, of: ExampleB.self))
    }
    
    func testUpdatesReceivedOnSaving() throws
    {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 2
        
        self.store.objects(type: ExampleB.self)
            .publisher()
            .subscribe(on: DispatchQueue.global())
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        Task { await self.store.save(ExampleB(id: UUID().uuidString)) }
        self.waitForExpectations(timeout: 2.0)
    }
    
    // MARK: Fetching
    
    func testFetchingObjectByID() async throws
    {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        await self.store.save(objectB)
        
        let fetchedObject: ExampleB = try await self.store.object(id: idB).execute()
        XCTAssertEqual(fetchedObject.id, objectB.id)
    }
    
    // MARK: Deleting
    
    func testDeletingObject() async throws
    {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        await self.store.save(object)
        
        let fetchedObject = try await self.store.object(id: id, of: ExampleB.self).execute()
        await self.store.delete(fetchedObject)
        
        do
        {
            _ = try await self.store.object(id: id, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        }
        catch { }
    }
    
    func testDeletingObjects() async throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        await self.store.save(objectA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        await self.store.save(objectB)
        
        let fetchedObjectA: ExampleB = try await self.store.object(id: idA).execute()
        let fetchedObjectB: ExampleB = try await self.store.object(id: idB).execute()
        await self.store.delete(objects: [fetchedObjectA, fetchedObjectB])
        
        do
        {
            _ = try await self.store.object(id: idA, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        }
        catch { }
        
        do
        {
            _ = try await self.store.object(id: idB, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        }
        catch { }
    }
    
    func testUpdatesReceivedOnDeleting() throws
    {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 3
        
        self.store.objects(type: ExampleB.self)
            .publisher()
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        let object = ExampleB(id: UUID().uuidString)
        Task {
            await self.store.save(object)
            await self.store.delete(object)
        }
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    // MARK: Merging
    
    func testMerging() async throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        await self.store.save(objects: [objectA, objectB, objectC])
        await self.store.merge(with: [objectA, objectB])
        
        XCTAssertNoThrow { try await self.store.object(id: idA, of: ExampleB.self).execute() }
        XCTAssertNoThrow { try await self.store.object(id: idB, of: ExampleB.self).execute() }
        
        do
        {
            _ = try await self.store.object(id: idC, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        }
        catch { }
        
        let exampleBs = await self.store.objects(type: ExampleB.self).execute()
        XCTAssertEqual(2, exampleBs.count)
    }
    
    func testMergingIntoSubset() async throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        let idD = UUID().uuidString
        let objectD = ExampleB(id: idD)
        
        await self.store.save(objects: [objectA, objectB, objectC, objectD])
        await self.store.merge(
            objects: [objectA, objectB],
            into: { [idA, idB, idC].contains($0.id) }
        )
        
        XCTAssertNoThrow { try await self.store.object(id: idA, of: ExampleB.self).execute() }
        XCTAssertNoThrow { try await self.store.object(id: idB, of: ExampleB.self).execute() }
        XCTAssertNoThrow { try await self.store.object(id: idD, of: ExampleB.self).execute() }
        
        do
        {
            _ = try await self.store.object(id: idC, of: ExampleB.self).execute()
            XCTFail("Object not deleted")
        }
        catch { }
        
        let exampleBs = await self.store.objects(type: ExampleB.self).execute()
        XCTAssertEqual(3, exampleBs.count)
    }
    
    // MARK: Migrations
    
    func testMigration() async throws
    {
        let idA = UUID().uuidString
        let idB = UUID().uuidString
        let idC = UUID().uuidString
        
        let oldObjects = [idA, idB, idC].map { ExampleB.init(id: $0) }
        await self.store.save(objects: oldObjects)
        
        var exampleBResults = await self.store.objects(type: ExampleB.self).execute()
        XCTAssertEqual(3, exampleBResults.count)
        
        let migration = Migration<ExampleB, ExampleD> { oldObject in
            ExampleD(
                id: oldObject.id,
                value: oldObject.value,
                integerValue: oldObject.integerValue
            )
        }
        await self.store.register(migration: migration)
        
        // Validate objects are migrated
        exampleBResults = await self.store.objects(type: ExampleB.self).execute()
        XCTAssertEqual(0, exampleBResults.count)
        
        let exampleDResults = await self.store.objects(type: ExampleD.self).execute()
        XCTAssertEqual(3, exampleDResults.count)
        
        // Validate information migrated
        for oldObject in oldObjects
        {
            let object: ExampleD = try await self.store.object(id: oldObject.id).execute()
            XCTAssertEqual(oldObject.integerValue, object.integerValue)
            XCTAssertEqual(oldObject.value, object.value)
        }
    }
}
