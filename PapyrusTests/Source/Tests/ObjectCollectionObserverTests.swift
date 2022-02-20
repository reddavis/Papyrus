import XCTest
@testable import Papyrus

// swiftlint:disable implicitly_unwrapped_optional

class ObjectCollectionObserverTests: XCTestCase {
    private var temporaryDirectoryURL: URL!
    private var directory: URL!
    private let fileManager = FileManager.default
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.temporaryDirectoryURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        
        self.directory = temporaryDirectoryURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
    }
    
    // MARK: Tests
    
    func testDirectoryCreatedIfNotExists() throws {
        let directory = self.temporaryDirectoryURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        
        XCTAssertFalse(self.fileManager.fileExists(atPath: directory.path))
        
        let observer = ObjectCollectionObserver<ExampleB>(
            url: directory,
            onChange: { _ in }
        )
        observer.start()
        
        // Assert the observer creates directory if it doesn't exist
        XCTAssert(self.fileManager.fileExists(atPath: directory.path))
    }
    
    func testObservingChanges() throws {
        let expectation = self.expectation(description: "Change detected")
        expectation.expectedFulfillmentCount = 2
        
        let observer = ObjectCollectionObserver<ExampleB>(
            url: self.directory,
            onChange: { objects in
                expectation.fulfill()
            }
        )
        observer.start()
        
        // Write object
        try self.fileManager.setAttributes(
            [.modificationDate: Date.now],
            ofItemAtPath: self.directory.path
        )
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}
