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
@property (nonatomic, strong) UIButton *scanOrDisconnect;
@property (nonatomic, strong) UIActivityIndicatorView *scanningActView;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    float width = UIScreen.mainScreen.bounds.size.width;

    self.scanOrDisconnect = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _scanOrDisconnect.frame = CGRectMake(0, 20, width, 44);
    [_scanOrDisconnect addTarget:self action:@selector(scanForFob) forControlEvents:UIControlEventTouchUpInside];
    [_scanOrDisconnect setTitle:@"Scan" forState:UIControlStateNormal];
    [self.view addSubview:_scanOrDisconnect];
    
    self.scanningActView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _scanningActView.center = _scanOrDisconnect.center;
    _scanningActView.hidesWhenStopped = YES;
    [self.view addSubview:_scanningActView];
    
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
        
        _scanOrDisconnect.hidden = NO;
        [_scanningActView stopAnimating];
        [_scanOrDisconnect setTitle:@"Disconnect" forState:UIControlStateNormal];
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
    
    TIKeyfob.shared.axisMovedBlock = ^{
        NSLog(@"(%f, %f, %f)",TIKeyfob.shared.x,TIKeyfob.shared.y,TIKeyfob.shared.z);
    };
}

- (void)sendNotifWithText:(NSString *)text {
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.repeatInterval = NSDayCalendarUnit;
    [notification setAlertBody:text];
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
    [UIApplication.sharedApplication setScheduledLocalNotifications:@[notification]];
}

- (void)scanForFob {
    if (TIKeyfob.shared.isPaired) {
        [[TIKeyfob shared]disconnect];
        [_scanOrDisconnect setTitle:@"Scan" forState:UIControlStateNormal];
    } else {
        [[TIKeyfob shared]scanForBLEPeripheralsWithTimeout:30.0f];
        _scanOrDisconnect.hidden = YES;
        [_scanningActView startAnimating];
    }
}

@end
