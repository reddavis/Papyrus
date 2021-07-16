import XCTest
@testable import Papyrus


class ObjectFileObserverTests: XCTestCase
{
    // Private
    private var directory: URL!
    private let fileManager = FileManager.default
    
    // MARK: Setup
    
    override func setUpWithError() throws
    {
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
    
    func testObservingChanges() throws
    {
        // Setup
        let expectation = self.expectation(description: "Change detected")
        
        let observer = ObjectFileObserver<ExampleB>(
            filename: UUID().uuidString,
            directoryURL: self.directory,
            onChange: { _ in
                expectation.fulfill()
            }
        )
        observer.start()
        
        // Assert the observer creates directory if it doesn't exist
        XCTAssert(self.fileManager.fileExists(atPath: self.directory.path))
        
        try self.fileManager.setAttributes(
            [.modificationDate : Date.now],
            ofItemAtPath: self.directory.path
        )
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}
