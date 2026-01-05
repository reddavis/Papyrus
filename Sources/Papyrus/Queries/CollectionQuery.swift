import AsyncAlgorithms
import Foundation
import os

/// `PapyrusStore.CollectionQuery<T>` is a mechanism for querying `Papyrus` objects.
public struct CollectionQuery<T>: Sendable where T: Papyrus {
    public typealias OnFilter = @Sendable (T) -> Bool
    public typealias OnSort = @Sendable (T, T) -> Bool

    // Private
    private let decoder: JSONDecoder = .init()
    private let directoryURL: URL
    private let filter: OnFilter?
    private let logger: Logger
    private let sort: OnSort?

    // MARK: Initialization

    init(
        directoryURL: URL,
        filter: OnFilter? = nil,
        sort: OnSort? = nil
    ) {
        self.directoryURL = directoryURL
        self.filter = filter
        self.logger = Logger(subsystem: "com.reddavis.PapyrusStore", category: "CollectionQuery")
        self.sort = sort
    }

    // MARK: API

    /// Executes the query. If filter or sort parameters are
    /// set, they will be applied to the results.
    /// - Returns: The results of the query.
    public func execute() -> [T] {
        fetchObjects()
    }

    /// Apply a filter to the query.
    /// - Parameter onFilter: The filter to be applied.
    /// - Returns: The query item.
    public func filter(_ onFilter: @escaping OnFilter) -> Self {
        .init(
            directoryURL: directoryURL,
            filter: onFilter,
            sort: sort
        )
    }

    /// Apply a sort to the query.
    /// - Parameter onSort: The sort to be applied.
    /// - Returns: The query item.
    public func sort(_ onSort: @escaping OnSort) -> Self {
        .init(
            directoryURL: directoryURL,
            filter: filter,
            sort: onSort
        )
    }

    /// Observe changes to the query.
    /// - Returns: A `AsyncThrowingStream` instance.
    public func observe() -> AsyncThrowingStream<[T], Error> where T: Sendable {
        do {
            let observer = try DirectoryObserver(url: directoryURL)
            return observer.observe()
                .map { _ in fetchObjects() }
                .eraseToThrowingStream()
        } catch {
            return Fail(error: error)
                .eraseToThrowingStream()
        }
    }

    private func fetchObjects() -> [T] {
        do {
            let fileManager = FileManager.default
            let filenames = try fileManager.contentsOfDirectory(atPath: directoryURL.path)
            return filenames.reduce(into: [(Date, T)]()) { result, filename in
                let url = directoryURL.appendingPathComponent(filename)
                do {
                    let data = try Data(contentsOf: url)
                    let model = try decoder.decode(T.self, from: data)
                    let creationDate = try fileManager.attributesOfItem(
                        atPath: url.path
                    )[.creationDate] as? Date ?? .now
                    result.append((creationDate, model))
                } catch {
                    logger.error("Failed to read cached data. error: \(error)")
                    do {
                        // Delete cached data
                        logger.debug("Deleting old cached data. url: \(url)")
                        try fileManager.removeItem(at: url)
                    } catch {
                        logger.error("Failed deleting old cached data. url: \(url) error: \(error)")
                    }
                }
            }
            .sorted { $0.0 < $1.0 }
            .map(\.1)
            .filter(filter)
            .sorted(by: sort)
        } catch CocoaError.fileReadNoSuchFile {
            logger.info("Failed to read contents of directory. url: \(directoryURL)")
            return []
        } catch {
            logger.fault("Unknown error occured. error: \(error)")
            return []
        }
    }
}

// MARK: Sequence

extension Sequence {
    fileprivate func filter(_ isIncluded: ((Element) -> Bool)?) -> [Element] {
        guard let isIncluded = isIncluded else { return Array(self) }
        return filter { isIncluded($0) }
    }

    fileprivate func sorted(by areInIncreasingOrder: ((Element, Element) -> Bool)?) -> [Element] {
        guard let areInIncreasingOrder = areInIncreasingOrder else { return Array(self) }
        return sorted { areInIncreasingOrder($0, $1) }
    }
}
