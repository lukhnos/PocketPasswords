//
//  PPStore.m
//  PocketPasswords
//
//  Created by Lukhnos Liu on 3/25/15.
//  Copyright (c) 2015 Lukhnos Liu. All rights reserved.
//

#import <stdlib.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Foundation/Foundation.h>
#import "PPStore.h"

static NSData *dataFromJSON(NSDictionary *jsonObj, NSString *keyPath)
{
    NSString *value = [jsonObj valueForKeyPath:keyPath];
    return [[NSData alloc] initWithBase64EncodedString:value options:0];
}

uint8_t *PPDecrypt(NSString *path, NSString *passphrase)
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return NULL;
    }

    const char *passphraseU8 = [passphrase UTF8String];

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        return NULL;
    }

    NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSData *encodedKey = dataFromJSON(jsonObj, @"encrypted_key.encrypted_key");
    NSData *hmac = dataFromJSON(jsonObj, @"encrypted_data.hmac");
    NSData *iv = dataFromJSON(jsonObj, @"encrypted_data.iv");
    uint rounds = (uint)[[jsonObj valueForKeyPath:@"encrypted_key.rounds"] unsignedIntegerValue];
    NSData *salt = dataFromJSON(jsonObj, @"encrypted_key.salt");
    NSData *cipherText = dataFromJSON(jsonObj, @"encrypted_data.ciphertext");

    // Derive the key to decode the encoding key.
    uint8_t derivedEncodingKey[32];
    bzero(derivedEncodingKey, sizeof(derivedEncodingKey));
    int result = CCKeyDerivationPBKDF(kCCPBKDF2, passphraseU8, strlen(passphraseU8), [salt bytes], [salt length], kCCPRFHmacAlgSHA256, rounds, derivedEncodingKey, sizeof(derivedEncodingKey));
    assert(result == 0);

    uint8_t encodingKey[32];
    size_t dataMoved;

    CCCryptorStatus status;
    status = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionECBMode, derivedEncodingKey, sizeof(derivedEncodingKey), NULL, [encodedKey bytes], [encodedKey length], encodingKey, sizeof(encodingKey), &dataMoved);
    assert(status == 0);
    assert(dataMoved == sizeof(encodingKey));

    uint8_t aesKey[32];
    uint8_t hmacKey[32];
    uint8_t keyDerivationData[32];

    size_t blockSize = 16;
    memset(keyDerivationData, 0x00, blockSize);
    memset(keyDerivationData + blockSize, 0x01, blockSize);
    status = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode, encodingKey, sizeof(encodingKey), NULL, keyDerivationData, sizeof(keyDerivationData), aesKey, sizeof(aesKey), &dataMoved);
    assert(status == 0);
    assert(dataMoved == sizeof(aesKey));

    memset(keyDerivationData, 0x02, blockSize);
    memset(keyDerivationData + blockSize, 0x03, blockSize);
    status = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode, encodingKey, sizeof(encodingKey), NULL, keyDerivationData, sizeof(keyDerivationData), hmacKey, sizeof(hmacKey), &dataMoved);
    assert(status == 0);
    assert(dataMoved == sizeof(aesKey));

    uint8_t computedHmac[32];
    CCHmac(kCCHmacAlgSHA256, hmacKey, sizeof(hmacKey), [cipherText bytes], [cipherText length], computedHmac);

    bool hmacMatch = true;
    for (int i = 0; i < 32; i++) {
        if (computedHmac[i] != *((uint8_t *)[hmac bytes] + i)) {
            hmacMatch = false;
        }
    }
    if (!hmacMatch) {
        return NULL;
    }

    uint8_t *plainText = (uint8_t *)calloc(1, [cipherText length] + 1);
    status = CCCrypt(kCCDecrypt, kCCAlgorithmAES, 0, aesKey, sizeof(aesKey), [iv bytes], [cipherText bytes], [cipherText length], plainText, [cipherText length], &dataMoved);
    assert(status == 0);
    assert(dataMoved == [cipherText length]);

    uint8_t lastByte = plainText[[cipherText length] - 1];
    size_t plainTextLength = [cipherText length] - lastByte;

    for (size_t i = 0; i < plainTextLength; i++) {
        if (plainText[i] == 0) {
            plainText[i] = 32;
        }
    }


    for (size_t i = plainTextLength, l = [cipherText length]; i < l; i++) {
        plainText[i] = 0;
    }

    return plainText;
}



@implementation PPStore

+ (PPStore *)sharedInstance
{
    static PPStore *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PPStore alloc] init];
    });
    return instance;
}

- (NSUInteger)count
{
    if ([self.indices count] > 2) {
        return [self.indices count] - 2;
    }
    return 0;
}

- (NSArray *)headerRow
{
    return [self rawRowAtIndex:0];
}

- (NSArray *)rawRowAtIndex:(NSUInteger)index
{
    if (index + 1 >= [self.indices count]) {
        return [NSArray array];
    }

    NSUInteger start = [[self.indices objectAtIndex:index] unsignedIntegerValue];
    NSUInteger end = [[self.indices objectAtIndex:index + 1] unsignedIntegerValue];
    NSString *text = [self.text substringWithRange:NSMakeRange(start + 1, MAX(end - (start + 1), 0))];
    return [text componentsSeparatedByString:@"\t"];
}

- (void)loadStore:(NSString *)path passphrase:(NSString *)passphrase
{
    uint8_t *plaintext = PPDecrypt(path, passphrase);
    if (!plaintext) {
        return;
    }

    if (strncasecmp((const char *)plaintext, "title", 5)) {
        return;
    }

    self.text = [[NSMutableString alloc] initWithUTF8String:(const char *)plaintext];
    free(plaintext);

    NSUInteger length = [self.text length];

    self.indices = [NSMutableArray array];
    [self.indices addObject:@0];
    for (NSUInteger index = 0; index < length; index++) {
        if ([self.text characterAtIndex:index] == '\n') {
            [self.indices addObject:@(index)];
        }
    }
    [self.indices addObject:@(length)];
}

- (void)clearStore
{

    self.text = nil;
    self.indices = nil;
}

- (NSArray *)rowAtIndex:(NSUInteger)index
{
    return [self rawRowAtIndex:index + 1];
}

- (NSString *)titleAtIndex:(NSUInteger)index
{
    index += 1;
    if (index + 1 >= [self.indices count]) {
        return @"";
    }

    NSUInteger start = [[self.indices objectAtIndex:index] unsignedIntegerValue];
    NSUInteger end = [[self.indices objectAtIndex:index + 1] unsignedIntegerValue];
    NSUInteger firstStop = start;
    for (; firstStop < end; firstStop++) {
        if ([self.text characterAtIndex:firstStop] == '\t') {
            break;
        }
    }

    NSString *text = [self.text substringWithRange:NSMakeRange(start + 1, MAX(firstStop - (start + 1), 0))];
    return text;
}
@end