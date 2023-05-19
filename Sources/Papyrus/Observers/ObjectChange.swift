public enum ObjectChange<T: Papyrus>: Equatable {
    case deleted
    case changed(T)
    case created(T)
}

