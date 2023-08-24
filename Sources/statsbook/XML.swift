//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// A delegate of the XMLParser that builds our XML tree document
fileprivate class XMLBuilder : NSObject, XMLParserDelegate {
    var root: XML = .empty // start with nothing
    
    var nest: [XML] = []
    /// add this to the "node"
    func append(_ xml: XML) {
        guard var last = nest.popLast() else {
            return
        }
        try? last.append(child: xml)
        nest.append(last)
    }
    func parserDidStartDocument(_ parser: XMLParser) {
        nest.append(.document([]))
    }
    func parserDidEndDocument(_ parser: XMLParser) {
        guard let last = nest.popLast(), case .document = last else {
            parser.abortParsing()
//            parser.parserError = Errors.invalidXML
            return
        }
        root = last
    }
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        append(.cdata(CDATABlock))
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        append(.characters(string))
    }
    func parser(_ parser: XMLParser, foundComment comment: String) {
        append(.comment(comment))
    }
    func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) {
        append(.endMappingPrefix(prefix))
    }
    func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String) {
        append(.whitespace(whitespaceString))
    }
    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
        append(.beginMappingPrefix(prefix, toURI: namespaceURI))
    }
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
        append(.elementDeclaration(elementName, model: model))
    }
    func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
        append(.processingInstruction(target, data: data))
    }
    func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
        print("foundInternalEntityDeclarationWithName")
    }
    func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) {
        print("foundNotationDeclarationWithName")
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        nest.append(.element(elementName, namespace: namespaceURI, qName: qName, attributes: attributeDict, children: []))
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let last = nest.popLast(), case .element = last else {
            parser.abortParsing()
//            parser.parserError = Errors.invalidXML
            return
        }
        append(last)
    }

    func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) {
    }
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
    }
    func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) {
    }
}
/// A very simple XML model
enum XML : Equatable {
    case empty // special case not existing in the file
    case document([XML])
    case cdata(Data)
    case characters(String)
    case comment(String)
    case whitespace(String)
    case beginMappingPrefix(String, toURI: String)
    case endMappingPrefix(String)
    case elementDeclaration(String, model: String)
    case processingInstruction(String, data: String?)
    case element(String, namespace: String?, qName: String?, attributes: [String:String], children: [XML])
    
    /// Convert this element (and all children recursively) into just their textual content
    var asString: String {
        switch self {
        case .document(let xml):
            return xml.map{$0.asString}.joined()
        case .characters(let str):
            return str
        case .whitespace(let str):
            return str
        case .element(_, namespace: _, qName: _, attributes: _, children: let xml):
            return xml.map{$0.asString}.joined()
        default:
            return ""
        }
    }
    /// Convert this element (and all children recursively) into a string converted to an int
    var asInt: Int? {
        switch self {
        case .element(_, namespace: _, qName: _, attributes: _, children: let xml):
            let str = xml.map{$0.asString}.joined()
            return Int(str)
        default:
            return nil
        }
    }
    /// Append a child to the current element, if possible
    mutating func append(child: XML) throws {
        switch self {
        case .document(let children):
            self = .document(children + [child])
        case .element(let name, namespace: let namespace, qName: let qname, attributes: let attributes, children: let children):
            self = .element(name, namespace: namespace, qName: qname, attributes: attributes, children: children + [child])
        default:
            throw Errors.addingChildToNonParentXML
        }
    }
    
    /// All of the children of the element
    var children: [XML]? {
        switch self {
        case .document(let children):
            return children
        case .element(_, namespace: _, qName: _, attributes: _, children: let children):
            return children
        default:
            return nil
        }
    }
    
    subscript(attribute: String) -> String? {
        switch self {
        case .element(_, namespace: _, qName: _, attributes: let attributes, children: _):
            return attributes[attribute]
        default:
            return nil
        }
    }
    /// Parse the XML
    init(_ data: Data) throws {
        let parser = XMLParser(data: data)
        let delegate = XMLBuilder()
        parser.delegate = delegate
        if !parser.parse(), let error = parser.parserError {
            throw error
        }
        self = delegate.root
    }
}

protocol XMLFile {
    var xml: XML { get set }
}

extension XML {
    /// Find the first child element with this name
    func firstChild(named: String) -> XML? {
        children?.first(where: {
            if case .element(named, namespace: _, qName: _, attributes: _, children: _) = $0 {
                return true
            }
            return false
        })
    }

    /// Find the first child element with a given test satisfied
    func firstChild(where test: (XML)->Bool) -> XML? {
        children?.first(where: test)
    }

    /// Find all children with this name
    /// - Parameter named: The element named
    /// - Returns: A list of all XML nodes
    func allChildren(named: String) -> [XML] {
        children?.filter({
            if case .element(named, namespace: _, qName: _, attributes: _, children: _) = $0 {
                return true
            }
            return false
        }) ?? []
    }
}

// A very simple XML creation which certainly has special case errors
extension XML : CustomStringConvertible {
    var description: String {
        switch self {
        case .document(let xml):
            return #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n"# + xml.map{$0.description}.joined()
        case .characters(let str):
            return str
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "<", with: "&lt;")
        case .whitespace(let str):
            return str
        case .element(let name, namespace: let ns, qName: let qname, attributes: let attributes, children: let children):
            var retval = "<\(name)"
            if attributes.isEmpty == false {
                for attr in attributes {
                    retval += " \(attr.key)=\"\(attr.value)\""
                }
            }
            if children.isEmpty {
                retval += "/>"
            } else {
                retval += ">" + children.map{$0.description}.joined() + "</\(name)>"
            }
            return retval
        case .cdata, .comment:
            return ""
        default:
            fatalError("Unsupported XML serialization \(self)")
        }
    }
}

extension XML {
    /// Walk through the XML tree, and pass in each node to the
    /// walker function.  That function should return nil (to keep walking)
    /// or a new XML value to replace this item.  Return ".empty" to
    /// delete the item
    /// - Parameter walker: The walker function
    /// - Returns: The resulting value
    ///
    func walkAndUpdate(walker: (XML)->XML?) -> XML {
        func process(children: [XML]) -> [XML] {
            var retval = [XML]()
            for child in children {
                let walked = walker(child)
                switch walked {
                case .none:
                    // keep going into children
                    retval.append(child.walkAndUpdate(walker: walker))
                case .empty:
                    // delete this
                    break
                case .some(let value):
                    // replace this
                    retval.append(value)
                }
            }
            retval.removeAll(where: {$0 == .empty})
            return retval
        }
        switch self {
        case .empty:
            return .empty
        case .document(let children):
            return .document(process(children: children))
        case .element(let name, namespace: let namespace, qName: let qname, attributes: let attributes, children: let children):
            switch walker(self) {
            case .none:
                return .element(name, namespace: namespace, qName: qname, attributes: attributes, children: process(children: children))
            case .some(let v):
                return v
            }
        default:
            switch walker(self) {
            case .none:
                return self // unchanged (and no children
            case .some(let v):
                return v
            }
        }
    }
}
