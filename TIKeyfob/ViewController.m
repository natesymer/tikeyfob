//
//  ViewController.m
//  TIKeyfob
//
//  Created by Nathaniel Symer on 2/17/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "TIKeyfob.h"

@interface ViewController ()

@property (nonatomic, strong) UIView *leftButton;
@property (nonatomic, strong) UIView *rightButton;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    float width = UIScreen.mainScreen.bounds.size.width;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(0, 20, width, 44);
    [button addTarget:self action:@selector(scanForFob) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Scan" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    UIView *background = [[UIView alloc]initWithFrame:CGRectMake(50, 80, width-100, 300)];
    background.backgroundColor = [UIColor blackColor];
    background.layer.cornerRadius = 20;
    [self.view addSubview:background];
    
    self.leftButton = [[UIView alloc]initWithFrame:CGRectMake(100, 100, 50, 25)];
    _leftButton.backgroundColor = [UIColor whiteColor];
    _leftButton.layer.cornerRadius = 5;
    [self.view addSubview:_leftButton];
    
    self.rightButton = [[UIView alloc]initWithFrame:CGRectMake(width-150, 100, 50, 25)];
    _rightButton.backgroundColor = [UIColor whiteColor];
    _rightButton.layer.cornerRadius = 5;
    [self.view addSubview:_rightButton];
    
    TIKeyfob.shared.bluetoothDevicesFoundBlock = ^(NSArray *peripherals){
        [TIKeyfob.shared connectPeripheral:peripherals.firstObject];
    };
    
    TIKeyfob.shared.keyfobPairedBlock = ^{
        [TIKeyfob.shared enableButtons];
        [TIKeyfob.shared enableAccelerometer];
        TIKeyfob.shared.buzzerVolume = TIKeyfobBuzzerVolumeHigh;
    };
    
    TIKeyfob.shared.leftKeyBlock = ^(BOOL pressed){
        TIKeyfob.shared.buzzerVolume = pressed?TIKeyfobBuzzerVolumeLow:TIKeyfobBuzzerVolumeOff;
        _leftButton.backgroundColor = pressed?[UIColor greenColor]:[UIColor whiteColor];
        [self sendNotifWithText:@"Left button pressed."];
    };
    
    TIKeyfob.shared.rightKeyBlock = ^(BOOL pressed){
        [self sendNotifWithText:@"Right button pressed."];
        TIKeyfob.shared.buzzerVolume = pressed?TIKeyfobBuzzerVolumeHigh:TIKeyfobBuzzerVolumeOff;
        _rightButton.backgroundColor = pressed?[UIColor greenColor]:[UIColor whiteColor];
    };
}

- (void)sendNotifWithText:(NSString *)text {
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.repeatInterval = NSDayCalendarUnit;
    [notification setAlertBody:text];
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
    [UIApplication.sharedApplication setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

- (void)scanForFob {
    [[TIKeyfob shared]scanForBLEPeripheralsWithTimeout:30.0f];
}

@end
