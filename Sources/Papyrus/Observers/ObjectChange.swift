public enum ObjectChange<T: Papyrus>: Equatable {
    case changed(T)
    case created(T)
    case deleted
}

extension ObjectChange: Sendable where T: Sendable {}
