//
//  ExampleB.swift
//  PapyrusTests
//
//  Created by Red Davis on 17/12/2020.
//

import Foundation
@testable import Papyrus


struct ExampleB: Papyrus
{
    var id: String
    var value: String
    var integerValue: Int
    
    // MARK Initialization
    
    init(id: String, value: String = UUID().uuidString, integerValue: Int = 0)
    {
        self.id = id
        self.value = value
        self.integerValue = integerValue
    }
    
    // MARK: Data
    
    func write(to url: URL) throws
    {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let url = url.appendingPathComponent(String(self.id))
        try data.write(to: url)
    }
}
