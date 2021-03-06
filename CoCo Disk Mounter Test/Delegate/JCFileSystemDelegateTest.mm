//
//  JCFileSystemDelegateTest.mm
//  CoCo Disk Mounter
//
//  Created by Jamie Cho on 2013-02-25.
//  Copyright (c) 2013 Jamie Cho. All rights reserved.
//

#import "JCFileSystemDelegateTest.h"

#import "../../CoCo Disk Mounter/Delegate/JCFileSystemDelegate.h"
#import "../../CoCo Disk Mounter/Delegate/JCError.h"
#import "../../CoCo Disk Mounter/Delegate/JCConversionUtils.h"
#import "../../CoCo Disk Mounter/Model/NilFileSystem.h"
#import "../helpers/GmockInitializer.h"
#include "../model/MockFileSystem.h"

using namespace testing;

@implementation JCFileSystemDelegateTest

- (void)setUp {
    [super setUp];
    GmockInitializer::initialize();
}

- (void)testConvertsExceptionsToErrors {
    // Successful call
    NSError *error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    STAssertTrue(JCFileSystemDelegateRunFunctionAndHandleExceptions([] () { }, &error), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() should return true when the function does not throw");
    STAssertNil(error, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() should set the error to nil when the function does not throw");
    
    // FileNotFoundException
    error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    STAssertFalse(JCFileSystemDelegateRunFunctionAndHandleExceptions([] () { throw CoCoDiskMounter::FileNotFoundException("/foo/bar"); }, &error), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() should return false when the function throws");
    STAssertEquals(error.domain, JCErrorDomain, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error domain should be JCErrorDomain");
    STAssertEquals(error.code, JCErrorDomainFileNotFound, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error code should be JCErrorDomainFileNotFound when CoCoDiskMounter::FileNotFoundException thrown.");
    STAssertEquals(error.userInfo.count, 1uL, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo should have 1 entry");
    STAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], JCConvertStringToNSString(CoCoDiskMounter::FileNotFoundException("/foo/bar").getReason()), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo NSLocalizedDescriptionKey is incorrect");

    // IOException
    error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    STAssertFalse(JCFileSystemDelegateRunFunctionAndHandleExceptions([] () { throw CoCoDiskMounter::IOException("/foo/bar"); }, &error), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() should return false when the function throws");
    STAssertEquals(error.domain, JCErrorDomain, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error domain should be JCErrorDomain");
    STAssertEquals(error.code, JCErrorDomainIO, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error code should be JCErrorDomainIO when CoCoDiskMounter::IOException thrown.");
    STAssertEquals(error.userInfo.count, 1uL, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo should have 1 entry");
    STAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], JCConvertStringToNSString(CoCoDiskMounter::IOException("/foo/bar").getReason()), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo NSLocalizedDescriptionKey is incorrect");
    
    // Exception
    error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    STAssertFalse(JCFileSystemDelegateRunFunctionAndHandleExceptions([] () { throw CoCoDiskMounter::Exception("/foo/bar"); }, &error), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() should return false when the function throws");
    STAssertEquals(error.domain, JCErrorDomain, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error domain should be JCErrorDomain");
    STAssertEquals(error.code, JCErrorDomainGeneric, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error code should be JCErrorDomainGeneric when CoCoDiskMounter::Exception thrown.");
    STAssertEquals(error.userInfo.count, 1uL, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo should have 1 entry");
    STAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], JCConvertStringToNSString(CoCoDiskMounter::Exception("/foo/bar").getReason()), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo NSLocalizedDescriptionKey is incorrect");
    
    // Unknown Exceptions
    error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    STAssertFalse(JCFileSystemDelegateRunFunctionAndHandleExceptions([] () { throw std::string("hello"); }, &error), @"JCFileSystemDelegateRunFunctionAndHandleExceptions() should return false when the function throws");
    STAssertEquals(error.domain, JCErrorDomain, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error domain should be JCErrorDomain");
    STAssertEquals(error.code, JCErrorDomainGeneric, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error code should be JCErrorDomainGeneric when an unknown exception is thrown.");
    STAssertEquals(error.userInfo.count, 1uL, @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo should have 1 entry");
    STAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"Unknown exception", @"JCFileSystemDelegateRunFunctionAndHandleExceptions() error userInfo NSLocalizedDescriptionKey is incorrect");
}

- (void)testAttributeDictionaryFromMap {
    // Try adding only one entry
    std::map<CoCoDiskMounter::IFileSystem::Attribute_t, long> map;
    map[CoCoDiskMounter::IFileSystem::AttributeFileSize] = 1234;
    NSDictionary *dictionary;
    @autoreleasepool {
        dictionary = [JCFileSystemDelegate attributeDictionaryFromMap:map];
        STAssertEquals(dictionary.count, 1uL, @"Attribute dictionary should have only one entry");
        STAssertEquals(dictionary[NSFileSize], [NSNumber numberWithLong:1234], @"NSFileSize attribute entry must be 1234");
        [dictionary retain];
    }
    STAssertEquals(dictionary.retainCount, 1ul, @"attributeDictionaryFromMap is not autoreleasing dictionary");
    
    // Try adding multiple entries
    map[CoCoDiskMounter::IFileSystem::AttributeFileType] = CoCoDiskMounter::IFileSystem::FileTypeDirectory;
    map[CoCoDiskMounter::IFileSystem::AttributeGroupOwnerAccountID] = 54321;
    map[CoCoDiskMounter::IFileSystem::AttributeOwnerAccountID] = 321;
    map[CoCoDiskMounter::IFileSystem::AtributeFileModificationDate] = 1005;
    map[CoCoDiskMounter::IFileSystem::AttributePosixPermissions] = 0753;
    map[CoCoDiskMounter::IFileSystem::AttributeReferenceCount] = 10;
    map[CoCoDiskMounter::IFileSystem::AttributeSystemFileAccessDateKey] = 1001;
    map[CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey] = 1002;
    map[CoCoDiskMounter::IFileSystem::AttributeSystemFileChangeDateKey] = 1003;
    map[CoCoDiskMounter::IFileSystem::AttributeSystemFileFlagsKey] = 1004;
    map[CoCoDiskMounter::IFileSystem::AttributeSystemFileNumber] = 64;
    // next entry is bogus and should be ignored
    map[(CoCoDiskMounter::IFileSystem::Attribute_t)1000] = 643215;

    // Check entries
    @autoreleasepool {
        dictionary = [JCFileSystemDelegate attributeDictionaryFromMap:map];
        [dictionary retain];
        STAssertEquals(dictionary.count, 12uL, @"Attribute dictionary should have 12 entries");
        STAssertEquals([NSNumber numberWithLong:1234], dictionary[NSFileSize], @"NSFileSize attribute entry must be 1234");
        STAssertEquals(dictionary[NSFileType], NSFileTypeDirectory, @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeFileType");
        STAssertEqualObjects(dictionary[NSFileGroupOwnerAccountID], [NSNumber numberWithLong:54321], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeGroupOwnerAccountID");
        STAssertEqualObjects(dictionary[NSFileModificationDate], [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1005/1000.0], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeFileModificationDate");
        STAssertEqualObjects(dictionary[NSFileOwnerAccountID], [NSNumber numberWithLong:321], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributePosixPermissions");
        STAssertEqualObjects(dictionary[NSFilePosixPermissions], [NSNumber numberWithLong:0753], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeOwnerAccountID");
        STAssertEqualObjects(dictionary[NSFileReferenceCount], [NSNumber numberWithLong:10], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeReferenceCount");
        STAssertEqualObjects(dictionary[kGMUserFileSystemFileAccessDateKey], [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1001/1000.0], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey");
        STAssertEqualObjects(dictionary[kGMUserFileSystemFileBackupDateKey], [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1002/1000.0], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey");
        STAssertEqualObjects(dictionary[kGMUserFileSystemFileChangeDateKey], [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1003/1000.0], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeSystemFileChangeDateKey");
        STAssertEqualObjects(dictionary[kGMUserFileSystemFileFlagsKey], [NSNumber numberWithLong:1004], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeSystemFileFlagsKey");
        STAssertEqualObjects(dictionary[NSFileSystemFileNumber], [NSNumber numberWithLong:64], @"attributeDictionaryFromMap is not properly mapping CoCoDiskMounter::IFileSystem::AttributeSystemFileNumber");
    }
    STAssertEquals(dictionary.retainCount, 1uL, @"dictionary not autoreleased");
    [dictionary release];
}

- (void)testDictionaryAttributeFromMapAttribute {
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeFileType], NSFileType, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeFileType");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeFileSize], NSFileSize, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeFileSize");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AtributeFileModificationDate], NSFileModificationDate, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AtributeFileModificationDate");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeReferenceCount], NSFileReferenceCount, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeReferenceCount");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributePosixPermissions], NSFilePosixPermissions, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributePosixPermissions");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeOwnerAccountID], NSFileOwnerAccountID, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeOwnerAccountID");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeGroupOwnerAccountID], NSFileGroupOwnerAccountID, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeGroupOwnerAccountID");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileNumber], NSFileSystemFileNumber, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeSystemFileNumber");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey], kGMUserFileSystemFileBackupDateKey, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileChangeDateKey], kGMUserFileSystemFileChangeDateKey, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeSystemFileChangeDateKey");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileAccessDateKey], kGMUserFileSystemFileAccessDateKey, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeSystemFileAccessDateKey");
    STAssertEqualObjects([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileFlagsKey], kGMUserFileSystemFileFlagsKey, @"dictionaryAttributeFromMapAttribute does not properly map CoCoDiskMounter::IFileSystem::AttributeSystemFileFlagsKey");
    STAssertNil([JCFileSystemDelegate dictionaryAttributeFromMapAttribute:(CoCoDiskMounter::IFileSystem::Attribute_t)10000], @"dictionaryAttributeFromMapAttribute does not properly map invalid attributes");
}

- (void)testDictionaryAttributeValueFromMapAttribute {
    STAssertEqualObjects(NSFileTypeRegular, [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeFileType mapValue:CoCoDiskMounter::IFileSystem::FileTypeRegular], @"dictionaryAttributeValueFromMapAttribute does not properly map file types");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1001/1000.0], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AtributeFileModificationDate mapValue:1001], @"dictionaryAttributeValueFromMapAttribute does not properly map modified dates");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1002/1000.0], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey mapValue:1002], @"dictionaryAttributeValueFromMapAttribute does not properly map backup dates");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1003/1000.0], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileBackupDateKey mapValue:1003], @"dictionaryAttributeValueFromMapAttribute does not properly map change dates");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)1004/1000.0], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileAccessDateKey mapValue:1004], @"dictionaryAttributeValueFromMapAttribute does not properly map file access dates");
    STAssertEqualObjects([NSNumber numberWithLong:12345], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeFileSize mapValue:12345], @"dictionaryAttributeValueFromMapAttribute does not properly map file size");
    STAssertEqualObjects([NSNumber numberWithLong:1234], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeFileSize mapValue:1234], @"dictionaryAttributeValueFromMapAttribute does not properly map file size");
    STAssertEqualObjects([NSNumber numberWithLong:123], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributePosixPermissions mapValue:123], @"dictionaryAttributeValueFromMapAttribute does not properly map posix permissions");
    STAssertEqualObjects([NSNumber numberWithLong:12], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeOwnerAccountID mapValue:12], @"dictionaryAttributeValueFromMapAttribute does not properly map account id");
    STAssertEqualObjects([NSNumber numberWithLong:54321], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeGroupOwnerAccountID mapValue:54321], @"dictionaryAttributeValueFromMapAttribute does not properly map group account id");
    STAssertEqualObjects([NSNumber numberWithLong:5432], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileFlagsKey mapValue:5432], @"dictionaryAttributeValueFromMapAttribute does not properly map group flags");
    STAssertEqualObjects([NSNumber numberWithLong:5432], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:CoCoDiskMounter::IFileSystem::AttributeSystemFileNumber mapValue:5432], @"dictionaryAttributeValueFromMapAttribute does not properly map file number");
    STAssertEqualObjects([NSNumber numberWithLong:543], [JCFileSystemDelegate dictionaryAttributeValueFromMapAttribute:(CoCoDiskMounter::IFileSystem::Attribute_t)1000 mapValue:543], @"dictionaryAttributeValueFromMapAttribute does not properly map invalid keys");
}

