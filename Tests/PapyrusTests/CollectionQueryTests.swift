import Asynchrone
import XCTest
@testable import Papyrus

final class CollectionQueryTests: XCTestCase {
    private var storeDirectory: URL!
    private let numberOfDummyObjects = 10
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: self.storeDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Dummy data
        try self.numberOfDummyObjects.times { index in
            try ExampleB(id: UUID().uuidString, integerValue: index).write(to: self.storeDirectory)
        }
    }
    
    // MARK: Tests
    
    func testFetchingAll() async throws {
        let query = CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
        let results = await query.execute().count
        
        XCTAssertEqual(results, self.numberOfDummyObjects)
    }
    
    func testFiltering() async throws {
        let query = CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
        let results = await query.execute().count
        
        XCTAssertEqual(results, 5)
    }
    
    func testSorting() async throws {
        let query = CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
        let results = await query.execute()
        
        XCTAssertEqual(results.first?.integerValue, 10)
    }
    
    func testFiltersAppliedToObserverPublisher() async throws {
        let collection = try await CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
            .stream()
            .first()

        XCTAssertEqual(collection?.count, 5)
    }
    
    func testSortAppliedToStream() async throws {
        let collection = try await CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
            .stream()
            .first()

        XCTAssertEqual(collection?.count, 10)
        XCTAssertEqual(collection?.first?.integerValue, 10)
    }
}
