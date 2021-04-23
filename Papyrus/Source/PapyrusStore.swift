//
//  PapyrusStore.swift
//  Papyrus
//
//  Created by Red Davis on 16/12/2020.
//

import Combine
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
    public init(url: URL)
    {
        self.url = url
        self.logger = Logger(
            subsystem: "com.reddavis.PapyrusStore",
            category: "PapyrusStore"
        )
        self.setupDataDirectory()
    }
    
    /// Initialize a new `PapyrusStore` instance with the default
    /// storage directory.
    ///
    /// The default Papyrus Store will persist it's data to a
    /// directory inside Application Support.
    public convenience init()
    {
        let url = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Papyrus", isDirectory: true)
        self.init(url: url)
    }
    
    // MARK: Setup
    
    private func setupDataDirectory()
    {
        do
        {
            try self.createDirectoryIfNeeded(at: self.url)
        }
        catch
        {
            self.logger.fault("Unable to create store directory: \(error)")
        }
    }
    
    // MARK: File management
    
    private func fileURL<ID: LosslessStringConvertible>(for typeDescription: String, id: ID) -> URL
    {
        self.fileURL(for: typeDescription, filename: String(id))
    }
    
    private func fileURL(for typeDescription: String, filename: String) -> URL
    {
        self.directoryURL(for: typeDescription).appendingPathComponent(filename)
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
    func save<T: Papyrus>(_ object: T)
    {
        // Pre-warm cache
        self.cache(object)
        
        // Write to file system
        var touchedDirectories = Set([self.directoryURL(for: T.self)])
        
        let root = PapyrusEncodingWrapper(object: object)
        self.save(root, filename: root.filename)
        
        // Store any Papyrus relationships.
        Mirror.reflectProperties(of: object, matchingType: PapyrusEncodingWrapper.self, recursively: true) {
            self.save($0, filename: $0.filename)
            touchedDirectories.insert(self.directoryURL(for: $0.typeDescription))
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
    func saveEventually<T: Papyrus>(_ object: T)
    {
        self.writeQueue.async {
            self.save(object)
        }
    }
    
    /// Saves all objects to the store.
    /// - Parameter objects: An array of objects to add to the store.
    func save<T: Papyrus>(objects: [T])
    {
        objects.forEach(self.save)
    }
    
    /// Eventually saves all objects to the store.
    /// - Parameter objects: An array of objects to add to the store.
    func saveEventually<T: Papyrus>(objects: [T])
    {
        self.writeQueue.async {
            objects.forEach(self.save)
        }
    }
    
    private func save(_ object: PapyrusEncodingWrapper, filename: String)
    {
        do
        {
            try self.createDirectoryIfNeeded(for: object.typeDescription)
            let data = try self.encoder.encode(object)
            try data.write(to: self.fileURL(for: object.typeDescription, filename: filename))
            self.logger.debug("Saved: \(object.typeDescription) [Filename: \(filename)]")
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
    /// Creates a `ObjectQuery<T>` instance for an object of the
    /// type inferred and id provided.
    /// - Parameter id: The `id` of the object.
    /// - Returns: A `ObjectQuery<T>` instance.
    func object<T: Papyrus, ID: LosslessStringConvertible>(id: ID) -> ObjectQuery<T>
    {
        ObjectQuery(id: id, directoryURL: self.directoryURL(for: T.self))
    }
    
    /// Creates a `ObjectQuery<T>` instance for an object of the
    /// type and id provided.
    /// - Parameters:
    ///   - id: The `id` of the object.
    ///   - type: The `type` of the object.
    /// - Returns: A `ObjectQuery<T>` instance.
    func object<T: Papyrus, ID: LosslessStringConvertible>(id: ID, of type: T.Type) -> ObjectQuery<T>
    {
        ObjectQuery(id: id, directoryURL: self.directoryURL(for: T.self))
    }
    
    /// Returns a `PapyrusCollection<T>` instance of all objects of
    /// the given type.
    /// - Parameter type: The type of objects to fetch.
    /// - Returns: A `AnyPublisher<[T], Error>` instance.
    func objects<T: Papyrus>(type: T.Type) -> CollectionQuery<T>
    {
        CollectionQuery(directoryURL: self.directoryURL(for: T.self))
    }
}

// MARK: Deleting

public extension PapyrusStore
{
    /// Deletes an object with `id` and of `type` from the store.
    /// - Parameters:
    ///   - id: The `id` of the object to be deleted.
    ///   - type: The `type` of the object to be deleted.
    func delete<T: Papyrus, ID: LosslessStringConvertible & Hashable>(id: ID, of type: T.Type)
    {
        self.delete(objectIdentifiers: [id : type])
    }
    
    /// Eventually deletes an object with `id` and of `type` from the store.
    /// - Parameters:
    ///   - id: The `id` of the object to be deleted.
    ///   - type: The `type` of the object to be deleted.
    func deleteEventually<T: Papyrus>(id: String, of type: T.Type)
    {
        self.writeQueue.async {
            self.delete(id: id, of: type)
        }
    }
    
    /// Deletes an object from the store.
    /// - Parameter object: The object to delete.
    func delete<T: Papyrus>(_ object: T)
    {
        self.delete(objectIdentifiers: [object.id : T.self])
    }
    
    /// Eventually deletes an object from the store.
    /// - Parameter object: The object to delete.
    func deleteEventually<T: Papyrus>(_ object: T)
    {
        self.writeQueue.async {
            self.delete(object)
        }
    }
    
    /// Deletes an array of objects.
    /// - Parameter objects: An array of objects to delete.
    func delete<T: Papyrus, ID>(objects: [T]) where ID == T.ID
    {
        let identifiers = objects.reduce(into: [ID : T.Type]()) {
            $0[$1.id] = T.self
        }
        self.delete(objectIdentifiers: identifiers)
    }
    
    /// Eventually deletes an array of objects.
    /// - Parameter objects: An array of objects to delete.
    func deleteEventually<T: Papyrus>(objects: [T])
    {
        self.writeQueue.async {
            self.delete(objects: objects)
        }
    }
    
    private func delete<ID: LosslessStringConvertible, T: Papyrus>(objectIdentifiers: [ID : T.Type])
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
            
            self.logger.debug("Deleted: \(url)")
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
    
    func fetchCachedObject<ID: LosslessStringConvertible, T: Papyrus>(id: ID) -> T?
    {
        let key = CacheKey(id: id, type: T.self)
        guard let wrapper = self.memoryCache.object(forKey: key),
              let object = wrapper.object as? T else
        {
            return nil
        }
        
        return object
    }
    
    func removeCachedObject<ID: LosslessStringConvertible, T: Papyrus>(id: ID, type: T.Type)
    {
        let key = CacheKey(id: id, type: type)
        self.memoryCache.removeObject(forKey: key)
    }
}
