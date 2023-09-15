import XCTest
@testable import Papyrus

final class CollectionQueryTests: XCTestCase {
    private var directory: URL!
    private let numberOfDummyObjects = 10
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Dummy data
        try self.numberOfDummyObjects.times { index in
            try ExampleB(id: UUID().uuidString, integerValue: index).write(to: self.directory)
        }
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: self.directory)
    }
    
    // MARK: Tests
    
    func test_fetchingAll() {
        let query = CollectionQuery<ExampleB>(directoryURL: self.directory)
        let results = query.execute()
        
        XCTAssertEqual(results.count, self.numberOfDummyObjects)
        XCTAssertEqual(results.map(\.integerValue), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    }
    
    func test_filter() {
        let query = CollectionQuery<ExampleB>(directoryURL: self.directory)
            .filter { $0.integerValue > 5 }
        let results = query.execute().count
        
        XCTAssertEqual(results, 5)
    }
    
    func test_sort() {
        let query = CollectionQuery<ExampleB>(directoryURL: self.directory)
            .sort { $0.integerValue > $1.integerValue }
        let results = query.execute()
        
        XCTAssertEqual(results.first?.integerValue, 10)
    }
    
    func test_filter_whenAppliedToStream() async throws {
        Task {
            try await Task.sleep(for: .milliseconds(10))
            try FileManager.default.poke(self.directory)
        }
        
        let collection = try await CollectionQuery<ExampleB>(directoryURL: self.directory)
            .filter { $0.integerValue > 5 }
            .observe()
            .first()
        
        XCTAssertEqual(collection?.count, 5)
    }
    
    func test_sort_whenAppliedToStream() async throws {
        Task {
            try await Task.sleep(for: .milliseconds(10))
            try FileManager.default.poke(self.directory)
        }
        
        let collection = try await CollectionQuery<ExampleB>(directoryURL: self.directory)
            .sort { $0.integerValue > $1.integerValue }
            .observe()
            .first()

        XCTAssertEqual(collection?.count, 10)
        XCTAssertEqual(collection?.first?.integerValue, 10)
    }
}
