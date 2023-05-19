import Foundation

/// [Thanks!](https://www.swiftbysundell.com/articles/reflection-in-swift/)
extension Mirror {
    static func reflectProperties<T>(
        of target: Any,
        matchingType type: T.Type = T.self,
        recursively: Bool = false,
        using closure: (T) throws -> Void
    ) rethrows {
        let mirror = Mirror(reflecting: target)
        for child in mirror.children {
            try (child.value as? T).map(closure)
            
            guard recursively else { return }
            
            try Mirror.reflectProperties(
                of: child.value,
                recursively: true,
                using: closure
            )
        }
    }
}
