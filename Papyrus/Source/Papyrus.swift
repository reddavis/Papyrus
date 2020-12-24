//
//  Papyrus.swift
//  Papyrus
//
//  Created by Red Davis on 16/12/2020.
//

import Foundation


/// A type that can be stored, retrieved and deleted from a `PapyrusStore`.
///
/// A `Papyrus` conforming object must also conform to `Codable`.
public protocol Papyrus: Codable
{
    /// The ID of the object.
    var id: String { get }
}
