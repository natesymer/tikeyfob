//
//  CBPeripheral+TIKeyfob.h
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (TIKeyfob)

- (CBService *)serviceWithUUID:(CBUUID *)UUID;

- (BOOL)writeValue:(NSData *)data forServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID;
- (BOOL)readValueForServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID;
- (BOOL)setNotifyValue:(BOOL)on forServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID;

@end
