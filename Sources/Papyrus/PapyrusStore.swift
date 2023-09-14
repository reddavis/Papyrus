import Foundation

/// A `PapyrusStore` is a data store for `Papyrus` conforming objects.
///
/// `PapyrusStore` aims to hit the sweet spot between saving raw API responses to the file system
/// and a fully fledged database like Realm.
public struct PapyrusStore: Sendable {
    private var fileManager: FileManager { .default }
    private let url: URL
    private let logger: Logger
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = .init()
    
    // MARK: Initialization
    
    /// Initialize a new `PapyrusStore` instance persisted at the provided `URL`.
    /// - Parameter url: The `URL` to persist data to.
    public init(url: URL, logLevel: LogLevel = .off) {
        self.url = url
        self.logger = Logger(
            subsystem: "com.reddavis.PapyrusStore",
            category: "PapyrusStore",
            logLevel: logLevel
        )
        self.setupDataDirectory()
    }
    
    /// Initialize a new `PapyrusStore` instance with the default
    /// storage directory.
    ///
    /// The default Papyrus Store will persist it's data to a
    /// directory inside Application Support.
    public init(logLevel: LogLevel = .off) {
        let url = URL.applicationSupportDirectory.appendingPathComponent("Papyrus", isDirectory: true)
        self.init(url: url, logLevel: logLevel)
    }
    
    // MARK: Store management
    
    private func setupDataDirectory() {
        do {
            try self.createDirectoryIfNeeded(at: self.url)
        } catch {
            self.logger.fault("Unable to create store directory: \(error)")
        }
    }
    
    /// Reset the store.
    ///
    /// This will destroy and then rebuild the store's directory.
    public func reset() throws {
        try self.fileManager.removeItem(at: self.url)
        self.setupDataDirectory()
    }
    
    // MARK: File management
    
    private func fileURL<ID: LosslessStringConvertible>(for typeDescription: String, id: ID) -> URL {
        self.fileURL(for: typeDescription, filename: String(id))
    }
    
    private func fileURL(for typeDescription: String, filename: String) -> URL {
        self.directoryURL(for: typeDescription).appendingPathComponent(filename)
    }
    
    private func directoryURL<T>(for type: T.Type) -> URL {
        self.directoryURL(for: String(describing: type))
    }
    
    private func directoryURL(for typeDescription: String) -> URL {
        self.url.appendingPathComponent(typeDescription, isDirectory: true)
    }
    
    private func createDirectoryIfNeeded<T>(for type: T.Type) throws {
        try self.createDirectoryIfNeeded(for: String(describing: type))
    }
    
    private func createDirectoryIfNeeded(for typeDescription: String) throws {
        try self.createDirectoryIfNeeded(at: self.directoryURL(for: typeDescription))
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        var isDirectory = ObjCBool(false)
        let exists = self.fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        // All good - directory already exists.
        if isDirectory.boolValue && exists { return }
        
        // A file already exists where we want to create our directory.
        else if !isDirectory.boolValue && exists { throw SetupError.fileExistsInDirectoryURL(url) }
        
        // Create directory
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        self.logger.debug("Created directory: \(url.absoluteString)")
    }
    
    // MARK: Saving
    
    /// Saves the object to the store.
    /// - Parameter object: The object to save.
    public func save<T: Papyrus>(_ object: T) async throws {
        try await self.save(objects: [object])
    }
    
    /// Saves all objects to the store.
    /// - Parameter objects: An array of objects to add to the store.
    public func save<T: Papyrus>(objects: [T]) async throws where T: Sendable {
        try await withThrowingTaskGroup(of: Void.self) { group in
            try self.createDirectoryIfNeeded(for: T.self)
            
            for object in objects {
                group.addTask {
                    let data = try self.encoder.encode(object)
                    let url = self.fileURL(for: object.typeDescription, filename: object.filename)
                    try data.write(to: url)
                    self.logger.debug("Saved: \(object.typeDescription) [Filename: \(object.filename)]")
                }
            }
            
            try await group.waitForAll()
            try self.fileManager.setAttributes(
                [.modificationDate: Date.now],
                ofItemAtPath: self.directoryURL(for: T.self).path
            )
        }
    }
    
    // MARK: Fetching
    
    /// Creates a `ObjectQuery<T>` instance for an object of the
    /// type inferred and id provided.
    /// - Parameter id: The `id` of the object.
    /// - Returns: A `ObjectQuery<T>` instance.
    public func object<T: Papyrus, ID: LosslessStringConvertible>(id: ID) -> ObjectQuery<T> {
        ObjectQuery(id: id, directoryURL: self.directoryURL(for: T.self))
    }
    
    /// Creates a `ObjectQuery<T>` instance for an object of the
    /// type and id provided.
    /// - Parameters:
    ///   - id: The `id` of the object.
    ///   - type: The `type` of the object.
    /// - Returns: A `ObjectQuery<T>` instance.
    public func object<T: Papyrus, ID: LosslessStringConvertible>(id: ID, of type: T.Type) -> ObjectQuery<T> {
        ObjectQuery(id: id, directoryURL: self.directoryURL(for: T.self))
    }
    
