//
//  TIKeyfob.m
//  TIKeyfob
//
//  Created by Nathaniel Symer on 2/17/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "TIKeyfob.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

#define KEYFOB_NAME @"TI BLE Keyfob"

#ifndef TI_BLE_Demo_TIBLECBKeyfobDefines_h
#define TI_BLE_Demo_TIBLECBKeyfobDefines_h

// Defines for the TI CC2540 keyfob peripheral
// Some of these are BS... Namely the accelerometer...

#define TI_KEYFOB_PROXIMITY_ALERT_UUID                      0x1802
#define TI_KEYFOB_PROXIMITY_ALERT_PROPERTY_UUID             0x2a06
#define TI_KEYFOB_PROXIMITY_ALERT_ON_VAL                    0x01
#define TI_KEYFOB_PROXIMITY_ALERT_OFF_VAL                   0x00
#define TI_KEYFOB_PROXIMITY_ALERT_WRITE_LEN                 1
#define TI_KEYFOB_PROXIMITY_TX_PWR_SERVICE_UUID             0x1804
#define TI_KEYFOB_PROXIMITY_TX_PWR_NOTIFICATION_UUID        0x2A07
#define TI_KEYFOB_PROXIMITY_TX_PWR_NOTIFICATION_READ_LEN    1

#define TI_KEYFOB_BATT_SERVICE_UUID                         0xFFB0
#define TI_KEYFOB_LEVEL_SERVICE_UUID                        0xFFB1
#define TI_KEYFOB_POWER_STATE_UUID                          0xFFB2
#define TI_KEYFOB_LEVEL_SERVICE_READ_LEN                    1

#define TI_KEYFOB_ACCEL_SERVICE_UUID                        0xFFA0
#define TI_KEYFOB_ACCEL_ENABLER_UUID                        0xFFA1
#define TI_KEYFOB_ACCEL_RANGE_UUID                          0xFFA2
#define TI_KEYFOB_ACCEL_READ_LEN                            1
#define TI_KEYFOB_ACCEL_X_UUID                              0xFFA3
#define TI_KEYFOB_ACCEL_Y_UUID                              0xFFA4
#define TI_KEYFOB_ACCEL_Z_UUID                              0xFFA5

#define TI_KEYFOB_KEYS_SERVICE_UUID                         0xFFE0
#define TI_KEYFOB_KEYS_NOTIFICATION_UUID                    0xFFE1
#define TI_KEYFOB_KEYS_NOTIFICATION_READ_LEN                1

#endif

@interface TIKeyfob () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) CBCentralManager *CM;
@property (strong, nonatomic) CBPeripheral *activePeripheral;

@property (nonatomic, assign) BOOL isCMReady;

@property (nonatomic, assign) BOOL leftButtonPressed;
@property (nonatomic, assign) BOOL rightButtonPressed;

@end

@implementation TIKeyfob

void tilog(NSString *text, ...) {
#if(TI_DEBUG)
    va_list args;
    va_start(args, text);
    NSLogv([NSString stringWithFormat:@"TIKeyfob: %@",text], args);
    va_end(args);
#endif
}

+ (TIKeyfob *)shared {
    static TIKeyfob *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[TIKeyfob alloc]init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.CM = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    return self;
}

- (void)setBuzzerVolume:(TIKeyfobBuzzerVolume)buzzerVolume {
    Byte buzVal;
    switch (buzzerVolume) {
        case TIKeyfobBuzzerVolumeHigh:
            buzVal = 0x02;
            break;
        case TIKeyfobBuzzerVolumeLow:
            buzVal = 0x01;
            break;
        case TIKeyfobBuzzerVolumeOff:
            buzVal = 0x0;
            break;
        default:
            break;
    }
    NSData *d = [NSData dataWithBytes:&buzVal length:TI_KEYFOB_PROXIMITY_ALERT_WRITE_LEN];
    [self writeValue:TI_KEYFOB_PROXIMITY_ALERT_UUID characteristicUUID:TI_KEYFOB_PROXIMITY_ALERT_PROPERTY_UUID p:_activePeripheral data:d];
}

- (void)readBattery {
    [self readValue:TI_KEYFOB_BATT_SERVICE_UUID characteristicUUID:TI_KEYFOB_LEVEL_SERVICE_UUID p:_activePeripheral];
}

- (void)enableAccelerometer {
    char data = 0x01;
    NSData *d = [NSData dataWithBytes:&data length:1];
    [self writeValue:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_ENABLER_UUID p:_activePeripheral data:d];
    [self notification:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_X_UUID p:_activePeripheral on:YES];
    [self notification:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_Y_UUID p:_activePeripheral on:YES];
    [self notification:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_Z_UUID p:_activePeripheral on:YES];
}

