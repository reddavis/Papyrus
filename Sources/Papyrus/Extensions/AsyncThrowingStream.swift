// Thanks - https://github.com/pointfreeco/swift-dependencies
extension AsyncThrowingStream where Element: Sendable, Failure == Error {
    init<S: AsyncSequence & Sendable>(
        _ sequence: S
    ) where S.Element == Element, S.Element: Sendable {
        self.init { continuation in
            let task = Task {
                do {
                    for try await element in sequence {
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
    func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}
