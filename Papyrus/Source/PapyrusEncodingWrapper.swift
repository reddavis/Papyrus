//
//  PapyrusWrapper.swift
//  Papyrus
//
//  Created by Red Davis on 17/12/2020.
//

import Foundation


struct PapyrusEncodingWrapper: Encodable
{
    // Internal
    let typeDescription: String
    
    // Private
    private let _encode: (Encoder) throws -> Void
    
    // MARK: Initializer
    
    init(_ wrapped: Encodable)
    {
        self._encode = wrapped.encode
        self.typeDescription = String(describing: type(of: wrapped))
    }

    // MARK: Encodable
    
    func encode(to encoder: Encoder) throws
    {
        try self._encode(encoder)
    }
}
