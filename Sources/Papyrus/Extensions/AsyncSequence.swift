// Thanks - https://github.com/pointfreeco/swift-dependencies
extension AsyncSequence {
    func eraseToStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }
    
    func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}
