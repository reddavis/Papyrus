//
//  PapyrusStore.swift
//  Papyrus
//
//  Created by Red Davis on 16/12/2020.
//

import Foundation


/// A `PapyrusStore` is a data store for `Papyrus` conforming objects.
///
/// `PapyrusStore` aims to hit the sweet spot between saving raw API responses to the file system
/// and a fully fledged database like Realm.
public final class PapyrusStore
{
    // Public
    
    /// The verboseness of the logger.
    public var logLevel: Logger.LogLevel {
        get { self.logger.logLevel }
        set { self.logger.logLevel = newValue }
    }
    
    // Private
    private let fileManager = FileManager.default
    private let writeQueue = DispatchQueue(label: "com.reddavis.Papyrus.writeQueue.\(UUID())", qos: .background)
    private let cacheWriteQueue = DispatchQueue(label: "com.reddavis.Papyrus.cacheWriteQueue.\(UUID())", qos: .background)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var idsQueuedForDeletion = Set<CacheKey>()
    
    private let memoryCache: NSCache<CacheKey, PapyrusCacheWrapper> = {
        let cache = NSCache<CacheKey, PapyrusCacheWrapper>()
        cache.totalCostLimit = 20 * 1024 * 1024
        
        return cache
    }()
    
    private let url: URL
    private let logger: Logger
    
    // MARK: Initialization
    
    /// Initialize a new `PapyrusStore` instance persisted at the provided `URL`.
    /// - Parameter url: The `URL` to persist data to.
    /// - Throws: Error when unable to create storage directory.
    public init(url: URL) throws
    {
        self.url = url
        self.logger = Logger(subsystem: "com.reddavis.PapyrusStore", category: "PapyrusStore")
        try self.setupDataDirectory()
    }
    
    /// Initialize a new `PapyrusStore` instance with the default
    /// storage directory.
    ///
    /// The default Papyrus Store will persist it's data to a
    /// directory inside Application Support.
    /// - Throws: Error when unable to create storage directory.
    public convenience init() throws
    {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Papyrus", isDirectory: true)
        try self.init(url: url)
    }
    
    // MARK: Setup
    
    private func setupDataDirectory() throws
    {
        try self.createDirectoryIfNeeded(at: self.url)
    }
    
    // MARK: File management
    
    private func fileURL(for object: Papyrus) -> URL
    {
        self.fileURL(for: String(describing: type(of: object)), id: object.id)
    }
    
    private func fileURL(for typeDescription: String, id: String) -> URL
    {
        self.directoryURL(for: typeDescription).appendingPathComponent(id)
    }
    
    private func directoryURL<T>(for type: T.Type) -> URL
    {
        self.directoryURL(for: String(describing: type))
    }
    
    private func directoryURL(for typeDescription: String) -> URL
    {
        self.url.appendingPathComponent(typeDescription, isDirectory: true)
    }
    