- (void)testDictionaryFileTypeFromMapFileType {
    STAssertEqualObjects(NSFileTypeRegular, [JCFileSystemDelegate dictionaryFileTypeFromMapFileType:CoCoDiskMounter::IFileSystem::FileTypeRegular], @"dictionaryFileTypeFromMapFileType does not properly map FileTypeRegular");
    STAssertEqualObjects(NSFileTypeDirectory, [JCFileSystemDelegate dictionaryFileTypeFromMapFileType:CoCoDiskMounter::IFileSystem::FileTypeDirectory], @"dictionaryFileTypeFromMapFileType does not properly map FileTypeDirectory");
    STAssertEqualObjects(NSFileTypeSymbolicLink, [JCFileSystemDelegate dictionaryFileTypeFromMapFileType:CoCoDiskMounter::IFileSystem::FileTypeSymbolicLink], @"dictionaryFileTypeFromMapFileType does not properly map FileTypeSymbolicLink");
    STAssertEqualObjects(NSFileTypeUnknown, [JCFileSystemDelegate dictionaryFileTypeFromMapFileType:(CoCoDiskMounter::IFileSystem::FileType_t)100], @"dictionaryFileTypeFromMapFileType does not properly map invalid attributes");
}

- (void)testFileOpenModeFromOpenMode {
    STAssertEquals(CoCoDiskMounter::IFileSystem::FileOpenModeReadOnly, [JCFileSystemDelegate fileOpenModeFromOpenMode:O_RDONLY], @"fileOpenModeFromOpenMode does not properly map fileOpenModeFromOpenMode");
    try {
        [JCFileSystemDelegate fileOpenModeFromOpenMode:O_RDWR];
        STFail(@"fileOpenModeFromOpenMode should only convert");
    } catch(CoCoDiskMounter::IOException &ioe) {        
    }
}