- (void)disableAccelerometer {
    char data = 0x00;
    NSData *d = [NSData dataWithBytes:&data length:1];
    [self writeValue:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_ENABLER_UUID p:_activePeripheral data:d];
    [self notification:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_X_UUID p:_activePeripheral on:NO];
    [self notification:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_Y_UUID p:_activePeripheral on:NO];
    [self notification:TI_KEYFOB_ACCEL_SERVICE_UUID characteristicUUID:TI_KEYFOB_ACCEL_Z_UUID p:_activePeripheral on:NO];
}

- (void)enableButtons {
    [self notification:TI_KEYFOB_KEYS_SERVICE_UUID characteristicUUID:TI_KEYFOB_KEYS_NOTIFICATION_UUID p:_activePeripheral on:YES];
}

- (void)disableButtons {
    [self notification:TI_KEYFOB_KEYS_SERVICE_UUID characteristicUUID:TI_KEYFOB_KEYS_NOTIFICATION_UUID p:_activePeripheral on:NO];
}

- (void)enableTXPower {
    [self notification:TI_KEYFOB_PROXIMITY_TX_PWR_SERVICE_UUID characteristicUUID:TI_KEYFOB_PROXIMITY_TX_PWR_NOTIFICATION_UUID p:_activePeripheral on:YES];
}

- (void)disableTXPower {
    [self notification:TI_KEYFOB_PROXIMITY_TX_PWR_SERVICE_UUID characteristicUUID:TI_KEYFOB_PROXIMITY_TX_PWR_NOTIFICATION_UUID p:_activePeripheral on:NO];
}

