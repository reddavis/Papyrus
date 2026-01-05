import AsyncAlgorithms
import Foundation
import os

/// `ObjectQuery<T>` is a mechanism for querying a single `Papyrus` object.
public struct ObjectQuery<T: Papyrus>: Sendable {
    private let decoder: JSONDecoder = .init()
    private let directoryURL: URL
    private let filename: String
    private let logger: Logger

    // MARK: Initialization

    init<ID: LosslessStringConvertible>(
        id: ID,
        directoryURL: URL
    ) {
        self.filename = String(id)
        self.directoryURL = directoryURL
        self.logger = Logger(subsystem: "com.reddavis.PapyrusStore", category: "ObjectQuery")
    }

    // MARK: API

    /// Executes the query.
    /// - Returns: The result of the query.
    public func execute() -> T? {
        switch fetchObject() {
        case .success(let object):
            return object
        case .failure:
            return nil
        }
    }

    /// Observe changes to the query via an async stream.
    /// - Returns: A `AsyncThrowingStream` instance.
    public func observe() -> AsyncThrowingStream<ObjectChange<T>, Error> where T: Sendable {
        do {
            let observer = try DirectoryObserver(url: directoryURL)
            let object = fetchObject()
            let observerSequence = observer.observe()
                .map { fetchObject() }

            return chain(Just(object), observerSequence)
                .pair()
                .compactMap { tuple in
                    let previousResult = tuple.0
                    let result = tuple.1

                    switch (previousResult, result) {
                    case (.success(let previousModel), .success(let model)) where previousModel != model:
                        return .changed(model)
                    case (.success, .failure):
                        return .deleted
                    case (.failure, .success(let model)):
                        return .created(model)
                    default:
                        return nil
                    }
                }
                .eraseToThrowingStream()
        } catch {
            return Fail(error: error)
                .eraseToThrowingStream()
        }
    }

    private func fetchObject() -> Result<T, Error> {
        let fileManager = FileManager.default
        let fileURL = directoryURL.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.info("Cached data not found. url: \(fileURL)")
            return .failure(NotFoundError())
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            // Cached data is using an old schema.
            logger.error("Failed to parse cached data. url: \(fileURL)")
            do {
                // Delete cached data
                logger.debug("Deleting old cached data. url: \(fileURL)")
                try fileManager.removeItem(at: fileURL)
            } catch {
                logger.error("Failed deleting old cached data. url: \(fileURL) error: \(error)")
                return .failure(error)
            }
            return .failure(InvalidSchemaError(details: error))
        }
    }
}

// MARK: Errors

extension ObjectQuery {
    private struct NotFoundError: Error {}
    private struct InvalidSchemaError: Error {
        var details: Error
    }
}

// MARK: AsyncPairSequence

fileprivate struct AsyncPairSequence<Base: AsyncSequence>: AsyncSequence {
    typealias AsyncIterator = Iterator
    typealias Element = (Base.Element, Base.Element)
    var base: Base

    func makeAsyncIterator() -> AsyncIterator {
        Iterator(base: base.makeAsyncIterator())
    }
}

extension AsyncPairSequence: Sendable where Base: Sendable, Element: Sendable {}

// MARK: AsyncPairSequence Iterator

extension AsyncPairSequence {
    fileprivate struct Iterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var lastValue: Base.Element?

        mutating func next() async rethrows -> (Base.Element, Base.Element)? {
            guard let nextValue = try await base.next() else {
                return nil
            }

            guard let lastValue else {
                lastValue = nextValue
                guard let nextNextValue = try await base.next() else {
                    return nil
                }

                lastValue = nextNextValue
                return (nextValue, nextNextValue)
            }

            defer { self.lastValue = nextValue }
            return (lastValue, nextValue)
        }
    }
}

extension AsyncPairSequence.Iterator: Sendable
where Base.AsyncIterator: Sendable, Element: Sendable {}

extension AsyncSequence {
    fileprivate func pair() -> AsyncPairSequence<Self> {
        AsyncPairSequence(base: self)
    }
}
