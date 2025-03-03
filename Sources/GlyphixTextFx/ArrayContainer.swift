//
//  Created by ktiays on 2024/11/17.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation

final class ArrayContainer<T>: Sequence, ExpressibleByArrayLiteral {
    private var array: [T]

    var isEmpty: Bool {
        array.isEmpty
    }

    init(_ array: [T] = []) {
        self.array = array
    }

    init(arrayLiteral elements: T...) {
        array = elements
    }

    @inlinable
    func append(_ newElement: T) {
        array.append(newElement)
    }

    @inlinable
    func remove(at index: Int) -> T {
        array.remove(at: index)
    }

    @inlinable
    func removeAll(keepingCapacity: Bool = false) {
        array.removeAll(keepingCapacity: keepingCapacity)
    }

    @inlinable
    func first(where predicate: (T) throws -> Bool) rethrows -> T? {
        try array.first(where: predicate)
    }

    @inlinable
    func removeAll(where shouldBeRemoved: (T) throws -> Bool) rethrows {
        try array.removeAll(where: shouldBeRemoved)
    }

    func makeIterator() -> IndexingIterator<[T]> {
        array.makeIterator()
    }
}
