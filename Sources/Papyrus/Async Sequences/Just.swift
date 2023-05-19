/// An asynchronous sequence that only emits the provided value once.
///
/// ```swift
/// let stream = Just(1)
///
/// for await value in stream {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// ```
struct Just<Element>: AsyncSequence {
    private let element: Element
    private var emittedElement = false
    
    // MARK: Initialization
    
    /// Creates an async sequence that emits an element once.
    /// - Parameters:
    ///   - element: The element to emit.
    init(_ element: Element) {
        self.element = element
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    func makeAsyncIterator() -> Self {
        .init(self.element)
    }
}

extension Just: Sendable where Element: Sendable {}

// MARK: AsyncIteratorProtocol

extension Just: AsyncIteratorProtocol {
    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    mutating func next() async -> Element? {
        guard !self.emittedElement else { return nil }
        defer { self.emittedElement = true }
        
        return self.element
    }
}
