extension AsyncSequence {
    func eraseToStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }
    
    func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}
