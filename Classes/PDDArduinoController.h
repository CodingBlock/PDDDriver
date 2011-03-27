//
//  PDDArduinoController.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/14/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDDSerialCommunicationManager.h"
#import "PDDDataStructures.h"

#define _PDDDefaultMotorOffset_	75

@interface PDDArduinoController : NSObject {
	// arduino state defines
	ArduinoState arduinoState;
	
	// serial comm. defines
	BOOL serialCommandInProgress;
	PDDSerialCommunicationManager *serialCommunicationManager;
	
	// queued changes for the arduino state
	ArduinoMotorDirection queuedMotorDirection;
	ArduinoSteeringMode queuedSteeringMode;
    
    // logging and debug purposes
    NSMutableArray *serialSendLog, *serialACKLog;
    BOOL softwareInterrupt;
}

@property struct ArduinoState arduinoState;
@property ArduinoMotorDirection queuedMotorDirection;
@property ArduinoSteeringMode queuedSteeringMode;

@property BOOL serialCommandInProgress;
@property (nonatomic, assign) PDDSerialCommunicationManager *serialCommunicationManager;
@property (nonatomic, retain) NSMutableArray *serialSendLog, *serialACKLog;
@property BOOL softwareInterrupt;

- (id)initWithSerialCommunicationManager:(PDDSerialCommunicationManager *)manager;
- (void)serialCommandSuccess:(NSString *)command;

- (void)saveLogs;

@end
