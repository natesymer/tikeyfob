//
//  TIKeyfob.h
//  TIKeyfob
//
//  Created by Nathaniel Symer on 2/17/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum {
    TIKeyfobBuzzerVolumeHigh,
    TIKeyfobBuzzerVolumeLow,
    TIKeyfobBuzzerVolumeOff
} TIKeyfobBuzzerVolume;

@interface TIKeyfob : NSObject

+ (TIKeyfob *)shared;

- (BOOL)scanForBLEPeripheralsWithTimeout:(float)timeout;
- (BOOL)connectPeripheral:(CBPeripheral *)peripheral;
- (void)disconnect;

- (void)readBattery;
- (void)enableAccelerometer;
- (void)disableAccelerometer;
- (void)enableButtons;
- (void)disableButtons;
- (void)enableTXPower;
- (void)disableTXPower;

@property (nonatomic, copy) void(^bluetoothDevicesFoundBlock)(NSArray *peripherals);
@property (nonatomic, copy) void(^keyfobPairedBlock)(void);
@property (nonatomic, copy) void(^leftKeyBlock)(BOOL pressed);
@property (nonatomic, copy) void(^rightKeyBlock)(BOOL pressed);
@property (nonatomic, copy) void(^batterLevelChangedBlock)(void);
@property (nonatomic, copy) void(^axisMovedBlock)(void);
@property (nonatomic, copy) void(^TxPwrLevelChanged)(void);

@property (nonatomic, assign) TIKeyfobBuzzerVolume buzzerVolume;
@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float z;
@property (nonatomic, assign) float batteryLevel;
@property (nonatomic, assign) float TXPwrLevel;

@property (nonatomic, assign) BOOL isPaired;

@end
