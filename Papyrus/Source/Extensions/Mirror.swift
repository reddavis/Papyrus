//
//  Mirror.swift
//  Papyrus
//
//  Created by Red Davis on 18/12/2020.
//

import Foundation


/// [Thanks!](https://www.swiftbysundell.com/articles/reflection-in-swift/)
extension Mirror
{
    static func reflectProperties<T>(of target: Any,
                                     matchingType type: T.Type = T.self,
                                     recursively: Bool = false,
                                     using closure: (T) -> Void)
    {
        let mirror = Mirror(reflecting: target)
        mirror.children.forEach {
            ($0.value as? T).map(closure)
            
            guard recursively else { return }
            
            Mirror.reflectProperties(of: $0.value,
                                     recursively: true,
                                     using: closure)
        }
    }
}
