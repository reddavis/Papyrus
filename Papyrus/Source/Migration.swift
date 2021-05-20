//
//  Migration.swift
//  Papyrus
//
//  Created by Red Davis on 19/05/2021.
//

import Foundation


/// A data migration for migrating one `Papyrus` object to another.
public struct Migration<FromObject: Papyrus, ToObject: Papyrus>
{
    // Public
    public typealias OnMigrate = (_ from: FromObject) -> ToObject
    
    // Internal
    let onMigrate: OnMigrate
    
    // MARK: Initialization
    
    /// Initialize a new `Migration` instance.
    /// - Parameter onMigrate: A closure declaring data migration.
    public init(_ onMigrate: @escaping OnMigrate)
    {
        self.onMigrate = onMigrate
    }
}
