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
        self.store = try PapyrusStore(url: self.storeDirectory)
    }
    
    // MARK: Saving
    
    func testDirectoriesAndFilesAreCreated() throws
    {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        // Object B's type directory created
        let objectTypeBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB)))
        self.expectToEventually(self.fileManager.fileExists(atPath: objectTypeBDirectory.path))
        
        // Object B's data file created
        let objectBDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB))).appendingPathComponent(idB)
        self.expectToEventually(self.fileManager.fileExists(atPath: objectBDataFile.path))
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
        self.expectToEventually(self.fileManager.fileExists(atPath: objectTypeADirectory.path))
        
        // Object A's data file created
        let objectADataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectA))).appendingPathComponent(idA)
        self.expectToEventually(self.fileManager.fileExists(atPath: objectADataFile.path))
        
        // Object B's type directory created
        let objectTypeBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB)))
        self.expectToEventually(self.fileManager.fileExists(atPath: objectTypeBDirectory.path))
        
        // Object B's data file created
        let objectBDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectB))).appendingPathComponent(idB)
        self.expectToEventually(self.fileManager.fileExists(atPath: objectBDataFile.path))
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
        self.expectToEventually(self.fileManager.fileExists(atPath: parentDirectory.path))
        
        // Parent's data file created
        let parentDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: parent))).appendingPathComponent(parentID)
        self.expectToEventually(self.fileManager.fileExists(atPath: parentDataFile.path))
        
        // Child A's type directory created
        let childADirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: childA)))
        self.expectToEventually(self.fileManager.fileExists(atPath: childADirectory.path))
        
        // Child A's data file created
        let childADataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: childA))).appendingPathComponent(childAID)
        self.expectToEventually(self.fileManager.fileExists(atPath: childADataFile.path))
        
        // Child B's type directory created
        let childBDirectory = self.storeDirectory.appendingPathComponent(String(describing: type(of: childB)))
        self.expectToEventually(self.fileManager.fileExists(atPath: childBDirectory.path))
        
        // Child B's data file created
        let childBDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: childB))).appendingPathComponent(childBID)
        self.expectToEventually(self.fileManager.fileExists(atPath: childBDataFile.path))
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
            .observe()
            .subscribe(on: DispatchQueue.global())
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        self.store.save(ExampleB(id: UUID().uuidString))
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    // MARK: Fetching
    
    func testFetchingObjectByID() throws
    {
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        let fetchedObject: ExampleB? = self.store.object(id: idB)
        XCTAssertEqual(fetchedObject?.id, objectB.id)
    }
    
    // MARK: Deleting
    
    func testDeletingObject() throws
    {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        self.store.save(object)
        
        let fetchedObject: ExampleB = try XCTUnwrap(self.store.object(id: id))
        self.store.delete(fetchedObject)
        
        XCTAssertNil(self.store.object(id: id, of: ExampleB.self))
    }
    
    func testDeletingObjects() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        self.store.save(objectA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        self.store.save(objectB)
        
        let fetchedObjectA: ExampleB = try XCTUnwrap(self.store.object(id: idA))
        let fetchedObjectB: ExampleB = try XCTUnwrap(self.store.object(id: idB))
        self.store.delete(objects: [fetchedObjectA, fetchedObjectB])
        
        XCTAssertNil(self.store.object(id: idA, of: ExampleB.self))
        XCTAssertNil(self.store.object(id: idB, of: ExampleB.self))
    }
    
    func testUpdatesReceivedOnDeleting() throws
    {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 3
        
        self.store.objects(type: ExampleB.self)
            .observe()
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        let object = ExampleB(id: UUID().uuidString)
        self.store.save(object)
        
        self.store.delete(object)
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    // MARK: Intersect
    
    func testIntersecting() throws
    {
        let idA = UUID().uuidString
        let objectA = ExampleB(id: idA)
        
        let idB = UUID().uuidString
        let objectB = ExampleB(id: idB)
        
        let idC = UUID().uuidString
        let objectC = ExampleB(id: idC)
        
        self.store.save(objects: [objectA, objectB, objectC])
        
        // Wait for data to be written
        let objectCDataFile = self.storeDirectory.appendingPathComponent(String(describing: type(of: objectC))).appendingPathComponent(idC)
        self.expectToEventually(self.fileManager.fileExists(atPath: objectCDataFile.path))
        
        self.store.intersect(with: [objectA, objectB])
        XCTAssertNotNil(self.store.object(id: idA, of: ExampleB.self))
        XCTAssertNotNil(self.store.object(id: idB, of: ExampleB.self))
        XCTAssertNil(self.store.object(id: idC, of: ExampleB.self))
    }
}
