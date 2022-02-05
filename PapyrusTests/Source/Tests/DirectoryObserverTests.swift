import XCTest
@testable import Papyrus

// swiftlint:disable implicitly_unwrapped_optional

class DirectoryObserverTests: XCTestCase {
    private var directory: URL!
    private let fileManager = FileManager.default
    
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
    }
    
    // MARK: Tests
    
    func testObservingChanges() throws {
        let expectation = self.expectation(description: "Change detected")
        
        let observer = DirectoryObserver(
            url: self.directory,
            onChange: { [weak self] url in
                XCTAssertEqual(url, self?.directory)
                expectation.fulfill()
            }
        )
        observer.start()
        
        // Assert the observer creates directory if it doesn't exist
        XCTAssert(self.fileManager.fileExists(atPath: self.directory.path))
        
        try self.fileManager.setAttributes(
            [.modificationDate: Date.now],
            ofItemAtPath: self.directory.path
        )
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}
