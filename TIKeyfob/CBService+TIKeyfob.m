//
//  CBService+TIKeyfob.m
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "CBService+TIKeyfob.h"
#import "CBUUID+TIKeyfob.h"

@implementation CBService (TIKeyfob)

- (CBCharacteristic *)characteristicWithUUID:(CBUUID *)UUID {
    for (CBCharacteristic *c in self.characteristics) {
        if ([c.UUID isEqualToUUID:UUID]) {
            return c;
        }
    }
    return nil;
}

@end
