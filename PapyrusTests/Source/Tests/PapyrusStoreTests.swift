//
//  PapyrusTests.swift
//  PapyrusTests
//
//  Created by Red Davis on 16/12/2020.
//

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
    
    func testDirectoriesAndFilesAreCreated() throws
    {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        // Object B's type directory created
        let objectTypeBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB)))
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectTypeBDirectory.path))
        
        // Object B's data file created
        let objectBDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB))).appendingPathComponent(idB)
        XCTAssertTrue(self.fileManager.fileExists(atPath: objectBDataFile.path))
    }
    
    func testHasOneRelationshipDirectoriesAndFilesAreCreated() throws
    {
        let idA = UUID().uuidString
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        let objectA = ExampleA(id: idA, test: objectB)
        self.store.save(objectA)
        
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
    
    func testHasManyRelationshipDirectoriesAndFilesAreCreated() throws
    {
        let childAID = UUID().uuidString
        let childA = ExampleB(id: childAID)
        
        let childBID = UUID().uuidString
        let childB = ExampleB(id: childBID)
        
        let parentID = UUID().uuidString
        let parent = ExampleC(id: parentID, children: [childA, childB])
        self.store.save(parent)
        
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
    
    func testSavingMultipleObjects() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        self.store.save(objects: [objectA, objectB])
        
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
        
        self.store.save(ExampleB(id: UUID().uuidString))
        self.waitForExpectations(timeout: 2.0)
    }
    
    func testSavingEventually() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        self.store.saveEventually(objectA)
        self.expectToEventually {
            do
            {
                let result = try self.store.object(id: idA, of: ExampleB.self).execute()
                return result == objectA
            }
            catch { return false }
        }
    }
    
    func testSavingObjectsEventually() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        self.store.saveEventually(objects: [objectA, objectB])
        self.expectToEventually {
            do
            {
                let fetchA = try self.store.object(id: idA, of: ExampleB.self).execute()
                XCTAssertEqual(objectA, fetchA)
                
                let fetchB = try self.store.object(id: idB, of: ExampleB.self).execute()
                XCTAssertEqual(objectB, fetchB)
                
                return true
            }
            catch { return false }
        }
    }
    
    // MARK: Fetching
    
    func testFetchingObjectByID() throws
    {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        let fetchedObject: ExampleB? = try XCTUnwrap(self.store.object(id: idB).execute())
        XCTAssertEqual(fetchedObject?.id, objectB.id)
    }
    
    // MARK: Deleting
    
    func testDeletingObject() throws
    {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        self.store.save(object)
        
        let fetchedObject: ExampleB = try XCTUnwrap(self.store.object(id: id).execute())
        self.store.delete(fetchedObject)
        
        XCTAssertThrowsError(try self.store.object(id: id, of: ExampleB.self).execute())
    }
    
    func testDeletingEventuallyObject() throws
    {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        self.store.save(object)
        
        let fetchedObject: ExampleB = try XCTUnwrap(self.store.object(id: id).execute())
        self.store.deleteEventually(fetchedObject)
        
        self.expectToEventuallyThrow {
            _ = try self.store.object(id: id, of: ExampleB.self).execute()
        }
    }
    
    func testDeletingObjects() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        self.store.save(objectA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        let fetchedObjectA: ExampleB = try XCTUnwrap(self.store.object(id: idA).execute())
        let fetchedObjectB: ExampleB = try XCTUnwrap(self.store.object(id: idB).execute())
        self.store.delete(objects: [fetchedObjectA, fetchedObjectB])
        
        XCTAssertThrowsError(try self.store.object(id: idA, of: ExampleB.self).execute())
        XCTAssertThrowsError(try self.store.object(id: idB, of: ExampleB.self).execute())
    }
    
    func testDeletingObjectsEventually() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        self.store.save(objectA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        let fetchedObjectA: ExampleB = try XCTUnwrap(self.store.object(id: idA).execute())
        let fetchedObjectB: ExampleB = try XCTUnwrap(self.store.object(id: idB).execute())
        self.store.deleteEventually(objects: [fetchedObjectA, fetchedObjectB])
        
        self.expectToEventually {
            let a = try? self.store.object(id: idA, of: ExampleB.self).execute()
            let b = try? self.store.object(id: idB, of: ExampleB.self).execute()
            return a != nil && b != nil
        }
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
        self.store.save(object)
        
        self.store.delete(object)
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    // MARK: Merging
    
    func testMerging() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        self.store.save(objects: [objectA, objectB, objectC])
        self.store.merge(with: [objectA, objectB])
        
        XCTAssertNoThrow(try self.store.object(id: idA, of: ExampleB.self).execute())
        XCTAssertNoThrow(try self.store.object(id: idB, of: ExampleB.self).execute())
        XCTAssertThrowsError(try self.store.object(id: idC, of: ExampleB.self).execute())
        XCTAssertEqual(2, self.store.objects(type: ExampleB.self).execute().count)
    }
    
    func testMergingEventually() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        self.store.save(objects: [objectA, objectB, objectC])
        self.store.mergeEventually(with: [objectA, objectB])
        
        self.expectToEventuallyThrow { _ = try self.store.object(id: idC, of: ExampleB.self).execute() }
    }
}