- (void)testNilFileSystemUsedByDefaultInitializer {
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] init] autorelease];
    NSError *error = nil;
    id userData = nil;
    STAssertEquals(0uL, [[target contentsOfDirectoryAtPath:@"/" error:&error] count], @"should return no directory entries");
    STAssertNil(error, @"contentsOfDirectoryAtPath:error should return no error");
    std::map<CoCoDiskMounter::IFileSystem::Attribute_t, long> mapAttributes;
    STAssertEquals(0uL, [[target attributesOfItemAtPath:@"/" userData:nil error:&error] count], @"attributesOfItemAtPath:userData:error should return no attribute entries");
    STAssertNil(error, @"attributesOfItemAtPath:userData:error should return no error");
    STAssertTrue([target openFileAtPath:@"/foo/bar" mode:O_RDONLY userData:&userData error:&error], @"openFileAtPath:mode:userData:error should return true");
    STAssertNil(error, @"openFileAtPath:mode:userData:error should return no error");
    STAssertEqualObjects([NSNumber numberWithLong:0], userData, @"openFileAtPath:mode:userData:error should return no userData");
    char buffer[1024];
    STAssertEquals(0, [target readFileAtPath:@"/foo/bar" userData:userData buffer:buffer size:sizeof(buffer) offset:100 error:&error], @"readFileAtPath:userData:buffer:offset:error should return 0");
    STAssertNil(error, @"readFileAtPath:userData:buffer:offset:error should return no error");
    [target releaseFileAtPath:@"/foo/bar" userData:userData];
    STAssertEquals(0uL, [[target extendedAttributesOfItemAtPath:@"/foo/bar" error:&error] count], @"extendedAttributesOfItemAtPath:error should return no attributes");
    STAssertNil(error, @"extendedAttributesOfItemAtPath:error should return no error");
}

