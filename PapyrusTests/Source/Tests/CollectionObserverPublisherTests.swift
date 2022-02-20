import Combine
import XCTest
@testable import Papyrus

// swiftlint:disable implicitly_unwrapped_optional

final class CollectionObserverPublisherTests: XCTestCase {
    private var storeDirectory: URL!
    private let numberOfDummyObjects = 10
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.cancellables = []
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: self.storeDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Dummy data
        try self.numberOfDummyObjects.times {
            try ExampleB(id: UUID().uuidString).write(to: self.storeDirectory)
        }
    }
    
    // MARK: Tests
    
    func testValuesReceived() throws {
        let expectation = self.expectation(description: "Received values")
        
        CollectionObserverPublisher<ExampleB>(directoryURL: self.storeDirectory)
            .first()
            .sink {
                XCTAssertEqual($0.count, self.numberOfDummyObjects)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    func testCompletionReceived() throws {
        let expectation = self.expectation(description: "Completion called")
        
        CollectionObserverPublisher<ExampleB>(directoryURL: self.storeDirectory)
            .first()
            .sink(receiveCompletion: {
                XCTAssertEqual($0, .finished)
                expectation.fulfill()
            }, receiveValue: {
                XCTAssertEqual($0.count, self.numberOfDummyObjects)
            })
            .store(in: &self.cancellables)
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    func testUpdatesNotReceivedOnWrites() throws {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 1
        
        CollectionObserverPublisher<ExampleB>(directoryURL: self.storeDirectory)
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        try ExampleB(id: UUID().uuidString).write(to: self.storeDirectory)
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    func testUpdatesNotReceivedOnDeletes() throws {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 1
        
        CollectionObserverPublisher<ExampleB>(directoryURL: self.storeDirectory)
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        let object = ExampleB(id: UUID().uuidString)
        try object.write(to: self.storeDirectory)
        try FileManager.default.removeItem(at: self.storeDirectory.appendingPathComponent(object.id))
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    func testUpdatesReceivedOnAttributeUpdate() throws {
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 2
        
        CollectionObserverPublisher<ExampleB>(directoryURL: self.storeDirectory)
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)
        
        try FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: self.storeDirectory.path
        )
        
        self.waitForExpectations(timeout: 2.0)
    }
}
