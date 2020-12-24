//
//  PapyrusCacheWrapper.swift
//  Papyrus
//
//  Created by Red Davis on 18/12/2020.
//

import Foundation


final class PapyrusCacheWrapper
{
    // Internal
    let object: Any
    
    // MARK: Initializer
    
    init<T>(_ object: T) where T: Papyrus
    {
        self.object = object
    }
}
