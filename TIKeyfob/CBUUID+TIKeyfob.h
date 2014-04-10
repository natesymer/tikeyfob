//
//  CBUUID+TIKeyfob.h
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBUUID (TIKeyfob)

- (NSString *)stringValue;
- (BOOL)isEqualToUUID:(CBUUID *)uuid;
+ (CBUUID *)UUIDWithInt:(UInt16)intval;
- (int)intValue;

@end
