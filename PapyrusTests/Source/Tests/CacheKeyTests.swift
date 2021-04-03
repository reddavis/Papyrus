//
//  CacheKeyTests.swift
//  PapyrusTests
//
//  Created by Red Davis on 03/04/2021.
//

import XCTest
@testable import Papyrus


class CacheKeyTests: XCTestCase
{
    func testKey() throws
    {
        var id = UUID().uuidString
        var key = CacheKey(id: id, type: ExampleA.self).key
        XCTAssertEqual(key, "ExampleA\(id)")
        
        id = UUID().uuidString
        key = CacheKey(object: ExampleB(id: id)).key
        XCTAssertEqual(key, "ExampleB\(id)")
    }
}
