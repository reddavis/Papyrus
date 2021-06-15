//
//  PapyrusCollection.swift
//  Papyrus
//
//  Created by Red Davis on 04/01/2021.
//

import Combine
import Foundation


/// `PapyrusStore.CollectionQuery<T>` is a mechanism for querying `Papyrus` objects.
public extension PapyrusStore
{
    class CollectionQuery<T> where T: Papyrus
    {
        // Public
        public typealias OnFilter = (T) throws -> Bool
        public typealias OnSort = (T, T) throws -> Bool
        
        // Private
        private let fileManager = FileManager.default
        private let directoryURL: URL
        private var filter: OnFilter?
        private var sort: OnSort?
        
        // MARK: Initialization
        
        init(directoryURL: URL)
        {
            self.directoryURL = directoryURL
        }
        
        // MARK: API
        
        /// Executes the query. If filter or sort parameters are
        /// set, they will be applied to the results.
        /// - Returns: The results of the query.
        public func execute() async -> [T]
        {
            guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path) else { return [] }
            let decoder = JSONDecoder()
            
            do
            {
                return try directoryNames
                    .map { self.directoryURL.appendingPathComponent($0) }
                    .compactMap {
                        do
                        {
                            let data = try Data(contentsOf: $0)
                            return try decoder.decode(T.self, from: data)
                        }
                        catch
                        {
                            // TODO: Delete file, it is likely old schema.
                            return nil
                        }
                    }
                    .filter(self.filter)
                    .sorted(by: self.sort)
            }
            catch
            {
                return []
            }
        }
        
        /// Apply a filter to the query.
        /// - Parameter onFilter: The filter to be applied.
        /// - Returns: The query item.
        public func filter(_ onFilter: @escaping OnFilter) -> Self
        {
            self.filter = onFilter
            return self
        }
        
        /// Apply a sort to the query.
        /// - Parameter onSort: The sort to be applied.
        /// - Returns: The query item.
        public func sort(_ onSort: @escaping OnSort) -> Self
        {
            self.sort = onSort
            return self
        }
        
        /// Observe changes to the query.
        /// - Returns: A publisher that emits values when
        /// valid objects are changed.
        public func publisher() -> AnyPublisher<[T], Never>
        {
            CollectionObserverPublisher(directoryURL: self.directoryURL)
                .tryMap { try $0.filter(self.filter) }
                .tryMap { try $0.sorted(by: self.sort) }
                .replaceError(with: [])
                .eraseToAnyPublisher()
        }
    }
}
