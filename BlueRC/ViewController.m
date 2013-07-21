//
//  ViewController.m
//  BlueRC
//
//  Created by user on 7/20/13.
//  Copyright (c) 2013 Scott Cheezem. All rights reserved.
//

#import "ViewController.h"

//the values reference the index of buf, UPLED referes to the index of the value to set for the led
#define UPLED 7
#define RIGHTLED 3
#define DOWNLED 1
#define LEFTLED 5


@interface ViewController ()

@end



@implementation ViewController{
    
}

@synthesize ble;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    //self.analogueStick = [[JSAnalogueStick alloc]initWithFrame:self.analogueStick.frame];
    self.analogStick.delegate = self;
    
    ble = [[BLE alloc]init];
    [ble controlSetup:1];
    ble.delegate = self;
    
    [self.connectButton addTarget:self action:@selector(scanForPeripherals:) forControlEvents:UIControlEventTouchUpInside];
    
    [self updateAnalogueLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)updateAnalogueLabel
{
	[self.analogTextLabel setText:[NSString stringWithFormat:@"Analogue: %.1f , %.1f", self.analogStick.xValue, self.analogStick.yValue]];
}

-(void)processAnalogControls{
    
    if([ble isConnected]){

        
        //an array of pin addresses and values
        UInt8 buf[9] = {0x03, 0x00, 0x05, 0x00, 0x06, 0x00, 0x0A, 0x00, 0x00};
        //UInt8 buf[5] = {0x03, 0x00, 0x05, 0x00, 0x00};
        //UInt8 buf[5] = {0x03, 0x00, 0x05, 0x00, 0x00};
        int scaledXval = abs(floorf((float)self.analogStick.xValue*255));
        
        int scaledYval = abs(floorf((float)self.analogStick.yValue*255));
        
        if(self.analogStick.xValue >= 0 && self.analogStick.yValue >= 0){
            //quad 1
            
            buf[UPLED] = scaledYval;
            buf[RIGHTLED] = scaledXval;
            buf[DOWNLED] = 0x00;
            buf[LEFTLED] = 0x00;

        }else if(self.analogStick.xValue <= 0 && self.analogStick.yValue >= 0){
            //quad 2
            buf[UPLED] = scaledYval;
            buf[RIGHTLED] = 0x00;
            buf[DOWNLED] = 0x00;
            buf[LEFTLED] = scaledXval;
            
            
        }else if(self.analogStick.xValue <= 0 && self.analogStick.yValue <= 0){
            //quad 3
            buf[UPLED] = 0x00;
            buf[RIGHTLED] = 0x00;
            buf[DOWNLED] = scaledYval;
            buf[LEFTLED] = scaledXval;
            
            
        }else if (self.analogStick.xValue >=0 && self.analogStick.yValue <= 0){
            //quad 4
            buf[UPLED] = 0x00;
            buf[RIGHTLED] = scaledXval;
            buf[DOWNLED] = scaledYval;
            buf[LEFTLED] = 0x00;
            
        }
        
        
        NSData *d = [[NSData alloc]initWithBytes:buf length:9];
        
        [ble write:d];
        
        
        
        /*UInt8 buf[3] =  {0x03, 0x00, 0x00};
         buf[1] = scaledYval;
         NSData *d = [[NSData alloc]initWithBytes:buf length:3];
         [ble write:d];*/

        //[self sendData];
    }
}

#pragma mark - JSAnalogueStickDelegate

- (void)analogueStickDidChangeValue:(JSAnalogueStick *)analogueStick
{
	[self updateAnalogueLabel];
    [self processAnalogControls];
    
}



#pragma mark - BLEDelegate
-(void)bleDidConnect{
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    [self.connectButton removeTarget:self action:@selector(scanForPeripherals:) forControlEvents:UIControlEventTouchUpInside];
    [self.connectButton addTarget:self action:@selector(disconnectFromPeripheral) forControlEvents:UIControlEventTouchUpInside];
    //self.connectButton.enabled = YES;
    [self.connectButton setEnabled:YES];
}

-(void)bleDidDisconnect{
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [self.connectButton removeTarget:self action:@selector(disconnectFromPeripheral) forControlEvents:UIControlEventTouchUpInside];
    [self.connectButton addTarget:self action:@selector(scanForPeripherals:) forControlEvents:UIControlEventTouchUpInside];
    self.rssiLabel.text = @"RSSI";
    //self.connectButton.enabled = YES;
    [self.connectButton setEnabled:YES];
}

-(void)bleDidReceiveData:(unsigned char *)data length:(int)length{
    
}

-(void)bleDidUpdateRSSI:(NSNumber *)rssi{
    self.rssiLabel.text = [NSString stringWithFormat:@"RSSI:%@",rssi];
}

#pragma mark - BLE Actions
-(void)scanForPeripherals:(id)sender{
    
    if(ble.peripherals){
        ble.peripherals = nil;
    }
    
    //self.connectButton.enabled = NO;
    [self.connectButton setEnabled:NO];
    [ble findBLEPeripherals:2];
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
}

-(void)disconnectFromPeripheral{
    //self.connectButton.enabled = NO;
    [self.connectButton setEnabled:NO];
     //this seems like its for disconnecting...
     if(ble.activePeripheral){
         if (ble.activePeripheral.isConnected) {
             [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
         
         }
     }
}

-(void)connectionTimer:(NSTimer*)timer{
    //self.connectButton.enabled = YES;
    
    if(ble.peripherals.count > 0){
        [ble connectPeripheral:[ble.peripherals objectAtIndex:0]];
    }else{
        self.connectButton.enabled = YES;
    }
    
}

@end
