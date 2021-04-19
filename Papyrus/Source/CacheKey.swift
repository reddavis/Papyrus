//
//  CacheKey.swift
//  Papyrus
//
//  Created by Red Davis on 22/12/2020.
//

import Foundation


final class CacheKey: NSObject
{
    // Internal
    let key: String
    override var hash: Int { self.key.hashValue }
    
    // MARK: Initialization
    
    init<T>(object: T) where T: Papyrus
    {
        self.key = String(describing: T.self) + String(object.id.hashValue)
    }
    
    init<T, ID: Hashable>(id: ID, type: T.Type) where T: Papyrus
    {
        self.key = String(describing: type) + String(id.hashValue)
    }
    
    // MARK: NSObject
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let object = object as? CacheKey else { return false }
        return object.key == self.key
    }
}
