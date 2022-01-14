import Foundation


/// A data migration for migrating one `Papyrus` object to another.
public struct Migration<FromObject: Papyrus, ToObject: Papyrus> {
    public typealias OnMigrate = (_ from: FromObject) -> ToObject
    
    // Internal
    let onMigrate: OnMigrate
    
    // MARK: Initialization
    
    /// Initialize a new `Migration` instance.
    /// - Parameter onMigrate: A closure declaring data migration.
    public init(_ onMigrate: @escaping OnMigrate) {
        self.onMigrate = onMigrate
    }
}
