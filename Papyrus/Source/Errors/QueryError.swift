import Foundation

public extension PapyrusStore {    
    /// `PapyrusStore` query error.
    enum QueryError: Error {
        
        /// Object not found
        case notFound
        
        /// Invalid schema
        case invalidSchema(details: Error)
    }
}
