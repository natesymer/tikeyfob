//
//  CBService+TIKeyfob.h
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBService (TIKeyfob)

- (CBCharacteristic *)characteristicWithUUID:(CBUUID *)UUID;

@end
