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

extension CentralFileHeader {
    var generalPurposeFlags: GeneralPurposeFlag {
        get {
            .init(rawValue:CFSwapInt16LittleToHost(generalFlags))
        }
        set {
            generalFlags = CFSwapInt16HostToLittle(newValue.rawValue)
        }
    }
    var compressionMethod: CompressionMethod? {
        get {
            .init(rawValue: Int(CFSwapInt16LittleToHost(compression)))
        }
        set {
            if let newValue {
                compression = CFSwapInt16HostToLittle(UInt16(newValue.rawValue))
            }
        }
    }
}
extension LocalFileHeader {
    var generalPurposeFlags: GeneralPurposeFlag {
        get {
            .init(rawValue:CFSwapInt16LittleToHost(generalFlags))
        }
        set {
            generalFlags = CFSwapInt16HostToLittle(newValue.rawValue)
        }
    }
    var compressionMethod: CompressionMethod? {
        get {
            .init(rawValue: Int(CFSwapInt16LittleToHost(compression)))
        }
        set {
            if let newValue {
                compression = CFSwapInt16HostToLittle(UInt16(newValue.rawValue))
            }
        }
    }
}

public struct ZipReader {
    let data: Data
    public var originalData: Data { data }
    var allEntries: [String: Entry]
    struct Entry {
        /// full name
        var name: String
        /// range in original data of the entire header+extras+data+data descriptor
        var range: Range<Int>
        /// The range of payload
        var payloadRange: Range<Int>
        /// if we've modified it, this is the modified compressed data
        var modified: Data?
        /// the original local file header
        var localHeader: LocalFileHeader
        /// the original central file header
        var header: CentralFileHeader
        /// additional data store in local header and central record
        var extraField: Data?
        /// additional data stored in central record
        var fileComment: Data?
        /// do we have a data descriptor?
        var dataDescriptor: DataDescriptor?
        /// derived
        var fileNameData: Data {
            self.name.data(using: .utf8) ?? Data()
        }
    }
    /// The name of the file entires in order
    public var entries: [String] = []
    
