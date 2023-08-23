//
//  Header.h
//  
//
//  Created by gandreas on 6/25/21.
//

#ifndef Header_h
#define Header_h
#import <stdlib.h>

// these are all little endian
#pragma pack(push, 2)
typedef struct {
    uint32_t localFileHeaderSig;
    uint16_t extractVersion;
    uint16_t generalFlags;
    uint16_t compression;
    uint16_t lastModTime;
    uint16_t lastModDate;
    uint32_t crc32;
    uint32_t compressedSize;
    uint32_t unCompressedSize;
    uint16_t fileNameLength;
    uint16_t extraFieldLength;
} LocalFileHeader;

typedef struct {
    uint32_t crc32;
    uint32_t compressedSize;
    uint32_t unCompressedSize;
} DataDescriptor;

typedef struct {
    uint32_t centralFileHeaderSig; // 00
    uint16_t creatorVersion; // 04
    uint16_t extractVersion; // 06
    uint16_t generalFlags; // 08
    uint16_t compression; // 0A
    uint16_t lastModTime; // 0C
    uint16_t lastModDate; // 0E
    uint32_t crc32;  // 10
    uint32_t compressedSize; // 14
    uint32_t unCompressedSize; // 18
    uint16_t fileNameLength; // 1C
    uint16_t extraFieldLength; // 1E
    uint16_t fileCommentLength; // 20
    uint16_t diskNumberStart; // 22
    uint16_t interalFileAttrs; // 24
    uint32_t externalFileAttrs; // 26
    int32_t localHeaderRelativeOffset; // 2A
} CentralFileHeader;
typedef struct {
    uint32_t endCentralFileHeaderSig; // 00
    uint16_t diskNumber; // 04
    uint16_t diskNumberWithStartCentral; // 06
    uint16_t numberEntriesThisDisk; // 08
    uint16_t numberEntries; // 0a
    uint32_t centralFileHeaderSize; // 0c
    uint32_t offsetCentralFileHeader; // 10
    uint16_t zipFileCommentLength; // 14
    // zip file comment
} EndCentralFileHeader;
#pragma pack(pop)

#endif /* Header_h */