    private func createDirectoryIfNeeded(for typeDescription: String) throws
    {
        try self.createDirectoryIfNeeded(at: self.directoryURL(for: typeDescription))
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws
    {
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
}

// MARK: Saving

public extension PapyrusStore
{
    /// Saves the object to the store.
    /// - Parameter object: The object to save.
    func save<T>(_ object: T) where T: Papyrus
    {
        // Pre-warm cache
        self.cache(object)
        
        // Write to file system
        var touchedDirectories = Set([self.directoryURL(for: T.self)])
        
        let root = PapyrusEncodingWrapper(object)
        self.save(root, id: object.id)
        self.logger.debug("Saved: \(String(describing: type(of: object))) [\(object.id)]")
        
        // Store any Papyrus relationships.
        Mirror.reflectProperties(of: object, matchingType: Papyrus.self, recursively: true) {
            let encodable = PapyrusEncodingWrapper($0)
            self.save(encodable, id: $0.id)
            
            touchedDirectories.insert(self.directoryURL(for: String(describing: type(of: $0))))
        }
        
        // Touch all changed directories
        self.logger.debug("Touching directories: \(touchedDirectories)")
        
        let now = Date()
        touchedDirectories.forEach {
            try? self.fileManager.setAttributes([.modificationDate : now], ofItemAtPath: $0.path)
        }
    }
    
    /// Eventually saves the object to the store.
    /// - Parameter object: The object to save.
    func saveEventually<T>(_ object: T) where T: Papyrus
    {
        self.writeQueue.async {
            self.save(object)
        }
    }
    
    /// Saves all objects to the store.
    /// - Parameter objects: An array of objects to add to the store.
    func save<T>(objects: [T]) where T: Papyrus
    {
        objects.forEach(self.save)
    }
    
    /// Eventually saves all objects to the store.
    /// - Parameter objects: An array of objects to add to the store.
    func saveEventually<T>(objects: [T]) where T: Papyrus
    {
        self.writeQueue.async {
            objects.forEach(self.save)
        }
    }
    
    private func save(_ object: PapyrusEncodingWrapper, id: String)
    {
        do
        {
            try self.createDirectoryIfNeeded(for: object.typeDescription)
            let data = try self.encoder.encode(object)
            try data.write(to: self.fileURL(for: object.typeDescription, id: id))
            
            self.logger.debug("Saved: \(object.typeDescription) [\(id)]")
        }
        catch
        {
            self.logger.fault("Failed to save: \(error)")
        }
    }
}

// MARK: Fetching

public extension PapyrusStore
{
    /// Retrieves an object, by its `id`, from the store.
    ///
    /// `nil` is returned if the object does not exist.
    /// - Parameter id: The `id` of the object.
    /// - Returns: The object of type `T` or nil if no object is found.
    func object<T>(id: String) -> T? where T: Papyrus
    {
        // Check if the object has been queued for deletion
        let key = CacheKey(id: id, type: T.self)
        guard !self.idsQueuedForDeletion.contains(key) else { return nil }
        
        if let object = self.fetchCachedObject(id: id) as T? { return object }
        
        let url = self.fileURL(for: String(describing: T.self), id: id)
        guard self.fileManager.fileExists(atPath: url.path) else { return nil }
        
        // Load data
        do
        {
            let data = try Data(contentsOf: url)
            let object = try self.decoder.decode(T.self, from: data)
            
            // Cache object
            self.cacheWriteQueue.async { self.cache(object) }
            
            return object
        }
        catch
        {
            try? self.fileManager.removeItem(at: url)
            return nil
        }
    }
    
    /// Retrieves an object, by its `id`, from the store.
    /// - Parameters:
    ///   - id: The `id` of the object.
    ///   - type: The `type` of the object.
    /// - Returns: The object of `type` or nil if no object is found.
    func object<T>(id: String, of type: T.Type) -> T? where T: Papyrus
    {
        self.object(id: id)
    }
    
    /// Returns a `PapyrusCollection<T>` instance of all objects of
    /// the given type.
    /// - Parameter type: The type of objects to fetch.
    /// - Returns: A `PapyrusCollection<T>` instance.
    func objects<T>(type: T.Type) -> Query<T>
    {
        Query(directoryURL: self.directoryURL(for: T.self))
    }
}

// MARK: Deleting

public extension PapyrusStore
{
    /// Deletes an object with `id` and of `type` from the store.
    /// - Parameters:
    ///   - id: The `id` of the object to be deleted.
    ///   - type: The `type` of the object to be deleted.
    func delete<T>(id: String, of type: T.Type) where T: Papyrus
    {
        self.delete(objectIdentifiers: [id : type])
    }
    
    /// Eventually deletes an object with `id` and of `type` from the store.
    /// - Parameters:
    ///   - id: The `id` of the object to be deleted.
    ///   - type: The `type` of the object to be deleted.
    func deleteEventually<T>(id: String, of type: T.Type) where T: Papyrus
    {
        self.writeQueue.async {
            self.delete(id: id, of: type)
        }
    }
    
    /// Deletes an object from the store.
    /// - Parameter object: The object to delete.
    func delete<T>(_ object: T) where T: Papyrus
    {
        self.delete(objectIdentifiers: [object.id : T.self])
    }
    
    /// Eventually deletes an object from the store.
    /// - Parameter object: The object to delete.
    func deleteEventually<T>(_ object: T) where T: Papyrus
    {
        self.writeQueue.async {
            self.delete(object)
        }
    }
    
    /// Deletes an array of objects.
    /// - Parameter objects: An array of objects to delete.
    func delete<T>(objects: [T]) where T: Papyrus
    {
        let identifiers = objects.reduce(into: [String : T.Type]()) {
            $0[$1.id] = T.self
        }
        self.delete(objectIdentifiers: identifiers)
    }
    
    /// Eventually deletes an array of objects.
    /// - Parameter objects: An array of objects to delete.
    func eventuallyDelete<T>(objects: [T]) where T: Papyrus
    {
        self.writeQueue.async {
            self.delete(objects: objects)
        }
    }
    
    private func delete<T>(objectIdentifiers: [String : T.Type]) where T: Papyrus
    {
        objectIdentifiers.forEach {
            self.removeCachedObject(id: $0.key, type: $0.value)
        }
        
        let touchedDirectories = Set(objectIdentifiers.map {
            self.directoryURL(for: $0.value)
        })
        
        objectIdentifiers.forEach {
            let url = self.fileURL(for: String(describing: $0.value), id: $0.key)
            try? self.fileManager.removeItem(at: url)
        }
        
        // Touch all changed directories
        self.logger.debug("Touching directories: \(touchedDirectories)")
        
        let now = Date()
        touchedDirectories.forEach {
            try? self.fileManager.setAttributes([.modificationDate : now], ofItemAtPath: $0.path)
        }
    }
}

// MARK: Merging

public extension PapyrusStore
{
    func merge<T>(with objects: [T]) where T: Papyrus
    {
        let objectIDs = objects.map(\.id)
        let objectsToDelete = self.objects(type: T.self)
            .filter { !objectIDs.contains($0.id) }
            .execute()
        
        self.delete(objects: objectsToDelete)
        self.save(objects: objects)
    }
    
    func mergeEventually<T>(with objects: [T]) where T: Papyrus
    {
        self.writeQueue.async {
            self.merge(with: objects)
        }
    }
}

// MARK: Cache

private extension PapyrusStore
{
    func cache<T>(_ object: T) where T: Papyrus
    {
        let wrapper = PapyrusCacheWrapper(object)
        let key = CacheKey(object: object)
        self.memoryCache.setObject(wrapper, forKey: key)
        
        self.logger.debug("Cached: \(String(describing: type(of: object))) [\(object.id)]")
    }
    
    func fetchCachedObject<T>(id: String) -> T? where T: Papyrus
    {
        let key = CacheKey(id: id, type: T.self)
        guard let wrapper = self.memoryCache.object(forKey: key),
              let object = wrapper.object as? T else
        {
            return nil
        }
        
        return object
    }
    
    func removeCachedObject<T>(id: String, type: T.Type) where T: Papyrus
    {
        let key = CacheKey(id: id, type: type)
        self.memoryCache.removeObject(forKey: key)
    }
}
