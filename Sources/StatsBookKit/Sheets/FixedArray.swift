//
//  File.swift
//  
//
//  Created by gandreas on 9/1/23.
//

import Foundation


/// An element needs to be able to be created
public protocol FixedArrayItem : TypedSheetCover {
    /// Is the element empty?
    var isEmpty : Bool { get }
    /// How large is each element.
    static var cellSize: Address.Offset { get }
    /// Apply a axis
    static var axis: Address.Axis { get }
    /// The "origin" (since items are based on the sheet address)
    static var topLeft: Address { get }
    /// So we can create it
    init(sheet: Sheet, offset: Address.Offset)
}

extension FixedArrayItem {
    /// The bottom right - the size of the cells, but offset by one since this would be the "next" item otherwise
    public static var bottomRight: Address {
        topLeft + cellSize + .init(dr:-1,dc:-1)
    }
}
/// Similar to a FlexArray, a FixedArray is a way to present the rows (or columns) in a spreadsheet
/// as an array.
public struct FixedArray<Element: FixedArrayItem> : Sequence, RandomAccessCollection, MutableCollection {
    /// The sheet they live in
    var sheet: Sheet
    /// An offset
    var cellOffset: Address.Offset
    
    /// The maximum number of items
    var maxItems: Int
    init(sheet: Sheet, offset: Address.Offset, maxItems: Int) {
        self.sheet = sheet
        cellOffset = offset
        self.maxItems = maxItems
    }
    // protocols
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    
    public var count: Int {
        // dropping the empty items
        var retval = maxItems - 1
        while retval > 0 {
            if self[retval].isEmpty {
                retval -= 1
            }
        }
        return retval
    }
    
    public subscript(position: Int) -> Element {
        get {
            guard position < maxItems else {
                fatalError()
            }
            return Element(sheet: sheet, offset: cellOffset + .init(dr: Element.axis == .row ? Element.cellSize.dr * position : 0, dc: Element.axis == .column ? Element.cellSize.dc * position : 0))
        }
        set {
            guard position < maxItems else {
                fatalError()
            }
            // so how do we set the elements?  By directly changing the
            // sheets values
            for row in 0..<Element.cellSize.dr {
                for col in 0..<Element.cellSize.dc {
                    let subValue = newValue.sheet[Element.topLeft + newValue.cellOffset + .init(dr: row, dc: col)]
                    let oldValue = sheet[Element.topLeft + self.cellOffset + .init(dr: row, dc: col)]
                    if let oldValue {
                        // directly write the address
                        sheet.cachedComments[oldValue.address] = subValue?.comment
                        oldValue.value = subValue?.value
                    } else {
                        // do we make a new cell?
                        fatalError("Setting to a cell not present in the sheet")
                    }
                }
            }
        }
    }
}
