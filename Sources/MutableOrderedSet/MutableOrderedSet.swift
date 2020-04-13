// from https://stackoverflow.com/questions/59887561/how-to-implement-a-mutable-ordered-set-generic-type-formerly-known-as-nsmutableo
// author: https://stackoverflow.com/users/2303865/leo-dabus Leo Dabus
// theoretically available at https://github.com/leodabus/MutableOrderedSet

/// Quick Playground Test (OrderedSet should have all methods that are available to Swift native Array and Set structures)
/// 
/// var ordereSet1: OrderedSet = [1,2,3,4,5,6,1,2,3]  // [1, 2, 3, 4, 5, 6]
/// var ordereSet2: OrderedSet = [4,5,6,7,8,9,7,8,9]  // [4, 5, 6, 7, 8, 9]
///
/// ordereSet1 == ordereSet2                          // false
/// ordereSet1.union(ordereSet2)                      // [1, 2, 3, 4, 5, 6, 7, 8, 9]
///
/// ordereSet1.intersection(ordereSet2)               // [4, 5, 6]
/// ordereSet1.symmetricDifference(ordereSet2)        // [1, 2, 3, 7, 8, 9]
///
/// ordereSet1.subtract(ordereSet2)                   // [1, 2, 3]
/// ordereSet1.insert(contentsOf: [1,3,4,6], at: 0)   // [4, 6, 1, 2, 3]
///
/// ordereSet2.popLast()                              // 9
public protocol OrderedSetProtocol: MutableCollection,
                                    RandomAccessCollection,
                                    SetAlgebra,
                                    AdditiveArithmetic,
                                    RangeReplaceableCollection
                                    where Element: Hashable, Index == Int { }

public struct OrderedSet<Element: Hashable>: OrderedSetProtocol {
    public init() { }
    private var elements: [Element] = []
    private var set: Set<Element> = []
}

/*
 Conforming to the MutableCollection Protocol

 To add conformance to the MutableCollection protocol to your own custom collection, upgrade your type’s subscript to support both read and write access. A value stored into a subscript of a MutableCollection instance must subsequently be accessible at that same position. That is, for a mutable collection instance a, index i, and value x, the two sets of assignments in the following code sample must be equivalent:
 */
extension OrderedSet: MutableCollection {
    public subscript(index: Index) -> Element {
        get { elements[index] }
        set {
            guard set.update(with: newValue) == nil else {
                //
                // needs some implementation before returning
                // insert(remove(at: elements.firstIndex(of: newValue)!), at: index)
                //
                return
            }
            elements[index] = newValue
        }
    }
}
/*
 Conforming to the RandomAccessCollection Protocol

 The RandomAccessCollection protocol adds further constraints on the associated Indices and SubSequence types, but otherwise imposes no additional requirements over the BidirectionalCollection protocol. However, in order to meet the complexity guarantees of a random-access collection, either the index for your custom type must conform to the Strideable protocol or you must implement the index(_:offsetBy:) and distance(from:to:) methods with O(1) efficiency.
 */
extension OrderedSet: RandomAccessCollection {

    public typealias Index = Int
    public typealias Indices = Range<Int>

    public typealias SubSequence = Slice<OrderedSet<Element>>
    public typealias Iterator = IndexingIterator<Self>

    // Generic subscript to support `PartialRangeThrough`, `PartialRangeUpTo`, `PartialRangeFrom`
    public subscript<R: RangeExpression>(range: R) -> SubSequence where Index == R.Bound { .init(base: self, bounds: range.relative(to: self)) }

    public var endIndex: Index { elements.endIndex }
    public var startIndex: Index { elements.startIndex }

    public func formIndex(after i: inout Index) { elements.formIndex(after: &i) }

    public var isEmpty: Bool { elements.isEmpty }

    @discardableResult
    public mutating func append(_ newElement: Element) -> Bool { insert(newElement).inserted }
}
/*
 Conforming to the SetAlgebra Protocol

 When implementing a custom type that conforms to the SetAlgebra protocol, you must implement the required initializers and methods. For the inherited methods to work properly, conforming types must meet the following axioms. Assume that S is a custom type that conforms to the SetAlgebra protocol, x and y are instances of S, and e is of type S.Element—the type that the set holds.

 S() == [ ]

 x.intersection(x) == x

 x.intersection([ ]) == [ ]

 x.union(x) == x

 x.union([ ]) == x x.contains(e) implies x.union(y).contains(e)

 x.union(y).contains(e) implies x.contains(e) || y.contains(e)

 x.contains(e) && y.contains(e) if and only if x.intersection(y).contains(e)

 x.isSubset(of: y) implies x.union(y) == y

 x.isSuperset(of: y) implies x.union(y) == x

 x.isSubset(of: y) if and only if y.isSuperset(of: x)

 x.isStrictSuperset(of: y) if and only if x.isSuperset(of: y) && x != y

 x.isStrictSubset(of: y) if and only if x.isSubset(of: y) && x != y
 */
