import Foundation

/// A type that can be stored, retrieved and deleted from a `PapyrusStore`.
///
/// A `Papyrus` conforming object must also conform:
/// - `Codable`
/// - `Equatable`
/// - `Identifiable where ID: LosslessStringConvertible & Sendable`
public protocol Papyrus: Codable, Equatable, Identifiable where ID: LosslessStringConvertible & Sendable { }

// MARK: Helpers

extension Papyrus {
    var filename: String { String(self.id) }
    var typeDescription: String { String(describing: type(of: self)) }
}
