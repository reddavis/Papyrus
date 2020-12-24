//
//  ObserverSubscription.swift
//  Papyrus
//
//  Created by Red Davis on 23/12/2020.
//

import Combine
import Foundation


extension PapyrusStore
{
    final class ObserverSubscription<T, Output>: Subscription where T: Subscriber, T.Input == [Output], Output: Papyrus
    {
        // Private
        private let fileManager = FileManager.default
        private let directoryURL: URL
        private var subscriber: T?
        private var demand: Subscribers.Demand = .none
        
        private let directoryObserverDispatchQueue = DispatchQueue(label: "com.reddavis.PapyrusStore.ObserverSubscription.directoryObserverDispatchQueue.\(UUID())", qos: .background)
        private var directoryObserver: DispatchSourceFileSystemObject?
        
        // MARK: Initialization
        
        init(directoryURL: URL, subscriber: T)
        {
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
            self.directoryObserver = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDesciptor, eventMask: [.attrib], queue: self.directoryObserverDispatchQueue)
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
                self.subscriber?.receive(completion: .finished)
                return
            }
            
            self.demand -= 1
            self.demand += subscriber.receive(self.fetchModels())
        }
        
        private func fetchModels() -> [Output]
        {
            guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path) else { return [] }
            let decoder = JSONDecoder()
            
            return directoryNames
                .map { self.directoryURL.appendingPathComponent($0) }
                .compactMap {
                    do
                    {
                        let data = try Data(contentsOf: $0)
                        return try decoder.decode(Output.self, from: data)
                    }
                    catch
                    {
                        // TODO: Delete file, it is likely old schema.
                        return nil
                    }
                }
        }
    }
}