    public init(data: Data) {
        self.data = data
        allEntries = [:]
        let sig : UInt32 = CFSwapInt32HostToLittle(Signatures.CentralFileHeaderSig.rawValue)
        let endSig : UInt32 = CFSwapInt32HostToLittle(Signatures.EndOfCentralDirSig.rawValue)
        data.withUnsafeBytes { (buffer:UnsafeRawBufferPointer) in
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
                // this is after the central header
                let afterHeader = t + MemoryLayout<CentralFileHeader>.stride
                // this is the name from the central header
                let nameBuffer = afterHeader.bindMemory(to: UInt8.self, capacity: Int(header.fileNameLength))
                let nameData = Data(buffer: UnsafeBufferPointer<UInt8>(start: nameBuffer, count: Int(header.fileNameLength)))
                let encoding = header.generalPurposeFlags.contains(.UTF8) ? String.Encoding.utf8 : String.Encoding.isoLatin1
                guard let fileName = String(data: nameData, encoding: encoding) else {
                    continue
                }
                if Int32(CFSwapInt32LittleToHost(header.compressedSize)) < 0 {
                    fatalError("\(fileName) has compressed size header \(header)")
                }
                
                let chunkStart = localOffset
                let filenameStart = localOffset + MemoryLayout<LocalFileHeader>.size
                let extraFieldStart = filenameStart + Int(CFSwapInt16LittleToHost(localHeader.fileNameLength))
                let payloadStart = extraFieldStart + Int(CFSwapInt16LittleToHost(localHeader.extraFieldLength))
                let payloadEnd = payloadStart + Int(CFSwapInt32LittleToHost(header.compressedSize))
                let chunkEnd = payloadEnd + (localHeader.generalPurposeFlags.contains(.HasDataDescriptor) ? MemoryLayout<DataDescriptor>.size : 0)
                /*
                let totalRange = localOffset ..< localOffset +
                Int(CFSwapInt32LittleToHost(header.compressedSize) + CFSwapInt32LittleToHost(localHeader.fileNameLength) + CFSwapInt32LittleToHost(localHeader.extraFieldLength) + (localHeader.generalPurposeFlags.contains(.HasDataDescriptor) ? MemoryLayout<DataDescriptor>.size : 0)))
                 */
                let dataDescriptor: DataDescriptor?
                if localHeader.generalPurposeFlags.contains(.HasDataDescriptor) {
                    dataDescriptor = (start + UnsafeRawPointer.Stride(payloadEnd)).bindMemory(to: DataDescriptor.self, capacity: 1).pointee
                } else {
                    dataDescriptor = nil
                }
                let extraField: Data?
                if localHeader.extraFieldLength != 0 {
                    extraField = data[extraFieldStart ..< payloadStart]
                } else {
                    extraField = nil
                }
                let entry = Entry(name: fileName,
                                  range: chunkStart ..< chunkEnd,
                                  payloadRange: payloadStart ..< payloadEnd,
                                  localHeader: localHeader,
                                  header: header,
                                  extraField: extraField,
                    dataDescriptor: dataDescriptor
                                  )
                allEntries[fileName] = entry
                entries.append(fileName)
                // move to next central file header
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
        guard let entry = allEntries[path] else {
            throw Errors.noSuchFile(path)
        }
        let range = entry.payloadRange
        if range.isEmpty {
            return Data()
        }
        #if nomore
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
            if header.generalPurposeFlags.contains(.HasDataDescriptor) {
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
        #else
        if entry.payloadRange.isEmpty {
            return Data()
        }
        let compressedData = data[entry.payloadRange]
        switch entry.localHeader.compressionMethod {
        case .None:
            return compressedData
        case .Deflated:
            return ZipReader.gZipDecompress(compressedData, size: Int(CFSwapInt32LittleToHost(entry.header.unCompressedSize)))
        case .none:
            throw Errors.unknownCompressionMethod(Int(CFSwapInt16LittleToHost(entry.localHeader.compression)))
        default:
            throw Errors.unsupportedCompressionMethod(entry.localHeader.compressionMethod!)
        }
        #endif
    }
    
    public func save() -> Data {
        let sortedEntries = allEntries.values.sorted { e1, e2 in
            e1.range.lowerBound < e2.range.lowerBound
        }
        
        var retval = Data()
        /// write out each
        var localHeaderRelativeOffsets:[String: Int] = [:]
        for entry in sortedEntries {
            // save the updated local header relative offset
            localHeaderRelativeOffsets[entry.name] = retval.count
            // first write out a header, extra header data
            var header = entry.localHeader
            // do we want to pull the data descriptor?
            retval.append(Data(bytes: &header, count: MemoryLayout<LocalFileHeader>.stride))
            retval.append(entry.fileNameData)
            if let extra = entry.extraField {
                assert(extra.count == Int(header.extraFieldLength))
                retval.append(extra)
            } else {
                assert(header.extraFieldLength == 0)
            }
            // then the compressed file
            if let modified = entry.modified {
                // this is already compressed
                retval.append(modified)
            } else {
                retval.append(data[entry.payloadRange])
            }
            // then the data descriptor (if any)
            if var dataDescriptor = entry.dataDescriptor {
                retval.append(Data(bytes: &dataDescriptor, count: MemoryLayout<DataDescriptor>.stride))
            }
        }
        let startOfCentralHeader = retval.count
        for entry in sortedEntries {
            // now write the central header for each item
            var header = entry.header
            header.localHeaderRelativeOffset = Int32(localHeaderRelativeOffsets[entry.name]!)
            retval.append(Data(bytes: &header, count: MemoryLayout<CentralFileHeader>.stride))
            // after the central header comes the file name, extraField (if any) and comment (if any)
            retval.append(entry.fileNameData)
            // the "extraFieldLength" in the central header isn't
            // the same as the extraFieldLength in the local header
//            if let extra = entry.extraField {
//                assert(extra.count == Int(entry.localHeader.extraFieldLength))
//                retval.append(extra)
//            } else {
                assert(header.extraFieldLength == 0)
//            }
            if let comment = entry.fileComment {
                assert(comment.count == Int(header.fileCommentLength))
                retval.append(comment)
            } else {
                assert(header.fileCommentLength == 0)
            }
        }
        // finally, write the EOCD
        var eocd = EndCentralFileHeader(
            endCentralFileHeaderSig: Signatures.EndOfCentralDirSig.rawValue,
            diskNumber: 0,
            diskNumberWithStartCentral: 0,
            numberEntriesThisDisk: UInt16(sortedEntries.count),
            numberEntries: UInt16(sortedEntries.count),
            centralFileHeaderSize: UInt32(retval.count - startOfCentralHeader),
            offsetCentralFileHeader: UInt32(startOfCentralHeader),
            zipFileCommentLength: 0)
        retval.append(Data(bytes: &eocd, count: MemoryLayout<EndCentralFileHeader>.stride))

        return retval
    }
    public mutating func replace(_ data: Data, for path: String) throws {
        guard var entry = allEntries[path] else {
            throw Errors.noSuchFile(path)
        }
        // compress the data
        let compressed = ZipReader.gZipCompress(data)
        if compressed.count > data.count {
            // got bigger, use uncompressed
            entry.modified = data
            entry.localHeader.compression = UInt16(CompressionMethod.None.rawValue)
            entry.localHeader.compressedSize = UInt32(data.count)
        } else {
            entry.modified = compressed
            entry.localHeader.compression = UInt16(CompressionMethod.Deflated.rawValue)
            entry.localHeader.compressedSize = UInt32(compressed.count)
        }
        entry.localHeader.crc32 = data.crc32
        entry.localHeader.unCompressedSize = UInt32(data.count)
        // remove the HasDataDescriptor (since we know how big it is, etc...)
        entry.localHeader.generalPurposeFlags.remove(.HasDataDescriptor)
        entry.header.generalPurposeFlags.remove(.HasDataDescriptor)
        entry.dataDescriptor = nil

        // update the central header
        entry.header.compression = entry.localHeader.compression
        entry.header.crc32 = entry.localHeader.crc32
        entry.header.compressedSize = entry.localHeader.compressedSize
        entry.header.unCompressedSize = entry.localHeader.unCompressedSize
        entry.header.generalFlags = entry.localHeader.generalFlags
        // and update ourselves
        allEntries[path] = entry
    }
    static func gZipDecompress(_ data: Data, size: Int) -> Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let result = data.withUnsafeBytes {
            let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                                                 data.count, nil, COMPRESSION_ZLIB)
            return Data(bytes: buffer, count:read)
        }
        buffer.deallocate()
        return result
    }

    static func gZipCompress(_ data: Data) -> Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count * 2)
        let result = data.subdata(in: 0 ..< data.count).withUnsafeBytes ({
            //            if #available(macOS 10.11,iOS 9.0, *) {
            let written = compression_encode_buffer(buffer, data.count * 2, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1), data.count, nil, COMPRESSION_ZLIB)
            return Data(bytes: buffer, count:written)
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
