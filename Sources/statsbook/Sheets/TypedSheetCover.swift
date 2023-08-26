//
//  File.swift
//  
//
//  Created by gandreas on 8/25/23.
//

import Foundation


/// A simple typed wrapper around an address.  We'd like to make this a property wrapper
/// but that confuses the keypath subscript
struct CellDef<T> {
    var address: Address
    init(_ address: Address) {
        self.address = address
    }
}

/// For any wrapper around a sheet (or an areas in a sheet), we provide a way to do a dynamic lookup
/// of various things
@dynamicMemberLookup
protocol TypedSheetCover {
    var sheet: Sheet { get }
    /// Where all the cell definitions are stored
    associatedtype CellDefinitions
    /// An instance of the cell definitions since we can't have keypaths that refer to
    /// static members (or we'd declare them in the struct itself)
    static var cellDefinitions: CellDefinitions { get }
    
    subscript<T>(dynamicMember path: KeyPath<CellDefinitions, CellDef<T>>) -> T { get set }

    /// If this is a subsection that is actually offset within the page (allowing for
    /// home vs away, for example)
    var cellOffset: Address.Offset { get }
}

// default implementations of the various parts of the field
extension TypedSheetCover {
    var cellOffset: Address.Offset { .zero }
    // support for strings by default
    subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<String?>>) -> String? {
        get {
            return self[Self.cellDefinitions[keyPath: path].address]
        }
        set {
            self[Self.cellDefinitions[keyPath: path].address] = newValue
        }
    }
    // support for numbers by default
    subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<Double?>>) -> Double? {
        get {
            return self[Self.cellDefinitions[keyPath: path].address]
        }
        set {
            self[Self.cellDefinitions[keyPath: path].address] = newValue
        }
    }
    // support for ints by default (type converting doubles)
    subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<Int?>>) -> Int? {
        get {
            if let d: Double = self[Self.cellDefinitions[keyPath: path].address] {
                return Int(d)
            }
            return nil
        }
        set {
            self[Self.cellDefinitions[keyPath: path].address] = newValue.map{Double($0)}
        }
    }

    subscript<T>(dynamicMember path: KeyPath<CellDefinitions, CellDef<T>>) -> T {
        get {
            fatalError("Unsupported type in dynamic sheet page")
        }
        set {
            fatalError("Unsupported type in dynamic sheet page")
        }
    }

    
    subscript(address: Address) -> String? {
        get {
            let cell = sheet[address.offset(by: cellOffset)]
            return try? cell?.eval()?.asString
        }
        set {
            if let newValue {
                sheet.cachedValues[address.offset(by: cellOffset)] = .string(newValue)
            } else {
                sheet.cachedValues[address.offset(by: cellOffset)] = .undefined
            }
        }
    }
    
    subscript(address: Address) -> Double? {
        get {
            let cell = sheet[address.offset(by: cellOffset)]
            return try? cell?.eval()?.asNumber
        }
        set {
            if let newValue {
                sheet.cachedValues[address.offset(by: cellOffset)] = .number(newValue)
            } else {
                sheet.cachedValues[address] = .undefined
            }
        }
    }
    
    var addressFor: AddressFetcher<Self> {
        .init()
    }
    static var addressFor: AddressFetcher<Self> {
        .init()
    }
}

// A way to get the address for a given field in a TypedSheetCover
// This assume that the dynamic member is valid (or errors)
// Note that this is not the absolute address, but relative to the dynamic sheet page
@dynamicMemberLookup
struct AddressFetcher<T: TypedSheetCover> {
    subscript<T2>(dynamicMember path: KeyPath<T.CellDefinitions, CellDef<T2>>) -> Address {
        return T.cellDefinitions[keyPath: path].address
    }
}