extension OrderedSet: SetAlgebra {
    public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let insertion = set.insert(newMember)
        if insertion.inserted { elements.append(newMember) }
        return insertion
    }
    public mutating func remove(_ member: Element) -> Element? {
        if let index = elements.firstIndex(of: member) {
            elements.remove(at: index)
            return set.remove(member)
        }
        return nil
    }
    public mutating func update(with newMember: Element) -> Element? {
        if let index = elements.firstIndex(of: newMember) {
            elements[index] = newMember
            return set.update(with: newMember)
        } else {
            elements.append(newMember)
            set.insert(newMember)
            return nil
        }
    }

    public func union(_ other: Self) -> Self {
        var orderedSet = self
        orderedSet.formUnion(other)
        return orderedSet
    }
    public func intersection(_ other: Self) -> Self { filter(other.contains) }
    public func symmetricDifference(_ other: Self) -> Self { filter { !other.set.contains($0) } + other.filter { !set.contains($0) } }

    public mutating func formUnion(_ other: Self) { other.forEach { self.append($0) } }
    public mutating func formIntersection(_ other: Self) { self = intersection(other) }
    public mutating func formSymmetricDifference(_ other: Self) { self = symmetricDifference(other) }
}
/*
 Conforming to ExpressibleByArrayLiteral

 Add the capability to be initialized with an array literal to your own custom types by declaring an init(arrayLiteral:) initializer. The following example shows the array literal initializer for a hypothetical OrderedSet type, which has setlike semantics but maintains the order of its elements.
 */
extension OrderedSet: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
    public init(arrayLiteral: Element...) {
        self.init()
        for element in arrayLiteral {
            self.append(element)
        }
    }
}

/*
Conforming to the AdditiveArithmetic Protocol

To add AdditiveArithmetic protocol conformance to your own custom type, implement the required operators, and provide a static zero property using a type that can represent the magnitude of any value of your custom type.
 */

extension OrderedSet: AdditiveArithmetic {
    public static var zero: Self { .init() }
    public static func + (lhs: Self, rhs: Self) -> Self { lhs.union(rhs) }
    public static func - (lhs: Self, rhs: Self) -> Self { lhs.subtracting(rhs) }
    public static func += (lhs: inout Self, rhs: Self) { lhs.formUnion(rhs) }
    public static func -= (lhs: inout Self, rhs: Self) { lhs.subtract(rhs) }
}
/*
 
Conforming to the RangeReplaceableCollection Protocol

To add RangeReplaceableCollection conformance to your custom collection, add an empty initializer and the replaceSubrange(:with:) method to your custom type. RangeReplaceableCollection provides default implementations of all its other methods using this initializer and method. For example, the removeSubrange(:) method is implemented by calling replaceSubrange(_:with:) with an empty collection for the newElements parameter. You can override any of the protocol’s required methods to provide your own custom implementation.
*/

extension OrderedSet: RangeReplaceableCollection {

    public init<S: Sequence>(_ elements: S) where S.Element == Element {
        elements.forEach { set.insert($0).inserted ? self.elements.append($0) : () }
    }

    mutating public func replaceSubrange<C: Collection, R: RangeExpression>(_ subrange: R, with newElements: C) where Element == C.Element, C.Element: Hashable, Index == R.Bound {
        elements[subrange].forEach { set.remove($0) }
        elements.removeSubrange(subrange)
        var index = subrange.relative(to: self).lowerBound
        newElements.forEach {
            if set.insert($0).inserted {
                elements.insert($0, at: index)
                formIndex(after: &index)
            }
        }
    }
/*
 Conforming to the CustomStringConvertible Protocol

 Add CustomStringConvertible conformance to your custom types by defining a description property.
 */
extension OrderedSet: CustomStringConvertible {
    public var description: String { .init(describing: elements) }
}
/*
 Conforming its Slice to CustomStringConvertible as well:
 */
extension Slice: CustomStringConvertible where Base: OrderedSetProtocol {
    public var description: String {
        var description = "["
        var first = true
        for element in self {
            if first {
                first = false
            } else {
                description += ", "
            }
            debugPrint(element, terminator: "", to: &description)
        }
        return description + "]"
    }
}
