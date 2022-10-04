import Foundation

@propertyWrapper
struct Atomic<Value> {
    private let lock = NSLock()
    private var value: Value
    
    var wrappedValue: Value {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.value
        }
        
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.value = newValue
        }
    }
    
    // MARK: Initialization
    
    init(wrappedValue value: Value) {
        self.value = value
    }
}
