// Thanks - https://github.com/pointfreeco/swift-dependencies
extension AsyncThrowingStream where Failure == Error {
    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        var iterator: S.AsyncIterator?
        self.init {
            if iterator == nil {
                iterator = sequence.makeAsyncIterator()
            }
            return try await iterator?.next()
        }
    }
}
