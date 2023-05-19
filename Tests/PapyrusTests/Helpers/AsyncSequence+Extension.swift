extension AsyncSequence {
    func first() async rethrows -> Element? {
        try await self.first { _ in
            true
        }
    }
    
    /// The last element of the sequence, if there is one.
    func last() async rethrows -> Element? {
        var latestElement: Element?
        for try await element in self {
            latestElement = element
        }
        
        return latestElement
    }
    
    func collect(_ numberOfElements: Int? = .none) async rethrows -> [Element] {
        var results: [Element] = []
        for try await element in self {
            results.append(element)
            
            if let numberOfElements = numberOfElements,
               results.count >= numberOfElements {
               break
            }
        }
        
        return results
    }
    
    @discardableResult
    func sink(
        priority: TaskPriority? = nil,
        receiveValue: @Sendable @escaping (Element) async -> Void
    ) -> Task<Void, Error> where Self: Sendable {
        Task(priority: priority) {
            for try await element in self {
                await receiveValue(element)
                try Task.checkCancellation()
            }
        }
    }    
}
