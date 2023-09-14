import XCTest
@testable import Papyrus

final class ObjectQueryTests: XCTestCase {
    private let fileManager = FileManager.default
    private var directory: URL!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.directory = URL.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        
        try self.fileManager.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    override func tearDown() {
        try? self.fileManager.removeItem(at: self.directory)
    }
    
    // MARK: Tests
    
    func test_execute() throws {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        try object.write(to: self.directory)
        
        let query = ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.directory
        )
        
        let result = try query.execute()
        XCTAssertEqual(result, object)
    }
    
    func test_execute_whenNonExistentObject() async throws {
        let id = UUID().uuidString
        let query = ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.directory
        )
        
        XCTAssertThrowsError(_ = try query.execute()) { error in
            guard case PapyrusStore.QueryError.notFound = error else {
                XCTFail()
                return
            }
        }
    }
    
    func test_observe() async throws {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        try object.write(to: self.directory)
        
        let query = ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.directory
        )
        
        var iterator = query.observe().makeAsyncIterator()
        
        // Update
        let updatedObject = ExampleB(id: id, value: UUID().uuidString)
        try updatedObject.write(to: self.directory)
        try FileManager.default.poke(self.directory)
        
        var value = try await iterator.next()
        XCTAssertEqual(value, .changed(updatedObject))

        // Deleted
        try self.fileManager.removeItem(at: self.directory.appendingPathComponent(id))
        try FileManager.default.poke(self.directory)

        value = try await iterator.next()
        XCTAssertEqual(value, .deleted)
    }
}
