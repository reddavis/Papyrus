//
//  HasMany.swift
//  Papyrus
//
//  Created by Red Davis on 19/04/2021.
//

import Foundation


@propertyWrapper
public struct HasMany<T: Papyrus>: Codable
{
    // Public
    public var wrappedValue: [T] {
        didSet {
            self.encodingWrappers = self.wrappedValue.map(PapyrusEncodingWrapper.init)
        }
    }
    
    // Internal
    private var encodingWrappers: [PapyrusEncodingWrapper]
    
    // MARK: Initialization
    
    public init(wrappedValue: [T])
    {
        self.wrappedValue = wrappedValue
        self.encodingWrappers = wrappedValue.map(PapyrusEncodingWrapper.init)
    }
    
    public init(from decoder: Decoder) throws
    {
        self.wrappedValue = try [T].init(from: decoder)
        self.encodingWrappers = self.wrappedValue.map(PapyrusEncodingWrapper.init)
    }
    
    // MARK: Encodable
    
    public func encode(to encoder: Encoder) throws
    {
        try self.wrappedValue.encode(to: encoder)
    }
}

// MARK: Equatable

extension HasMany: Equatable
{
    public static func ==(lhs: HasMany, rhs: HasMany) -> Bool
    {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
