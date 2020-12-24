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
    override var hash: Int { self.key.hash }
    
    // Private
    private let key: String
    
    // MARK: Initialization
    
    init<T>(object: T) where T: Papyrus
    {
        self.key = String(describing: T.self) + object.id
    }
    
    init<T>(id: String, type: T.Type) where T: Papyrus
    {
        self.key = String(describing: type) + id
    }
    
    // MARK: NSObject
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let object = object as? CacheKey else { return false }
        return object.key == self.key
    }
}
