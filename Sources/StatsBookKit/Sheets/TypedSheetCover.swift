//
//  File.swift
//  
//
//  Created by gandreas on 8/25/23.
//

import Foundation

public struct ValueFormat {
    public var booleanFormat: BooleanFormat?
}


/// A simple typed wrapper around an address.  We'd like to make this a property wrapper
/// but that confuses the keypath subscript
public struct CellDef<T> {
    public var address: Address
    public init(_ address: Address) {
        self.address = address
    }
    /// Allow explicit formats
    public var valueFormat: ValueFormat?
}

/// For any wrapper around a sheet (or an areas in a sheet), we provide a way to do a dynamic lookup
/// of various things
@dynamicMemberLookup
public protocol TypedSheetCover {
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
    public var cellOffset: Address.Offset { .zero }
    // support for strings by default
    public subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<String?>>) -> String? {
        get {
            return self[Self.cellDefinitions[keyPath: path].address]
        }
        nonmutating set {
            self[Self.cellDefinitions[keyPath: path].address] = newValue
        }
    }
    // support for numbers by default
    public subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<Double?>>) -> Double? {
        get {
            return self[Self.cellDefinitions[keyPath: path].address]
        }
        nonmutating set {
            self[Self.cellDefinitions[keyPath: path].address] = newValue
        }
    }
    // support for ints by default (type converting doubles)
    public subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<Int?>>) -> Int? {
        get {
            if let d: Double = self[Self.cellDefinitions[keyPath: path].address] {
                return Int(d)
            }
            return nil
        }
        nonmutating set {
            self[Self.cellDefinitions[keyPath: path].address] = newValue.map{Double($0)}
        }
    }
    
    public subscript(dynamicMember path: KeyPath<CellDefinitions, CellDef<Bool?>>) -> Bool? {
        get {
            let def = Self.cellDefinitions[keyPath: path]
            return self[def.address, def.valueFormat?.booleanFormat]
        }
        nonmutating set {
            let def = Self.cellDefinitions[keyPath: path]
            self[def.address, def.valueFormat?.booleanFormat] = newValue
        }
    }
    
    public subscript<T>(dynamicMember path: KeyPath<CellDefinitions, CellDef<T>>) -> T {
        get {
            fatalError("Unsupported type in dynamic sheet page: \(String(describing: T.self))")
        }
        nonmutating set {
            fatalError("Unsupported type in dynamic sheet page")
        }
    }
    
    
    subscript(address: Address) -> String? {
        get {
            let cell = sheet[address.offset(by: cellOffset)]
            return try? cell?.eval()?.asString
        }
        nonmutating set {
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
        nonmutating set {
            if let newValue {
                sheet.cachedValues[address.offset(by: cellOffset)] = .number(newValue)
            } else {
                sheet.cachedValues[address] = .undefined
            }
        }
    }
    
    subscript(address: Address, format: BooleanFormat?) -> Bool? {
        get {
            let cell = sheet[address.offset(by: cellOffset)]
            switch try? cell?.eval()?.asString {
            case "X","yes","y","YES","Y": return true
            case "","no","n","NO","N": return false
            case .none: return false
            default:
                return nil
            }
        }
        nonmutating set {
            if let format {
                switch newValue {
                case .none:
                    sheet.cachedValues[address.offset(by: cellOffset)] = format.undefinedValue
                case .some(true):
                    sheet.cachedValues[address.offset(by: cellOffset)] = format.trueValue
                case .some(false):
                    sheet.cachedValues[address.offset(by: cellOffset)] = format.falseValue
                }
            } else if let newValue {
                // we really need meta data to tell us what kind of value this is, but...
                switch newValue {
                case true: sheet.cachedValues[address.offset(by: cellOffset)] = .string("X")
                case false: sheet.cachedValues[address.offset(by: cellOffset)] = .undefined
                }
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
    
    /// Get a transformer that allows access to comments
    public var commentFor: CommentFetcher<Self> {
        .init(sheet: sheet, cellOffset: cellOffset)
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



// A way to get the comment for a given field in a TypedSheetCover
// This assume that the dynamic member is valid (or errors)
@dynamicMemberLookup
public struct CommentFetcher<T: TypedSheetCover> {
    var sheet: Sheet
    var cellOffset: Address.Offset
    public subscript<T2>(dynamicMember path: KeyPath<T.CellDefinitions, CellDef<T2>>) -> Comment? {
        guard let xml = sheet.comment(for: T.cellDefinitions[keyPath: path].address + cellOffset) else {
            return nil
        }
        return Comment(xml: xml, sheet: sheet)
    }
}

// MARK: SwiftUI addons
#if canImport(SwiftUI)
import SwiftUI
extension Sheet : ObservableObject {
    
}

// A way to get the comment for a given field in a TypedSheetCover
// This assume that the dynamic member is valid (or errors)
@dynamicMemberLookup
public struct BindingFetcher<T: TypedSheetCover> {
    @ObservedObject var sheet: Sheet
    var cellOffset: Address.Offset
    public subscript(dynamicMember path: KeyPath<T.CellDefinitions, CellDef<String?>>) -> Binding<String> {
        let address = T.cellDefinitions[keyPath: path].address.offset(by: cellOffset)
        
        return .init {
            let cell = sheet[address]
            return (try? cell?.eval()?.asString) ?? ""
        } set: { newValue in
            sheet.objectWillChange.send()
            if newValue.isEmpty == false {
                sheet.cachedValues[address] = .string(newValue)
            } else {
                sheet.cachedValues[address] = .undefined
            }
        }

    }
    public subscript(dynamicMember path: KeyPath<T.CellDefinitions, CellDef<Int?>>) -> Binding<Int> {
        let address = T.cellDefinitions[keyPath: path].address.offset(by: cellOffset)
        
        return .init {
            let cell = sheet[address]
            return (try? cell?.eval()?.asNumber).map{Int($0)} ?? 0
        } set: { newValue in
            sheet.objectWillChange.send()
            sheet.cachedValues[address] = .number(Double(newValue))
        }

    }
}

extension TypedSheetCover {
    /// Get a transformer that allows access to fields as bindings for SwiftUI (where
    /// the sheet is the observed object
    public var bindingFor: BindingFetcher<Self> {
        .init(sheet: sheet, cellOffset: cellOffset)
    }
}
#endif
