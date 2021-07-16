import Combine
import XCTest
@testable import Papyrus


final class CollectionQueryTests: XCTestCase
{
    // Private
    private var storeDirectory: URL!
    private let numberOfDummyObjects = 10
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: Setup
    
    override func setUpWithError() throws
    {
        self.cancellables = []
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: self.storeDirectory, withIntermediateDirectories: true, attributes: nil)
        
        // Dummy data
        try self.numberOfDummyObjects.times { index in
            try ExampleB(id: UUID().uuidString, integerValue: index).write(to: self.storeDirectory)
        }
    }
    
    // MARK: Tests
    
    func testFetchingAll() async throws
    {
        let query = PapyrusStore.CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
        let results = await query.execute().count
        
        XCTAssertEqual(results, self.numberOfDummyObjects)
    }
    
    func testFiltering() async throws
    {
        let query = PapyrusStore.CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
        let results = await query.execute().count
        
        XCTAssertEqual(results, 5)
    }
    
    func testSorting() async throws
    {
        let query = PapyrusStore.CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
        let results = await query.execute()
        
        XCTAssertEqual(results.first?.integerValue, 10)
    }
    
    func testFiltersAppliedToObserverPublisher() throws
    {
        let expectation = self.expectation(description: "Received value")
        
        PapyrusStore.CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
            .publisher()
            .first()
            .sink {
                XCTAssertEqual($0.count, 5)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        self.waitForExpectations(timeout: 2.0)
    }
    
    func testSortAppliedToObserverPublisher() throws
    {
        let expectation = self.expectation(description: "Received value")
        
        PapyrusStore.CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
            .publisher()
            .first()
            .sink {
                XCTAssertEqual($0.first?.integerValue, 10)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        self.waitForExpectations(timeout: 2.0)
    }
}