    /// Returns a `PapyrusCollection<T>` instance of all objects of
    /// the given type.
    /// - Parameter type: The type of objects to fetch.
    /// - Returns: A `AnyPublisher<[T], Error>` instance.
    public func objects<T: Papyrus>(type: T.Type) -> CollectionQuery<T> {
        CollectionQuery(directoryURL: self.directoryURL(for: T.self))
    }
    
    // MARK: Deleting
    
    /// Deletes an object with `id` and of `type` from the store.
    /// - Parameters:
    ///   - id: The `id` of the object to be deleted.
    ///   - type: The `type` of the object to be deleted.
    public func delete<T: Papyrus, ID>(
        id: ID,
        of type: T.Type
    ) async throws where ID: LosslessStringConvertible & Hashable & Sendable {
        try await self.delete(objectIdentifiers: [id: type])
    }

    /// Deletes an object from the store.
    /// - Parameter object: The object to delete.
    public func delete<T: Papyrus>(_ object: T) async throws {
        try await self.delete(objectIdentifiers: [object.id: T.self])
    }
    
    /// Deletes an array of objects.
    /// - Parameter objects: An array of objects to delete.
    public func delete<T: Papyrus, ID>(objects: [T]) async throws where ID == T.ID {
        let identifiers = objects.reduce(into: [ID: T.Type]()) {
            $0[$1.id] = T.self
        }
        try await self.delete(objectIdentifiers: identifiers)
    }
    
    public func deleteAll<T: Papyrus>(_ type: T.Type) throws {
        try self.fileManager.removeItem(at: self.directoryURL(for: type))
    }
    
    private func delete<ID, T: Papyrus>(
        objectIdentifiers: [ID: T.Type]
    ) async throws where ID: LosslessStringConvertible & Sendable {
        guard !objectIdentifiers.isEmpty else { return }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let touchedDirectories = Set(objectIdentifiers.map {
                self.directoryURL(for: $0.value)
            })
            
            for (id, type) in objectIdentifiers {
                group.addTask {
                    let url = self.fileURL(for: String(describing: type), id: id)
                    try self.fileManager.removeItem(at: url)
                    self.logger.debug("Deleted: \(url)")
                }
            }
            
            try await group.waitForAll()
            
            // Touch all changed directories
            self.logger.debug("Touching directories: \(touchedDirectories)")
            
            let now = Date()
            for url in touchedDirectories {
                try self.fileManager.setAttributes([.modificationDate: now], ofItemAtPath: url.path)
            }
        }
    }
    
    // MARK: Merging
    
    /// Merge new data with old data.
    ///
    /// Useful when syncing with an API.
    /// The merge will:
    ///   - Update objects that exist in the store and exist in `objects`.
    ///   - Create objects that do not exist in the store and exist in `objects`.
    ///   - Delete objects that exist in the store but do not exist in `objects`.
    /// - Parameter objects: An array of objects to merge.
    public func merge<T: Papyrus>(
        with objects: [T]
    ) async throws where T: Sendable {
        let objectIDs = objects.map(\.id)
        let objectsToDelete = try self.objects(type: T.self)
            .filter { !objectIDs.contains($0.id) }
            .execute()
        
        try await withThrowingTaskGroup(of: Void.self, body: { group in
            group.addTask {
                try await self.delete(objects: objectsToDelete)
            }
            group.addTask {
                try await self.save(objects: objects)
            }
            
            for try await _ in group {} // So we can throw errors
        })
    }
    
    /// Merge new data with a subset of old data.
    ///
    /// Useful when syncing with an API.
    /// The merge will:
    ///   - Update objects that exist in the filtered store and exist in `objects`.
    ///   - Create objects that do not exist in the filtered store and exist in `objects`.
    ///   - Delete objects that exist in the filtered store but do not exist in `objects`.
    /// - Parameters:
    ///   - objects: An array of objects to merge.
    ///   - filter: The filter to be applied when calculating the subset
    ///   of stored objects to merge into.
    public func merge<T: Papyrus>(
        objects: [T],
        into filter: @escaping (_ object: T) -> Bool
    ) async throws where T: Sendable {
        let objectIDs = objects.map(\.id)
        let objectsToDelete = try self.objects(type: T.self)
            .filter { !objectIDs.contains($0.id) && filter($0) }
            .execute()
        
        try await withThrowingTaskGroup(of: Void.self, body: { group in
            group.addTask {
                try await self.delete(objects: objectsToDelete)
            }
            group.addTask {
                try await self.save(objects: objects)
            }
            
            try await group.waitForAll()
        })
    }
}

// MARK: Setup error

extension PapyrusStore {
    /// Information about errors during `PapyrusStore` setup.
    public enum SetupError: Error {
        /// Unable to create directory.
        /// A file already exists at the provided location.
        case fileExistsInDirectoryURL(URL)
    }
}

// MARK: Query error

extension PapyrusStore {
    /// `PapyrusStore` query error.
    public enum QueryError: Error {
        
        /// Object not found
        case notFound
        
        /// Invalid schema
        case invalidSchema(details: Error)
    }
}
