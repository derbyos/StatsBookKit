import gandZipHeader
import Foundation
import Compression

enum Signatures : UInt32 {
    case LocalFileHeaderSig = 0x04034b50
    case ArchiveExtraDataSig = 0x08064b50
    case CentralFileHeaderSig = 0x02014b50
    case DigitalSignatureHeaderSig = 0x05054b50
    case EndOfCentralDirSig64 = 0x06064b50
    case EndOfCentralDirLocatorSig = 0x07074b50
    case EndOfCentralDirSig = 0x06054b50
    case SplitArchiveSig = 0x08074b50
}

public enum CompressionMethod: Int {
    case None = 0
    case Shrunk = 1
    case Reduced1 = 2
    case Reduced2 = 3
    case Reduced3 = 4
    case Reduce4 = 5
    case Imploded = 6
    case Tokenized = 7
    case Deflated = 8
    case EnhancledDeflated64 = 9
    case OldIBMTerse = 10
    case Bzip2 = 12
    case LZMA = 14
    case IBMTerse = 18
    case LZ77 = 19
    case WavPack = 97
    case PPMdI1 = 98
}
struct GeneralPurposeFlag : OptionSet {
    var rawValue: UInt16
    static let Encrypted = GeneralPurposeFlag(rawValue:1 << 0)
    static let Imploding8k = GeneralPurposeFlag(rawValue:1 << 1)
    static let Imploding3Trees = GeneralPurposeFlag(rawValue:1 << 2)
    static let DeflateOptionMask = GeneralPurposeFlag(rawValue:(1 << 1) | (1 << 2))
    static let DeflateOptionNormal = GeneralPurposeFlag(rawValue:(0 << 1) | (0 << 2))
    static let DeflateOptionMaximum = GeneralPurposeFlag(rawValue:(1 << 1) | (0 << 2))
    static let DeflateOptionFast = GeneralPurposeFlag(rawValue:(0 << 1) | (1 << 2))
    static let DeflateOptionSuperFast = GeneralPurposeFlag(rawValue:(1 << 1) | (1 << 2))
    static let LZMAEOS = GeneralPurposeFlag(rawValue:1 << 1)
    static let HasDataDescriptor = GeneralPurposeFlag(rawValue:1 << 3)
    static let EnhancedDeflate = GeneralPurposeFlag(rawValue:1 << 4)
    static let PatchedData = GeneralPurposeFlag(rawValue:1 << 5)
    static let StrongEncrption = GeneralPurposeFlag(rawValue:1 << 6)
    static let UTF8 = GeneralPurposeFlag(rawValue:1 << 11)
}

public struct ZipReader {
    let data: Data
    var entries: [String: Entry]
    struct Entry {
        /// full name
        var name: String
        /// range in original data
        var range: Range<Int>
        /// if we've modified it, this is the modified compressed data
        var modified: Data?
        /// the original local file header
        var localHeader: LocalFileHeader
        /// the original central file header
        var header: CentralFileHeader
    }
    /// The name of the file entires in order
    public var entryNames: [String] = []
    