- (void)writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    CBUUID *su = [self CBUUIDWithInt:serviceUUID];
    CBUUID *cu = [self CBUUIDWithInt:characteristicUUID];
    
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        //printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:p.UUID]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
       // printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:p.UUID]);
        return;
    }
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)readValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p {
    CBUUID *su = [self CBUUIDWithInt:serviceUUID];
    CBUUID *cu = [self CBUUIDWithInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        tilog(@"Failed to find service %@ on peripheral %@",su,p.identifier.UUIDString);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        tilog(@"Failed to find characteristic %@ on service %@ on peripheral %@",cu,su,p.identifier.UUIDString);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}

- (void)notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    CBUUID *su = [self CBUUIDWithInt:serviceUUID];
    CBUUID *cu = [self CBUUIDWithInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        tilog(@"Failed to find service %@ on peripheral %@",cu,p.identifier.UUIDString);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        tilog(@"Failed to find characteristic %@ on service %@ on peripheral %@",cu,su,p.identifier.UUIDString);
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
}

- (BOOL)scanForBLEPeripheralsWithTimeout:(float)timeout {
    if (!_isCMReady) {
        tilog(@"CoreBluetooth has not been initialized yet. If you're calling this immediately after making your first call to shared, you're triggering a race condition.");
        return NO;
    } else if (_CM.state != CBCentralManagerStatePoweredOn) {
        tilog(@"CoreBluetooth is not properly initialized. (State: %d)",_CM.state);
        return NO;
    }
    
    if (_activePeripheral && _activePeripheral.state == CBPeripheralStateConnected) {
        [_CM cancelPeripheralConnection:_activePeripheral];
    }
    
    if (timeout >= 0) {
        [NSTimer scheduledTimerWithTimeInterval:timeout target:_CM selector:@selector(stopScan) userInfo:nil repeats:NO];
    }

    [_CM scanForPeripheralsWithServices:nil options:0];
    return YES;
}

- (BOOL)connectPeripheral:(CBPeripheral *)peripheral {
    if (![peripheral.name isEqualToString:KEYFOB_NAME]) {
        tilog(@"The peripheral you're trying to connect to is not a TI BLE Keyfob.");
        return NO;
    }
    
    [_CM connectPeripheral:peripheral options:nil];
    return YES;
}

//
// CBCentralManagerDelegate methods
//

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    tilog(@"CBCentralManager state did update: %d",_CM.state);
    self.isCMReady = YES;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    tilog(@"Found Peripheral: %@",peripheral.name);
    
    if (![peripheral.name isEqualToString:KEYFOB_NAME]) {
        tilog(@"The peripheral is not a TI BLE Keyfob.");
        return;
    }

    if (!_peripherals) {
        _peripherals = [NSMutableArray arrayWithObjects:peripheral, nil];
    } else {
        for (int i = 0; i < _peripherals.count; i++) {
            CBPeripheral *p = _peripherals[i];
            if ([p.identifier isEqual:peripheral.identifier]) {
                _peripherals[i] = peripheral;
            }
        }
        [_peripherals addObject:peripheral];
    }
    
    if (_bluetoothDevicesFoundBlock) {
        _bluetoothDevicesFoundBlock(_peripherals);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [_CM stopScan];
    tilog(@"Connection to peripheral (%@) successful.",peripheral.name);
    self.activePeripheral = peripheral;
    _activePeripheral.delegate = self;
    [_activePeripheral discoverServices:nil];
}

//
// CBPeripheralDelegate methods
//

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        return;
    }
    
    tilog(@"Discovered characteristics.");
    
    for (CBCharacteristic *c in service.characteristics) {
        CBService *s = peripheral.services.lastObject;
        if ([self compareCBUUID:service.UUID UUID2:s.UUID]) {
            tilog(@"Paired with %@ (%@)",_activePeripheral.name,_activePeripheral.identifier.UUIDString);
            if (_keyfobPairedBlock) {
                _keyfobPairedBlock();
            }
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        for (CBService *s in peripheral.services) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    UInt16 characteristicUUID = [self CBUUIDToInt:characteristic.UUID];
    tilog(@"Characteristic UUID: %d",characteristicUUID);
    if (!error) {
        tilog(@"Characteristic UUID Error'd: %d",characteristicUUID);
        switch(characteristicUUID){
            case TI_KEYFOB_LEVEL_SERVICE_UUID:
            {
                char batlevel;
                [characteristic.value getBytes:&batlevel length:TI_KEYFOB_LEVEL_SERVICE_READ_LEN];
                self.batteryLevel = (float)batlevel;
                break;
            }
            case TI_KEYFOB_KEYS_NOTIFICATION_UUID:
            {
                char keys;
                [characteristic.value getBytes:&keys length:TI_KEYFOB_KEYS_NOTIFICATION_READ_LEN];
                
                BOOL tempLeftPressed = (keys & 0x01);
                BOOL tempRightPressed = (keys & 0x02);
                
                if (_leftKeyBlock && tempLeftPressed != _leftButtonPressed) {
                    _leftKeyBlock((keys & 0x01));
                }
                
                if (_rightKeyBlock && tempRightPressed != _rightButtonPressed) {
                    _rightKeyBlock((keys & 0x02));
                }
                
                self.leftButtonPressed = tempLeftPressed;
                self.rightButtonPressed = tempRightPressed;
                break;
            }
            case TI_KEYFOB_ACCEL_X_UUID:
            {
                char xval;
                [characteristic.value getBytes:&xval length:TI_KEYFOB_ACCEL_READ_LEN];
                self.x = (float)xval;
                if (_axisMovedBlock) {
                    _axisMovedBlock();
                }
                break;
            }
            case TI_KEYFOB_ACCEL_Y_UUID:
            {
                char yval;
                [characteristic.value getBytes:&yval length:TI_KEYFOB_ACCEL_READ_LEN];
                self.y = (float)yval;
                if (_axisMovedBlock) {
                    _axisMovedBlock();
                }
                break;
            }
            case TI_KEYFOB_ACCEL_Z_UUID:
            {
                char zval;
                [characteristic.value getBytes:&zval length:TI_KEYFOB_ACCEL_READ_LEN];
                self.z = (float)zval;
                if (_axisMovedBlock) {
                    _axisMovedBlock();
                }
                break;
            }
            case TI_KEYFOB_PROXIMITY_TX_PWR_NOTIFICATION_UUID:
            {
                char TXLevel;
                [characteristic.value getBytes:&TXLevel length:TI_KEYFOB_PROXIMITY_TX_PWR_NOTIFICATION_READ_LEN];
                self.TXPwrLevel = (float)TXLevel;
            }
            default:
            {
                break;
            }
        }
    }
}

//
// Helpers
//

- (CBUUID *)CBUUIDWithInt:(UInt16)intval {
    UInt16 swapped = intval << 8; swapped |= (intval >> 8);
    NSData *data = [NSData dataWithBytes:(char *)&swapped length:2];
    return [CBUUID UUIDWithData:data];
}

- (BOOL)compareCBUUID:(CBUUID *)UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    return (memcmp(b1, b2, UUID1.data.length) == 0)?YES:NO;
}

- (UInt16)CBUUIDToInt:(CBUUID *)UUID {
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

- (CBService *)findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    for (CBService *service in p.services) {
        if ([self compareCBUUID:service.UUID UUID2:UUID]) {
            return service;
        }
    }
    return nil;
}

- (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService *)service {
    for (CBCharacteristic *c in service.characteristics) {
        if ([self compareCBUUID:c.UUID UUID2:UUID]) {
            return c;
        }
    }
    return nil;
}

@end
