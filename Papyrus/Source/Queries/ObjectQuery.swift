//
//  ObjectQuery.swift
//  Papyrus
//
//  Created by Red Davis on 16/04/2021.
//

import Combine
import Foundation


/// `PapyrusStore.ObjectQuery<T>` is a mechanism for querying a single `Papyrus` object.
public extension PapyrusStore
{
    class ObjectQuery<T: Papyrus>
    {
        // Private
        private let fileManager = FileManager.default
        private let filename: String
        private let directoryURL: URL
        
        // MARK: Initialization
        
        init<ID: Hashable>(
            id: ID,
            directoryURL: URL
        )
        {
            self.filename = String(id.hashValue)
            self.directoryURL = directoryURL
        }
        
        // MARK: API
        
        /// Executes the query. If filter or sort parameters are
        /// set, they will be applied to the results.
        /// - Returns: The results of the query.
        public func execute() throws -> T
        {
            let fileURL = self.directoryURL.appendingPathComponent(self.filename)
            guard self.fileManager.fileExists(atPath: fileURL.path) else { throw PapyrusStore.QueryError.notFound }
            
            do
            {
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(T.self, from: data)
            }
            catch
            {
                // Cached data is using an old schema.
                try? self.fileManager.removeItem(at: fileURL)
                throw PapyrusStore.QueryError.notFound
            }
        }
        
        /// Observe changes to the query.
        /// - Returns: A publisher that emits values when
        /// valid objects are changed.
        public func publisher() -> AnyPublisher<T, PapyrusStore.QueryError>
        {
            ObjectObserverPublisher(
                filename: self.filename,
                directoryURL: self.directoryURL
            )
            .eraseToAnyPublisher()
        }
    }
}
