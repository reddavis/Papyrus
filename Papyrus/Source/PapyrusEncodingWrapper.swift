import Foundation


struct PapyrusEncodingWrapper: Encodable
{
    // Internal
    let typeDescription: String
    let filename: String
    
    // Private
    private let _encode: (Encoder) throws -> Void
    
    // MARK: Initializer
    
    init<T: Papyrus>(object: T)
    {
        self.filename = object.filename
        self._encode = object.encode
        self.typeDescription = String(describing: type(of: object))
    }

    // MARK: Encodable
    
    func encode(to encoder: Encoder) throws
    {
        try self._encode(encoder)
    }
}
