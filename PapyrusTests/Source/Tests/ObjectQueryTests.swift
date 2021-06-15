//
//  ObjectQueryTests.swift
//  PapyrusTests
//
//  Created by Red Davis on 17/04/2021.
//

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
}
