import XCTest
@testable import Papyrus

class ObjectObserverTests: XCTestCase {
    private var temporaryDirectoryURL: URL!
    private var directory: URL!
    private let fileManager = FileManager.default
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.temporaryDirectoryURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        
        self.directory = self.temporaryDirectoryURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        
        try self.fileManager.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    // MARK: Tests
    
    func testDirectoryCreatedIfNotExists() throws {
        let directory = self.temporaryDirectoryURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        
        XCTAssertFalse(self.fileManager.fileExists(atPath: directory.path))
        
        let observer = ObjectObserver<ExampleB>(
            filename: UUID().uuidString,
            directoryURL: directory,
            onChange: { _ in }
        )
        observer.start()
        
        // Assert the observer creates directory if it doesn't exist
        XCTAssert(self.fileManager.fileExists(atPath: directory.path))
    }
    
    func testObservingUpdates() throws {
        // Setup
        let expectation = self.expectation(description: "Change detected")
        expectation.expectedFulfillmentCount = 2
        
        var object = ExampleB(id: UUID().uuidString)
        try object.write(to: self.directory)
        
        let observer = ObjectObserver<ExampleB>(
            filename: object.id,
            directoryURL: self.directory,
            onChange: { _ in
                expectation.fulfill()
            }
        )
        observer.start()
        
        // Update object
        object.value = UUID().uuidString
        try object.write(to: self.directory)
        try self.markDirectoryAsUpdated(self.directory)
        
        // Wait
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testObservingDeletions() throws {
        // Setup
        let expectation = self.expectation(description: "Change detected")
        expectation.expectedFulfillmentCount = 2

        let object = ExampleB(id: UUID().uuidString)
        try object.write(to: self.directory)

        let observer = ObjectObserver<ExampleB>(
            filename: object.id,
            directoryURL: self.directory,
            onChange: { _ in
                expectation.fulfill()
            }
        )
        observer.start()

        // Delete object
        try object.remove(from: self.directory)
        try self.markDirectoryAsUpdated(self.directory)

        // Wait
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testOnChangeNotTriggeredIfNoChangeToObject() throws {
        // Setup
        let expectation = self.expectation(description: "Change detected")
        
        let object = ExampleB(id: UUID().uuidString)
        try object.write(to: self.directory)
        
        let observer = ObjectObserver<ExampleB>(
            filename: object.id,
            directoryURL: self.directory,
            onChange: { _ in
                expectation.fulfill()
            }
        )
        observer.start()
        
        // Mark directory as changed
        try self.markDirectoryAsUpdated(self.directory)
        
        // Wait
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}

// MARK: Helpers

fileprivate extension ObjectObserverTests {
    func markDirectoryAsUpdated(_ url: URL, date: Date = .now) throws {
        try self.fileManager.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: url.path
        )
    }
}
