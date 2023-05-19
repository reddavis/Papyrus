import XCTest
@testable import Papyrus

final class ObjectQueryTests: XCTestCase {
    private let fileManager = FileManager.default
    private var storeDirectory: URL!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        try self.fileManager.createDirectory(
            at: self.storeDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    // MARK: Tests
    
    func test_execute() throws {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        try object.write(to: self.storeDirectory)
        
        let query = ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.storeDirectory
        )
        
        let result = try query.execute()
        XCTAssertEqual(result, object)
    }
    
    func test_execute_whenNonExistentObject() async throws {
        let id = UUID().uuidString
        let query = ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.storeDirectory
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
        try object.write(to: self.storeDirectory)
        
        let query = ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.storeDirectory
        )
        
        var iterator = query.observe().makeAsyncIterator()
        
        // Update
        let updatedObject = ExampleB(id: id, value: UUID().uuidString)
        try updatedObject.write(to: self.storeDirectory)
        try FileManager.default.poke(self.storeDirectory)
        
        var value = try await iterator.next()
        XCTAssertEqual(value, .changed(updatedObject))

        // Deleted
        try self.fileManager.removeItem(at: self.storeDirectory.appendingPathComponent(id))
        try FileManager.default.poke(self.storeDirectory)

        value = try await iterator.next()
        XCTAssertEqual(value, .deleted)
    }
}
