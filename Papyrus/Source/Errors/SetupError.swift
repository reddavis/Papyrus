import Foundation


extension PapyrusStore {
    
    /// Information about errors during `PapyrusStore` setup.
    enum SetupError: Error {
        
        /// Unable to create directory.
        /// A file already exists at the provided location.
        case fileExistsInDirectoryURL(URL)
    }
}