    public init(data: Data) {
        self.data = data
        entries = [:]
        let sig : UInt32 = CFSwapInt32HostToLittle(Signatures.CentralFileHeaderSig.rawValue)
        let endSig : UInt32 = CFSwapInt32HostToLittle(Signatures.EndOfCentralDirSig.rawValue)
        data.withUnsafeBytes { buffer in
            let start = buffer.baseAddress!
            let end = start + data.count
            var t = start
            // scan forward from start of file is very slow and bad
            // first skip forward to find end central file header
            var e = end - MemoryLayout<EndCentralFileHeader>.stride
            while e > start {
                let p = e.bindMemory(to: UInt32.self, capacity: 1)
                if p.pointee != endSig {
                    e -= 1
                    continue
                }
                let eheader = e.bindMemory(to: EndCentralFileHeader.self, capacity: 1).pointee
                t = start + UnsafeRawPointer.Stride(CFSwapInt32LittleToHost(eheader.offsetCentralFileHeader))
                break
            }
            while t < end - MemoryLayout<UInt32>.stride {
                // find central file header
                let p = t.bindMemory(to: UInt32.self, capacity: 1)
                if p.pointee != sig {
                    t += 1
                    continue
                }
                let header = t.bindMemory(to: CentralFileHeader.self, capacity: 1).pointee
                // make sure this make sense
                var localOffset = Int(header.localHeaderRelativeOffset)
                if localOffset < 0 {
                    localOffset = 1 << 32 + localOffset
                }
                if localOffset < 0 || start + UnsafeRawPointer.Stride(localOffset) > end {
                    continue
                }
                let localHeader = (start + UnsafeRawPointer.Stride(localOffset)).bindMemory(to: LocalFileHeader.self, capacity: 1).pointee
                if CFSwapInt32LittleToHost(localHeader.localFileHeaderSig) != Signatures.LocalFileHeaderSig.rawValue {
                    continue
                }
                let afterHeader = t + MemoryLayout<CentralFileHeader>.stride
                let nameBuffer = afterHeader.bindMemory(to: UInt8.self, capacity: Int(header.fileNameLength))
                let nameData = Data(buffer: UnsafeBufferPointer<UInt8>(start: nameBuffer, count: Int(header.fileNameLength)))
                let encoding =  GeneralPurposeFlag(rawValue:CFSwapInt16LittleToHost(header.generalFlags)).contains(.UTF8) ? String.Encoding.utf8 : String.Encoding.isoLatin1
                guard let fileName = String(data: nameData, encoding: encoding) else {
                    continue
                }
                if Int32(CFSwapInt32LittleToHost(header.compressedSize)) < 0 {
                    fatalError("\(fileName) has compressed size header \(header)")
                }
                let entry = Entry(name: fileName,
                                  range: localOffset ..< localOffset + Int(CFSwapInt32LittleToHost(header.compressedSize)),
                                  localHeader: localHeader,
                                  header: header
                                  )
                entries[fileName] = entry
                entryNames.append(fileName)
                t += MemoryLayout<CentralFileHeader>.stride +
                    Int(CFSwapInt16LittleToHost(header.fileNameLength)) +
                    Int(CFSwapInt16LittleToHost(header.extraFieldLength)) +
                    Int(CFSwapInt16LittleToHost(header.fileCommentLength))
            }
        }
    }
    
    public enum Errors: Error {
        case noSuchFile(String)
        case unsupportedCompressionMethod(CompressionMethod)
        case unknownCompressionMethod(Int)
    }
    public func data(for path: String) throws -> Data {
        guard let entry = entries[path] else {
            throw Errors.noSuchFile(path)
        }
        let range = entry.range
        if range.isEmpty {
            return Data()
        }
        var retval: Data = Data()
        try data.withUnsafeBytes { buffer in
            if range.count == 0 {
                retval = Data()
                return
            }
            let t = buffer.baseAddress! + Int(range.lowerBound)
            let header = t.bindMemory(to: LocalFileHeader.self, capacity: 1).pointee
            var dataDescriptor: DataDescriptor = .init(crc32: header.crc32, compressedSize: header.compressedSize, unCompressedSize: header.unCompressedSize)
            let dataStart = t + MemoryLayout<LocalFileHeader>.stride + Int(CFSwapInt16LittleToHost(header.fileNameLength)) + Int(CFSwapInt16LittleToHost(header.extraFieldLength))
            if GeneralPurposeFlag(rawValue: header.generalFlags).contains(.HasDataDescriptor) {
                // data descriptor is after the data
                let t2 = dataStart + range.count + 4 // 4 being the size of the end signature
                dataDescriptor = t2.bindMemory(to: DataDescriptor.self, capacity: 1).pointee
            }
//            print("Uncompressing \(header)")
            // NB: compressedSize is usually 0
            let dataBuffer = dataStart.bindMemory(to: UInt8.self, capacity: range.count)
            let compressedData = Data(buffer: UnsafeBufferPointer<UInt8>(start: dataBuffer, count: range.count))
            let compressionMethod = CompressionMethod(rawValue: Int(CFSwapInt16LittleToHost(header.compression)))
            switch compressionMethod {
            case .None:
                retval = compressedData
            case .Deflated:
                retval = ZipReader.gZipDecompress(compressedData, size: Int(CFSwapInt32LittleToHost(dataDescriptor.unCompressedSize)))
            case .none:
                throw Errors.unknownCompressionMethod(Int(CFSwapInt16LittleToHost(header.compression)))
            default:
                throw Errors.unsupportedCompressionMethod(compressionMethod!)
            }
        }
        return retval
    }
    
    
    public func replace(_ data: Data, for path: String) throws {
        guard let range = entries[path] else {
            throw Errors.noSuchFile(path)
        }
    }
    static func gZipDecompress(_ data: Data, size: Int) -> Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let result = data.subdata(in: 0 ..< data.count).withUnsafeBytes ({
//            if #available(macOS 10.11,iOS 9.0, *) {
                let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                                                     data.count, nil, COMPRESSION_ZLIB)
                return Data(bytes: buffer, count:read)
//            } else {
//                // Fallback on earlier versions
//                fatalError()
//            }
        }) as Data
        buffer.deallocate()
        return result
    }

}

