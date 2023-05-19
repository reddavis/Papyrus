import Foundation

@propertyWrapper
public struct HasOne<T: Papyrus>: Codable {
    public var wrappedValue: T {
        didSet {
            self.encodingWrapper = PapyrusEncodingWrapper(self.wrappedValue)
        }
    }
    
    // Private
    private var encodingWrapper: PapyrusEncodingWrapper
    
    // MARK: Initialization
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
        self.encodingWrapper = PapyrusEncodingWrapper(self.wrappedValue)
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try T.init(from: decoder)
        self.encodingWrapper = PapyrusEncodingWrapper(self.wrappedValue)
    }
    
    // MARK: Encodable
    
    public func encode(to encoder: Encoder) throws {
        try self.wrappedValue.encode(to: encoder)
    }
}

// MARK: Equatable

extension HasOne: Equatable {
    public static func ==(lhs: HasOne, rhs: HasOne) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
