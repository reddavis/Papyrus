//
//  PapyrusCollectionTests.swift
//  PapyrusTests
//
//  Created by Red Davis on 04/01/2021.
//

import Combine
import XCTest
@testable import Papyrus


final class PapyrusQueryTests: XCTestCase
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
    
    func testFetchingAll() throws
    {
        let query = PapyrusStore.Query<ExampleB>(directoryURL: self.storeDirectory)
        XCTAssertEqual(query.execute().count, self.numberOfDummyObjects)
    }
    
    func testFiltering() throws
    {
        let query = PapyrusStore.Query<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
        XCTAssertEqual(query.execute().count, 5)
    }
    
    func testSorting() throws
    {
        let query = PapyrusStore.Query<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
        XCTAssertEqual(query.execute().first?.integerValue, 10)
    }
    
    func testFiltersAppliedToObserverPublisher() throws
    {
        let expectation = self.expectation(description: "Received value")
        
        PapyrusStore.Query<ExampleB>(directoryURL: self.storeDirectory)
            .filter { $0.integerValue > 5 }
            .observe()
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
        
        PapyrusStore.Query<ExampleB>(directoryURL: self.storeDirectory)
            .sort { $0.integerValue > $1.integerValue }
            .observe()
            .first()
            .sink {
                XCTAssertEqual($0.first?.integerValue, 10)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        self.waitForExpectations(timeout: 2.0)
    }
}