extension Data {
    static var table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            (0..<8).reduce(UInt32(i), { c, _ in
                (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
            })
        }
    }()

    static func checksum(bytes: [UInt8]) -> UInt32 {
        return ~(bytes.reduce(~UInt32(0), { crc, byte in
            (crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }

    public var crc32 : UInt32 {
        return withUnsafeBytes {
            Data.checksum(bytes: [UInt8](UnsafeBufferPointer(start: $0, count: self.count)))
        }
    }
}
/*
public struct ZipWriter {
    var data: Data
//    public var entries: [String: Range<Int>]
    public init() {
        data = Data()
        entries = [:]
    }
    public var entries: [String: (LocalFileHeader,Range<Int>)]
    public mutating func add(data contents: Data, path: String) {
        let compressed = ZipWriter.gZipCompress(contents)
        let fileName = path.data(using: .utf8)!
        var localFileHeader = LocalFileHeader(localFileHeaderSig: Signatures.LocalFileHeaderSig.rawValue, extractVersion: 0, generalFlags: 0, compression: UInt16(compressed.0.rawValue), lastModTime: 0, lastModDate: 0, crc32: data.crc32, compressedSize: UInt32(compressed.1.count), unCompressedSize: UInt32(contents.count), fileNameLength: UInt16(fileName.count), extraFieldLength: 0)
        let start = data.count
        data.append(Data(bytes: &localFileHeader, count: MemoryLayout<LocalFileHeader>.stride))
        data.append(fileName)
        data.append(compressed.1)
        entries[path] = (localFileHeader, start ..< data.count)
    }
    public mutating func finish() -> Data {
        let startCentralFileHeader = data.count
        var cfh = CentralFileHeader(centralFileHeaderSig: Signatures.CentralFileHeaderSig.rawValue, creatorVersion: 0, extractVersion: 0, generalFlags: 0, compression: <#T##UInt16#>, lastModTime: <#T##UInt16#>, lastModDate: <#T##UInt16#>, crc32: <#T##UInt32#>, compressedSize: <#T##UInt32#>, unCompressedSize: <#T##UInt32#>, fileNameLength: <#T##UInt16#>, extraFieldLength: <#T##UInt16#>, fileCommentLength: <#T##UInt16#>, diskNumberStart: <#T##UInt16#>, interalFileAttrs: <#T##UInt16#>, externalFileAttrs: <#T##UInt32#>, localHeaderRelativeOffset: <#T##Int32#>)
        var ecfh = EndCentralFileHeader(endCentralFileHeaderSig: Signatures.EndOfCentralDirSig.rawValue, diskNumber: 0, diskNumberWithStartCentral: 0, numberEntriesThisDisk: UInt16(entries.count), numberEntries: UInt16(entries.count), centralFileHeaderSize: <#T##UInt32#>, offsetCentralFileHeader: UInt32(startCentralFileHeader), zipFileCommentLength: 0)
        data.append(Data(bytes: &cfh, count: MemoryLayout<CentralFileHeader>.stride))
        data.append(Data(bytes: &ecfh, count: MemoryLayout<EndCentralFileHeader>.stride))
        return data
    }
    static func gZipCompress(_ data: Data) -> (CompressionMethod,Data) {
        return data.withUnsafeBytes { unsafeData in
            let bytesPointer = UnsafeMutableRawPointer.allocate(
                byteCount: data.count,
                    alignment: MemoryLayout<Int8>.alignment)
            defer {
                bytesPointer.deallocate()
            }
            let compressedSize = compression_encode_buffer(bytesPointer.bindMemory(to: UInt8.self, capacity: data.count), data.count, unsafeData.baseAddress!.bindMemory(to: UInt8.self, capacity: data.count), data.count, nil, COMPRESSION_ZLIB)
            if compressedSize != 0 {
                let compressedData = Data(bytes: bytesPointer, count: data.count)
                return (.Deflated, compressedData)
            } else {
                return (.None, data)
            }
        }
    }
}
*/
