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
    
    func test_fetchingAll() throws {
        let query = CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
        let results = try query.execute()
        
        XCTAssertEqual(results.count, self.numberOfDummyObjects)
        XCTAssertEqual(results.map(\.integerValue), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    }
    
    func test_filter() throws {
        let query = CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
        let results = try query.execute().count
        
        XCTAssertEqual(results, 5)
    }
    
    func test_sort() throws {
        let query = CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
        let results = try query.execute()
        
        XCTAssertEqual(results.first?.integerValue, 10)
    }
    
    func test_filter_whenAppliedToStream() async throws {
        Task {
            try await Task.sleep(for: .milliseconds(10))
            try FileManager.default.poke(self.storeDirectory)
        }
        
        let collection = try await CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
            .observe()
            .first()
        
        XCTAssertEqual(collection?.count, 5)
    }
    
    func test_sort_whenAppliedToStream() async throws {
        Task {
            try await Task.sleep(for: .milliseconds(10))
            try FileManager.default.poke(self.storeDirectory)
        }
        
        let collection = try await CollectionQuery<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
            .observe()
            .first()

        XCTAssertEqual(collection?.count, 10)
        XCTAssertEqual(collection?.first?.integerValue, 10)
    }
}



