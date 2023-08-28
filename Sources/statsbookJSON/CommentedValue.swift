//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

/// Add this coding user info key to the encoder and comments will not be written to the JSON
public var RemoveCommentsKey = CodingUserInfoKey(rawValue: "statbookJSON.noComments")!

/// Commented values are always optional, but there is built in way to enforce that

public protocol IsOptional {
    var optionalIsNull: Bool { get }
    static var decodedNull : Self { get }
}
extension Optional : IsOptional {
    public static var decodedNull : Self { .none }
    public var optionalIsNull: Bool {
        switch self {
        case .none: return true
        default: return false
        }
    }
}
/// This is the property wrapper around all values that allow them to have comments associated
/// with them
@propertyWrapper
public struct Commented<T:Codable & IsOptional> : Codable {
    public var wrappedValue: T {
        get {
            value
        }
        set {
            value = newValue
        }
    }
    var value: T
    public init(value: T) {
        self.value = value
    }
    public struct Comment : Codable {
        public init(text: String, author: String? = nil) {
            self.text = text
            self.author = author
        }
        
        public var text: String
        public var author: String?
    }
    public var comment: Comment?
    
    // we need this to be able to access the comment field
    // from outside the struct (since _foo is private)
    public var projectedValue: Self {
        get {
            self
        }
        set {
            self = newValue
        }
    }
    // encoding to support wrapping a comment or not
    public init(from decoder: Decoder) throws {
        // a comment
        if let container: KeyedDecodingContainer<Commented<T>.CodingKeys> = try? decoder.container(keyedBy: Commented<T>.CodingKeys.self) {
            self.value = try container.decode(T.self, forKey: Commented<T>.CodingKeys.value)
            self.comment = try container.decodeIfPresent(Comment.self, forKey: Commented<T>.CodingKeys.comment)
        } else {
            let singleValue = try decoder.singleValueContainer()
            // no comment
            self.comment = nil
            if singleValue.decodeNil() {
                self.value = T.decodedNull
            } else {
                self.value = try singleValue.decode(T.self)
            }
        }
    }
    public enum CodingKeys: CodingKey {
        case value
        case comment
    }
    
    public func encode(to encoder: Encoder) throws {
        if encoder.userInfo[RemoveCommentsKey] == nil, let comment {
            // write the comment in a container
            var container = encoder.container(keyedBy: Commented<T>.CodingKeys.self)
            try container.encode(self.value, forKey: .value)
            try container.encode(comment, forKey: .comment)
//        } else if value.optionalIsNull {
//            var container = encoder.singleValueContainer()
//            // don't write anything
        } else {
            // just write the value
            var container = encoder.singleValueContainer()
            try container.encode(self.value)
        }
    }
}


/// Magic to skip commented values where both value and comment are nil
extension KeyedEncodingContainer {
    mutating func encode<V>(_ value: Commented<V>, forKey key: Key) throws {
        if value.value.optionalIsNull && value.comment == nil {
            // do nothing
        } else {
//
//            try encode(value as! Encodable, forKey: key)
            try encodeIfPresent(value, forKey: key)
        }
    }
}

/// Magic to decode skipped commented values where both value and comment are nil
extension KeyedDecodingContainer {
    func decode<V>(_ type: Commented<V>.Type, forKey key: Key) throws -> Commented<V> {
        if let found = try? decodeIfPresent(type, forKey: key) {
            return found
        } else {
            return .init(value: .decodedNull)
        }
    }
}
extension Encoder where Self : KeyedEncodingContainerProtocol {
    mutating func encode<V>(_ value: Commented<V>, forKey key: Key) throws {
        if value.value.optionalIsNull {
            // do nothing
        } else {
            try encodeIfPresent(value, forKey: key)
        }
    }
}