ACTION(addFilePaths) {
    arg0.push_back("/hello world!");
    arg0.push_back("/hello ɕ!");
    return;
}

- (void)testReturnsContentsOfDirectoryPath {
    // Should return the contents
    std::shared_ptr<CoCoDiskMounterTest::MockFileSystem> dummyFileSystem(new CoCoDiskMounterTest::MockFileSystem());
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] initWithFileSystem:dummyFileSystem] autorelease];
    NSError *error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    NSArray *contents;
    @autoreleasepool {
        ON_CALL((*dummyFileSystem), contentsOfDirectoryAtPath(_, _)).WillByDefault(addFilePaths());
        EXPECT_CALL((*dummyFileSystem), contentsOfDirectoryAtPath(testing::ElementsAre(), "/foo/ɕ!"));
        contents = [target contentsOfDirectoryAtPath:@"/foo/ɕ!" error:&error];
        STAssertEquals(2ul, [contents count], @"contentsOfDirectoryAtPath: did not return correct number of entries");
        STAssertEqualObjects(@"/hello world!", contents[0], @"contentsOfDirectoryAtPath: first item not correct");
        STAssertEqualObjects(@"/hello ɕ!", contents[1], @"contentsOfDirectoryAtPath: second item not correct");
        STAssertNil(error, @"contentsOfDirectoryAtPath: error not nil");
        [contents retain];
    }
    STAssertEquals(1ul, contents.retainCount, @"contentsOfDirectoryAtPath: content retainCount is incorrect");
    [contents release];
    
    // Should forward error
    error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    @autoreleasepool {
        ON_CALL((*dummyFileSystem), contentsOfDirectoryAtPath(_, _)).WillByDefault(Throw(CoCoDiskMounter::Exception()));
        EXPECT_CALL((*dummyFileSystem), contentsOfDirectoryAtPath(testing::ElementsAre(), "/foo/ɕ!"));
        STAssertNil([target contentsOfDirectoryAtPath:@"/foo/ɕ!" error:&error], @"contentsOfDirectoryAtPath: error does not return nil");
        STAssertEqualObjects(JCErrorDomain, error.domain, @"contentsOfDirectoryAtPath: error domain is incorrect");
        STAssertEquals(JCErrorDomainGeneric, error.code, @"contentsOfDirectoryAtPath: code domain is incorrect");
    }
}

