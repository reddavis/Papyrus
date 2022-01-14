import Foundation


/// A type that can be stored, retrieved and deleted from a `PapyrusStore`.
///
/// A `Papyrus` conforming object must also conform:
/// - `Codable`
/// - `Equatable`
/// - `Identifiable where ID: LosslessStringConvertible`
public protocol Papyrus: Codable, Equatable, Identifiable where ID: LosslessStringConvertible { }

// MARK: Helpers

extension Papyrus {
    var filename: String { String(self.id) }
}
