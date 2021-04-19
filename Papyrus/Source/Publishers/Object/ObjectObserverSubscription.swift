//
//  ObjectObserverSubscription.swift
//  Papyrus
//
//  Created by Red Davis on 15/04/2021.
//

import Combine
import Foundation


final class ObjectObserverSubscription<T: Subscriber, Output>: Subscription
where T.Input == Output, T.Failure == PapyrusStore.QueryError, Output: Papyrus & Equatable
{
    // Private
    private let fileManager = FileManager.default
    private let filename: String
    private let directoryURL: URL
    private var subscriber: T?
    private var demand: Subscribers.Demand = .none
    private var previousFetch: Result<Output, PapyrusStore.QueryError>?
    
    private let directoryObserverDispatchQueue = DispatchQueue(
        label: "com.reddavis.PapyrusStore.ObjectObserverSubscription.directoryObserverDispatchQueue.\(UUID())",
        qos: .background
    )
    private var directoryObserver: DispatchSourceFileSystemObject?
    
    // MARK: Initialization
    
    init(
        filename: String,
        directoryURL: URL,
        subscriber: T
    )
    {
        self.filename = filename
        self.directoryURL = directoryURL
        self.subscriber = subscriber
    }
    
    // MARK: Setup
    
    private func startDirectoryObserver()
    {
        if !self.fileManager.fileExists(atPath: self.directoryURL.path)
        {
            try? self.fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
        }
        
        let fileDesciptor = open(self.directoryURL.path, O_EVTONLY)
        self.directoryObserver = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDesciptor,
            eventMask: [.attrib],
            queue: self.directoryObserverDispatchQueue
        )
        self.directoryObserver?.setEventHandler { [weak self] in
            self?.processNextRequest()
        }
        self.directoryObserver?.resume()
    }
    
    // MARK: Subscriber
    
    func cancel()
    {
        self.subscriber = nil
        self.directoryObserver?.cancel()
    }
    
    func request(_ demand: Subscribers.Demand)
    {
        self.demand = demand
        self.processNextRequest()
        self.startDirectoryObserver()
    }
    
    // MARK: Data
    
    private func processNextRequest()
    {
        guard let subscriber = self.subscriber else { return }
        guard self.demand > 0 else
        {
            subscriber.receive(completion: .finished)
            return
        }
        
        do
        {
            let object = try self.fetchObject()
            
            // Check the object has changed
            guard self.previousFetch != .success(object) else { return }
            
            self.demand -= 1
            self.demand += subscriber.receive(object)
            self.previousFetch = .success(object)
        }
        catch let error as PapyrusStore.QueryError
        {
            guard self.previousFetch != .failure(error) else { return }
            subscriber.receive(completion: .failure(error))
        }
        catch { } // Only `PapyrusStore.QueryError` thrown
    }
    
    private func fetchObject() throws -> Output
    {
        let fileURL = self.directoryURL.appendingPathComponent(self.filename)
        guard self.fileManager.fileExists(atPath: fileURL.path) else { throw PapyrusStore.QueryError.notFound }
        
        do
        {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Output.self, from: data)
        }
        catch
        {
            // Cached data is using an old schema.
            try? self.fileManager.removeItem(at: fileURL)
            throw PapyrusStore.QueryError.notFound
        }
    }
}
