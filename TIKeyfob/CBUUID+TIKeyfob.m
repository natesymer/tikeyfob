//
//  CBUUID+TIKeyfob.m
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "CBUUID+TIKeyfob.h"

@implementation CBUUID (TIKeyfob)

- (NSString *)stringValue {
    NSData *data = [self data];
    
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (int currentByteIndex = 0; currentByteIndex < data.length; currentByteIndex++) {
        switch (currentByteIndex) {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return [NSString stringWithString:outputString];
}

- (int)intValue {
    char b1[16];
    [self.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

+ (CBUUID *)UUIDWithInt:(UInt16)intval {
    UInt16 swapped = intval << 8; swapped |= (intval >> 8);
    NSData *data = [NSData dataWithBytes:(char *)&swapped length:2];
    return [CBUUID UUIDWithData:data];
}

- (BOOL)isEqualToUUID:(CBUUID *)uuid {
    if (!uuid) {
        return NO;
    }
    
    char b1[16];
    char b2[16];
    [uuid.data getBytes:b1];
    [self.data getBytes:b2];
    return (memcmp(b1, b2, uuid.data.length) == 0)?YES:NO;
}

@end
