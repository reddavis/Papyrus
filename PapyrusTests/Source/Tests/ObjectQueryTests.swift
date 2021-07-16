import Combine
import XCTest
@testable import Papyrus


final class ObjectQueryTests: XCTestCase
{
    // Private
    private var storeDirectory: URL!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: Setup
    
    override func setUpWithError() throws
    {
        self.cancellables = []
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.storeDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: self.storeDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    // MARK: Tests
    
    func testFetchingObject() async throws
    {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        try object.write(to: self.storeDirectory)
        
        let query = PapyrusStore.ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.storeDirectory
        )
        
        let result = try await query.execute()
        XCTAssertEqual(result, object)
    }
    
    func testFetchingNonExistentObject() async throws
    {
        let id = UUID().uuidString
        let query = PapyrusStore.ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.storeDirectory
        )
        
        do
        {
            _ = try await query.execute()
            XCTFail("Error should be raised")
        }
        catch { }
    }
    
    func testStreamingObjectChanges() async throws
    {
        let id = UUID().uuidString
        let object = ExampleB(id: id)
        try object.write(to: self.storeDirectory)
        
        let query = PapyrusStore.ObjectQuery<ExampleB>(
            id: id,
            directoryURL: self.storeDirectory
        )
        
        var iterator = query.stream().makeAsyncIterator()
                
        var value = await iterator.next()
        XCTAssertEqual(value, .success(object))
        
        // Update
        let updatedObject = ExampleB(id: id, value: UUID().uuidString)
        try updatedObject.write(to: self.storeDirectory)
        try self.updateDirectoryModificationDate(directoryURL: self.storeDirectory)
        
        value = await iterator.next()
        XCTAssertEqual(value, .success(updatedObject))
    }
}


// MARK: Helpers

extension ObjectQueryTests
{
    func updateDirectoryModificationDate(directoryURL: URL) throws
    {
        try FileManager.default.setAttributes(
            [.modificationDate : Date.now],
            ofItemAtPath: directoryURL.path
        )
    }
}
