import Foundation


extension Sequence {
    func filter(_ isIncluded: ((Element) throws -> Bool)?) rethrows -> [Element] {
        guard let isIncluded = isIncluded else { return Array(self) }
        return try self.filter { try isIncluded($0) }
    }
    
    func sorted(by areInIncreasingOrder: ((Element, Element) throws -> Bool)?) rethrows -> [Element] {
        guard let areInIncreasingOrder = areInIncreasingOrder else { return Array(self) }
        return try self.sorted { try areInIncreasingOrder($0, $1) }
    }
}
