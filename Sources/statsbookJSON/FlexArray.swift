//
//  File.swift
//  
//
//  Created by gandreas on 8/29/23.
//

import Foundation

/// Since we take values from fixed numbers of rows and columns, but don't want to store empty data
/// we have a fixed array that allows things to be trimmed/padded

/// An element needs to be able to be created
public protocol FlexArrayItem {
    init()
    var isEmpty : Bool { get }
    /// how many types of these items should exist (very useful for spreadsheets with fixed number of elements)
    static var maxItemCount : Int? { get }
}


public struct FlexArray<Element: FlexArrayItem> : Sequence, RandomAccessCollection, MutableCollection {
    public var startIndex: Int { 0 }
    
    // NB: Not same as count
    public var endIndex: Int { elements.count }
    
    public var count: Int {
        // if we have a specified count, we use that
        if let maxCount {
            return maxCount
        } else {
            return elements.count
        }
    }
    /// The updated elements
//    public private(set) var updated: [Element]
//    var getter: ()->[WrappedElement]
//    var setter: ([WrappedElement])->()
    var elements: [Element]
    /// The (maximum) count
    public var maxCount: Int? = Element.maxItemCount
    public init(maxCount: Int? = Element.maxItemCount, _ values: [Element]) {
        self.elements = values
        self.maxCount = maxCount
    }
    
    public subscript(index: Int) -> Element {
        get {
            if index >= elements.count {
                return Element()
            }
            return elements[index]
        }
        set {
            if let maxCount, index >= maxCount {
                return // drop elements past that mark
            }
            if elements.isEmpty {
                if index >= elements.count {
                    // don't extend
                } else if index == elements.count - 1 {
                    // remove the last element, and any other blank elements
                    _ = elements.popLast()
                    while elements.last?.isEmpty == true {
                        _ = elements.popLast()
                    }
                } else {
                    elements[index] = newValue
                }
            } else {
                // extend, if needed
                while index >= elements.count {
                    elements.append(Element())
                }
                elements[index] = newValue
            }
        }
    }
    
    /// Iterate over actual elements (so trailing blank elements are skipped)
    public struct FlexArrayIterator : IteratorProtocol {
        public mutating func next() -> Element? {
            index += 1
            if index >= fixedArray.endIndex {
                return nil
            }
            return fixedArray[index]
        }
        
        var index: Int
        var fixedArray: FlexArray<Element>
    }
    public func makeIterator() -> FlexArrayIterator {
        FlexArrayIterator(index: 0, fixedArray: self)
    }
}

extension FlexArray : Codable where Element : Codable {
    // unfortunately, coding loses the max explicit value
    public init(from decoder: Decoder) throws {
        maxCount = Element.maxItemCount
        elements = try [Element](from: decoder)
    }
    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

extension FlexArray : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        maxCount = Element.maxItemCount
        self.elements = elements
    }
// other useful initializers
    public init(_ elements: Element...) {
        maxCount = Element.maxItemCount
        self.elements = elements
    }

    public init() {
        maxCount = Element.maxItemCount
        self.elements = []
    }
}


#if canImport(SwiftUI)
import SwiftUI

// Compiler gets too confused with dynamic member lookup
//@dynamicMemberLookup
public struct IndexedElement<Element> : Identifiable {
    // we keep the index in the id
    public var id: Int
    public var element: Element
    public init(id: Int, element: Element) {
        self.id = id
        self.element = element
    }
//    /// Allow pass through of element access
//    public subscript<T>(dynamicMember path: WritableKeyPath<Element,T>) -> T {
//        get {
//            element[keyPath: path]
//        }
//        set {
//            element[keyPath: path] = newValue
//        }
//    }
}

public struct IndexedElementArray<Base> : Sequence, RandomAccessCollection where Base : Sequence & MutableCollection & RandomAccessCollection, Base.Index == Int {
    @Binding var binding: Base
    
    public typealias Element = Binding<IndexedElement<Base.Element>>
    public var startIndex: Int { binding.startIndex }
    public var endIndex: Int { binding.endIndex }
    public var count: Int { binding.count }
    public init(_ binding: Binding<Base>) {
        _binding = binding
    }
    /*
    public subscript(position: Int) -> Element {
        get {
            .init(id: position, element: binding[position])
        }
        nonmutating set {
            assert(position == newValue.id)
            binding[newValue.id] = newValue.element
        }
    }
     */
    public subscript(position: Int) -> Element {
        .init {
            .init(id: position, element: binding[position])
        } set: {
            assert(position == $0.id)
            binding[$0.id] = $0.element
        }
    }
}
extension Binding where Value : Sequence & MutableCollection & RandomAccessCollection, Value.Index == Int {
    /// convert a binding to an array to one where the elements have ids
    /// based on their index
    public var asIndexedArray : IndexedElementArray<Value> {
        .init(self)
    }
}
#endif
