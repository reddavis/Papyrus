//
//  QueryError.swift
//  Papyrus
//
//  Created by Red Davis on 15/04/2021.
//

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
