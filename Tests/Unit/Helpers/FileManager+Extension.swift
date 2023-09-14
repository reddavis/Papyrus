import Foundation

extension FileManager {
    func poke(_ url: URL) throws {
        try self.setAttributes(
            [.modificationDate: Date.now],
            ofItemAtPath: url.path
        )
    }
}
