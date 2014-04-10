//
//  CBPeripheral+TIKeyfob.m
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "CBPeripheral+TIKeyfob.h"
#import "CBUUID+TIKeyfob.h"
#import "CBService+TIKeyfob.h"
#import "tilog.h"

@implementation CBPeripheral (TIKeyfob)

- (CBService *)serviceWithUUID:(CBUUID *)UUID {
    for (CBService *service in self.services) {
        if ([service.UUID isEqualToUUID:UUID]) {
            return service;
        }
    }
    return nil;
}

- (CBCharacteristic *)characteristicWithServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID {
    CBUUID *su = [CBUUID UUIDWithInt:serviceUUID];
    CBUUID *cu = [CBUUID UUIDWithInt:characteristicUUID];
    
    CBService *service = [self serviceWithUUID:su];
    
    if (!service) {
        tilog(@"Peripheral %@: Failed to find service %@.", self.identifier.UUIDString, su.stringValue);
        return nil;
    }
    
    CBCharacteristic *characteristic = [service characteristicWithUUID:cu];
    
    if (!characteristic) {
        tilog(@"Peripheral %@: Failed to find characteristic %@ on service %@.", self.identifier.UUIDString, cu.stringValue, su.stringValue);
        return nil;
    }
    
    return characteristic;
}

- (BOOL)writeValue:(NSData *)data forServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID {
    CBCharacteristic *characteristic = [self characteristicWithServiceUUID:serviceUUID characteristicUUID:characteristicUUID];
    
    if (!characteristic) return NO;
    
    [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    return YES;
}

- (BOOL)readValueForServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID {
    CBCharacteristic *characteristic = [self characteristicWithServiceUUID:serviceUUID characteristicUUID:characteristicUUID];
    
    if (!characteristic) return NO;
    
    [self readValueForCharacteristic:characteristic];
    return YES;
}

- (BOOL)setNotifyValue:(BOOL)on forServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID {
    CBCharacteristic *characteristic = [self characteristicWithServiceUUID:serviceUUID characteristicUUID:characteristicUUID];
    
    if (!characteristic) return NO;
    
    [self setNotifyValue:on forCharacteristic:characteristic];
    return YES;
}

@end
