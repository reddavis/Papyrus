import Foundation


public extension PapyrusStore
{
    /// `PapyrusStore` query error.
    enum QueryError: Error, Equatable
    {
        /// Object not found
        case notFound
    }
}