ACTION(addFileAttributes) {
    arg0[CoCoDiskMounter::IFileSystem::AttributeFileType] = CoCoDiskMounter::IFileSystem::FileTypeRegular;
    arg0[CoCoDiskMounter::IFileSystem::AtributeFileModificationDate] = 2000000L;
    return;
}

- (void)testAttributesOfItemAtPath {
    std::shared_ptr<CoCoDiskMounterTest::MockFileSystem> dummyFileSystem(new CoCoDiskMounterTest::MockFileSystem());
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] initWithFileSystem:dummyFileSystem] autorelease];
    NSError *error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    NSDictionary *attributes;
    @autoreleasepool {
        ON_CALL((*dummyFileSystem), getPropertiesOfFile(_, _)).WillByDefault(addFileAttributes());
        EXPECT_CALL((*dummyFileSystem), getPropertiesOfFile(testing::ElementsAre(), "/foo/ɕ!"));
        attributes = [target attributesOfItemAtPath:@"/foo/ɕ!" userData:(id)0x123456 error:&error];
        STAssertNil(error, @"attributesOfItemAtPath: error not nil");
        STAssertEquals(2ul, attributes.count, @"attributesOfItemAtPath: returned wrong number of items");
        STAssertEqualObjects(NSFileTypeRegular, attributes[NSFileType], @"attributesOfItemAtPath: did not return correctfile type");
        STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:2000.0], attributes[NSFileModificationDate], @"attributesOfItemAtPath: did not return correct file modification date");
        [attributes retain];
    }
    STAssertEquals(1ul, attributes.retainCount, @"attributesOfItemAtPath: attributes retainCount is incorrect");
    [attributes release];
    
    // Should forward error
    error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    @autoreleasepool {
        ON_CALL((*dummyFileSystem), getPropertiesOfFile(_, _)).WillByDefault(Throw(CoCoDiskMounter::FileNotFoundException("/foo/ɕ!")));
        EXPECT_CALL((*dummyFileSystem), getPropertiesOfFile(testing::ElementsAre(), "/foo/ɕ!"));
        STAssertNil([target attributesOfItemAtPath:@"/foo/ɕ!" userData:(id)0x123456 error:&error], @"attributesOfItemAtPath: error does not return nil");
        STAssertEqualObjects(JCErrorDomain, error.domain, @"attributesOfItemAtPath: error domain is incorrect");
        STAssertEquals(error.code, JCErrorDomainFileNotFound, @"attributesOfItemAtPath: code domain is incorrect");
    }
}

- (void)testOpensFile {
    std::shared_ptr<CoCoDiskMounterTest::MockFileSystem> dummyFileSystem(new CoCoDiskMounterTest::MockFileSystem());
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] initWithFileSystem:dummyFileSystem] autorelease];
    NSError *error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    id userData = nil;
    @autoreleasepool {
        ON_CALL((*dummyFileSystem), openFileAtPath("/foo/ɕ!", CoCoDiskMounter::IFileSystem::FileOpenModeReadOnly)).WillByDefault(Return((void *)0x54321));
        EXPECT_CALL((*dummyFileSystem), openFileAtPath("/foo/ɕ!", CoCoDiskMounter::IFileSystem::FileOpenModeReadOnly));
        STAssertTrue([target openFileAtPath:@"/foo/ɕ!" mode:O_RDONLY userData:&userData error:&error], @"openFileAtPath: should return true when the open call is successful");
        STAssertEquals([userData longValue], 0x54321L, @"openFileAtPath: userData not set properly");
    }
    
    ON_CALL((*dummyFileSystem), openFileAtPath("/foo/ɕ!", CoCoDiskMounter::IFileSystem::FileOpenModeReadOnly)).WillByDefault(Throw(CoCoDiskMounter::FileNotFoundException("/foo/ɕ!")));
    EXPECT_CALL((*dummyFileSystem), openFileAtPath("/foo/ɕ!", CoCoDiskMounter::IFileSystem::FileOpenModeReadOnly));
    userData = nil;
    STAssertFalse([target openFileAtPath:@"/foo/ɕ!" mode:O_RDONLY userData:&userData error:&error], @"openFileAtPath: should return false when the open call fails");
    STAssertEqualObjects(JCErrorDomain, error.domain, @"openFileAtPath: error domain is incorrect");
    STAssertEquals(error.code, JCErrorDomainFileNotFound, @"openFileAtPath: code domain is incorrect");
}

