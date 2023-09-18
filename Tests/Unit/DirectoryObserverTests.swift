import XCTest
@testable import Papyrus

final class DirectoryObserverTests: XCTestCase {
    private var directory: URL!
    private let fileManager = FileManager.default
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.directory = URL.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
    }
    
    override func tearDown() {
        try? self.fileManager.removeItem(at: self.directory)
    }
    
    // MARK: Tests
    
    func test_observer() async throws {
        let observer = try DirectoryObserver(url: self.directory)
        let taskStartedExpectation = self.expectation(description: "taskStartedExpectation")
        let expectation = self.expectation(description: "Change detected")
        
        Task {
            taskStartedExpectation.fulfill()
            for await _ in observer.observe() {
                expectation.fulfill()
            }
        }
        
        await self.fulfillment(of: [taskStartedExpectation], timeout: 0.1)
        try FileManager.default.poke(self.directory)
        
        await self.fulfillment(of: [expectation], timeout: 0.1)
        XCTAssert(self.fileManager.fileExists(atPath: self.directory.path))
    }
}
