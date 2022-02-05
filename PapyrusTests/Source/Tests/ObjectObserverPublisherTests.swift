#if canImport(Combine)
import Combine
import XCTest
@testable import Papyrus


final class ObjectObserverPublisherTests: XCTestCase {
    private var id: String!
    private var storeDirectory: URL!
    private var cancellables: Set<AnyCancellable>!
    
    private var filename: String {
        self.id
    }
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.id = UUID().uuidString
        self.cancellables = []
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: self.storeDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    // MARK: Tests
    
    func testValuesReceived() throws {
        // Setup
        let object = ExampleB(id: self.id)
        try object.write(to: self.storeDirectory)
        
        // Test
        let expectation = self.expectation(description: "Received values")
        
        ObjectObserverPublisher<ExampleB>(
            filename: self.filename,
            directoryURL: self.storeDirectory
        )
        .sink(
            receiveCompletion: {
                switch $0 {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:()
                }
            },
            receiveValue: {
                XCTAssertEqual($0, object)
                expectation.fulfill()
            }
        )
        .store(in: &self.cancellables)
        
        self.waitForExpectations(timeout: 2.0)
    }
    
    func testCompletionReceived() throws {
        // Setup
        let object = ExampleB(id: self.id)
        try object.write(to: self.storeDirectory)
        
        // Test
        let expectation = self.expectation(description: "Completion called")
        
        ObjectObserverPublisher<ExampleB>(
            filename: self.filename,
            directoryURL: self.storeDirectory
        )
        .first()
        .sink(
            receiveCompletion: {
                switch $0 {
                case .failure:
                    XCTFail()
                default:()
                }
                
                expectation.fulfill()
            },
            receiveValue: {
                XCTAssertEqual($0, object)
            }
        )
        .store(in: &self.cancellables)

        self.waitForExpectations(timeout: 2.0)
    }

    func testUpdatesReceivedOnChange() throws {
        // Setup
        var object = ExampleB(id: self.id)
        try object.write(to: self.storeDirectory)
        
        // Test
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 2
        
        ObjectObserverPublisher<ExampleB>(
            filename: self.filename,
            directoryURL: self.storeDirectory
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in expectation.fulfill() }
        )
        .store(in: &self.cancellables)
        
        object.value = UUID().uuidString
        try object.write(to: self.storeDirectory)
        try self.updateDirectoryModificationDate(directorURL: self.storeDirectory)

        self.waitForExpectations(timeout: 2.0)
    }
    
    func testUpdatesNotReceivedWhenNoChange() throws {
        // Setup
        let object = ExampleB(id: self.id)
        try object.write(to: self.storeDirectory)
        
        // Test
        let expectation = self.expectation(description: "Received values")
        expectation.expectedFulfillmentCount = 1
        
        ObjectObserverPublisher<ExampleB>(
            filename: self.filename,
            directoryURL: self.storeDirectory
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in expectation.fulfill() }
        )
        .store(in: &self.cancellables)
        
        try object.write(to: self.storeDirectory)
        try self.updateDirectoryModificationDate(directorURL: self.storeDirectory)

        self.waitForExpectations(timeout: 1.0)
    }
    
    func testNotFoundErrorReceivedWhenNoObject() throws {
        let expectation = self.expectation(description: "Received values")
        
        ObjectObserverPublisher<ExampleB>(
            filename: self.filename,
            directoryURL: self.storeDirectory
        )
        .sink(
            receiveCompletion: {
                switch $0 {
                case .failure(let error):
                    switch error {
                    case .invalidSchema:
                        XCTFail()
                    default:()
                    }
                    
                    expectation.fulfill()
                case .finished:
                    XCTFail()
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &self.cancellables)
        
        self.waitForExpectations(timeout: 2.0)
    }
}

// MARK: Helpers

extension ObjectObserverPublisherTests {
    func updateDirectoryModificationDate(directorURL: URL) throws {
        try FileManager.default.setAttributes(
            [.modificationDate : Date()],
            ofItemAtPath: directorURL.path
        )
    }
}
#endif