- (void)testClosesFile {
    std::shared_ptr<CoCoDiskMounterTest::MockFileSystem> dummyFileSystem(new CoCoDiskMounterTest::MockFileSystem());
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] initWithFileSystem:dummyFileSystem] autorelease];
    EXPECT_CALL((*dummyFileSystem), closeFile((void *)0x54321));
    [target releaseFileAtPath:@"/foo/ɕ!" userData:[NSNumber numberWithLong:0x54321]];

    // Should absorb thrown exceptions
    try {
        ON_CALL((*dummyFileSystem), closeFile((void *)0x54321)).WillByDefault(Throw(CoCoDiskMounter::FileNotFoundException("oops!")));
        EXPECT_CALL((*dummyFileSystem), closeFile((void *)0x54321));
        [target releaseFileAtPath:@"/foo/ɕ!" userData:[NSNumber numberWithLong:0x54321]];
    } catch(...) {
        STFail(@"releaseFileAtPath: should absorb exceptions thrown by closeFile");
    }
}

- (void)testReadsFile {
    std::shared_ptr<CoCoDiskMounterTest::MockFileSystem> dummyFileSystem(new CoCoDiskMounterTest::MockFileSystem());
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] initWithFileSystem:dummyFileSystem] autorelease];
    char buffer[1024];
    NSError *error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    ON_CALL((*dummyFileSystem), readFile((void *)0x54321L, buffer, sizeof(buffer), 25)).WillByDefault(Return(32));
    EXPECT_CALL((*dummyFileSystem), readFile((void *)0x54321L, buffer, sizeof(buffer), 25));
    STAssertEquals([target readFileAtPath:@"/foo/ɕ!" userData:[NSNumber numberWithLong:0x54321] buffer:buffer size:sizeof(buffer) offset:25 error:&error], 32, @"readFileAtPath: not returning correct number of read bytes.");
    STAssertNil(error, @"readFileAtPath: not setting error to nil when called successfully");

    ON_CALL((*dummyFileSystem), readFile((void *)0x54321L, buffer, sizeof(buffer), 25)).WillByDefault(Throw(CoCoDiskMounter::IOException()));
    EXPECT_CALL((*dummyFileSystem), readFile((void *)0x54321L, buffer, sizeof(buffer), 25));
    STAssertEquals([target readFileAtPath:@"/foo/ɕ!" userData:[NSNumber numberWithLong:0x54321] buffer:buffer size:sizeof(buffer) offset:25 error:&error], -1, @"readFileAtPath: not returning -1 when exception thrown.");
    STAssertEqualObjects(JCErrorDomain, error.domain, @"readFileAtPath: error domain is incorrect");
    STAssertEquals(error.code, JCErrorDomainIO, @"readFileAtPath: code domain is incorrect");
}

-(void)testReturnsEmptyExtendedAttributes {
    std::shared_ptr<CoCoDiskMounterTest::MockFileSystem> dummyFileSystem(new CoCoDiskMounterTest::MockFileSystem());
    JCFileSystemDelegate *target = [[[JCFileSystemDelegate alloc] initWithFileSystem:dummyFileSystem] autorelease];
    NSArray *attributes;
    NSError *error = [NSError errorWithDomain:@"xxx" code:123 userInfo:nil];
    @autoreleasepool {
        attributes = [target extendedAttributesOfItemAtPath:@"/foo/ɕ!" error:&error];
        STAssertEquals(attributes.count, 0uL, @"extendedAttributesOfItemAtPath: should return an empty list");
        STAssertNil(error, @"extendedAttributesOfItemAtPath: should set error to nil");
    }
}

@end
