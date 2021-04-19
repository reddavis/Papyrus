//
//  Papyrus.swift
//  Papyrus
//
//  Created by Red Davis on 16/12/2020.
//

import Foundation


/// A type that can be stored, retrieved and deleted from a `PapyrusStore`.
///
/// A `Papyrus` conforming object must also conform:
/// - `Codable`
/// - `Equatable`
/// - `Identifiable`
public protocol Papyrus: Codable, Equatable, Identifiable { }

// MARK: Helpers

extension Papyrus
{
    var filename: String { String(self.id.hashValue) }
}
