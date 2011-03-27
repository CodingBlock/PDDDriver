//
//  PDDArduinoController.m
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/14/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import "PDDArduinoController.h"
#import "ASIFormDataRequest.h"
#import "PDDDecisionManager.h"
#include <unistd.h>

@implementation PDDArduinoController
@synthesize arduinoState;
@synthesize queuedMotorDirection;
@synthesize queuedSteeringMode;
@synthesize serialCommandInProgress;
@synthesize serialCommunicationManager;
@synthesize serialSendLog, serialACKLog;
@synthesize softwareInterrupt;

#pragma mark -
#pragma mark NSObject
- (void)dealloc
{
	[super dealloc];
}

- (id)initWithSerialCommunicationManager:(PDDSerialCommunicationManager *)manager
{
	if( (self = [super init]) )
	{
        // set up logs
        //if( PDDDebugMode )
        {
            serialACKLog    = [[NSMutableArray alloc] init];
            serialSendLog   = [[NSMutableArray alloc] init];
        }
		// set serial communication manager
		// TODO: maybe move the init of the serial comm manager to here?
		serialCommunicationManager = manager;
		
		// set defaults
        softwareInterrupt = NO;
		serialCommandInProgress = NO;
		queuedSteeringMode = NSIntegerMin;
		queuedMotorDirection = NSIntegerMin;
		
		// set a default arduino state (bare minimum)
		arduinoState = PDDArduinoStateMake(0, 0, _PDDDefaultMotorOffset_, 0, ArduinoMotorDirectionFoward, ArduinoSteeringModeNone);
		
		// spawn an 'arduinoLoop' in a new thread
		[NSThread detachNewThreadSelector:@selector(arduinoLoop) toTarget:self withObject:nil];
	}
	
	return self;
}

#pragma mark -
#pragma mark Arduino Loop
- (void)applyQueuedStates
{
    if( queuedSteeringMode != NSIntegerMin )
    {
        arduinoState.steeringMode = queuedSteeringMode;
        queuedSteeringMode = NSIntegerMin;
    }
    
    if( queuedMotorDirection != NSIntegerMin )
    {
        arduinoState.motorDirection = queuedMotorDirection;
        queuedMotorDirection = NSIntegerMin;
    }
}

- (ArduinoState)swapArduinoStateMotorOffset:(ArduinoState)ardState withMotorSpeed:(int)motorSpeed
{
    ardState.motorOffset = motorSpeed;
    ardState.motorX = 0;
    
    return ardState;
}

- (float)calculateArduinoSpeedBasedOnDecision:(Decision)decision arduinoState:(ArduinoState)ardState
{
    // accelerate function: ((x*a)^2)+o
    // decelerate function: -((x*a)^2)+o
    // x = an int (counter)
    // a = acceleration (probably a float between 0.053f and 0.2f, not sure yet)
    // o = offset
    
    float speed = 0.0f;
    
    // decide if we need to accelerate or decelerate
    if( decision.accelerationMode == ArduinoAccelerationModeAccelerate )
    {
       
        speed = powf((ardState.motorX * ardState.motorAcceleration), 2.0) + ardState.motorOffset;
    }else if ( decision.accelerationMode == ArduinoAccelerationModeDecelerate )
    {
        // TODO: perhaps change this function to a sqrt implementation (faster response time, which may be vital here)
        speed = -(powf((ardState.motorX * ardState.motorAcceleration), 2.0)) + ardState.motorOffset;
    }
    
    return speed;
}

- (void)arduinoLoop
{
	// this is a simulation for the 'void loop()' function on the Arduino
	// I have replaced that loop with this code because the iPhone 4 is better, faster, strong.
	// this 'run loop' will push changes to the Arduino over serial and is used
	// to do some 'complex' calculations in terms of speed, acceleration and steering.
	// system decisions are made in another class and retreived (in struct form) here.
	
	while( !softwareInterrupt )
	{
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
		// make sure the 'queued' states are applied first (so we don't send them again)
		[self applyQueuedStates];
		
		// get system decision (acceleration, steering and others)
		// system decision would be determined in 'another thread' and might require a lock to set/get
        // TODO: respect the enum to determine which has priority: speed, steering of direction
		Decision decision = [[PDDDecisionManager defaultManager] decision];
        Decision previousDecision = [[PDDDecisionManager defaultManager] previousDecision];		
        
        // if we need a forcedAcceleration mode (forced by decisions in this class), save it to this var
        ArduinoAccelerationMode forcedAccelerationMode = decision.accelerationMode;
        
        // load in old (saved) Arduino state
        ArduinoState oldArduinoState = arduinoState;
		
        // clone the old state into a new state
		ArduinoState newArduinoState = PDDArduinoStateClone(oldArduinoState);
        
        // TODO: create a function to create an arduino state (or expand) based on the decision
        // now we have a clone, change 'newArduinoState' vars depending on the decision struct, use the 'oldArduinoState' to influence that
        newArduinoState.motorAcceleration = decision.acceleration;
        
        // do some swapping to support the previous decision
        if( decision.accelerationMode != previousDecision.accelerationMode )
        {
            if( decision.accelerationMode == ArduinoAccelerationModeAccelerate && previousDecision.accelerationMode == ArduinoAccelerationModeDecelerate )
            {
                // going from decelerate to accelerate; 
                // set speed as offset, and reset motorX
                if( oldArduinoState.motorSpeed < newArduinoState.motorOffset )
                {
                    newArduinoState = [self swapArduinoStateMotorOffset:newArduinoState withMotorSpeed:oldArduinoState.motorSpeed];
                }
            }
            
            if( decision.accelerationMode == ArduinoAccelerationModeDecelerate && previousDecision.accelerationMode == ArduinoAccelerationModeAccelerate )
            {
                // going from accelerate to decelerate; 
                // set speed as offset, and reset motorX
                if( oldArduinoState.motorSpeed > newArduinoState.motorOffset )
                {
                    newArduinoState = [self swapArduinoStateMotorOffset:newArduinoState withMotorSpeed:oldArduinoState.motorSpeed];  
                }
            }
        }
        
        // if we keep a steady acceleration mode, do not calculate anything
        // else; calculate new speed
        if( decision.accelerationMode != ArduinoAccelerationModeSteady && decision.accelerationMode != ArduinoAccelerationModeNone )
        {
            // swap some states if the acceleration changes (but not if we came from steady or none, because we already swapped!)
            if( oldArduinoState.motorAcceleration != newArduinoState.motorAcceleration && (previousDecision.accelerationMode != ArduinoAccelerationModeNone && previousDecision.accelerationMode != ArduinoAccelerationModeSteady) )
            {
                // set the current offset of the new arduino state to be the motorspeed of the old arduino state
                // in order to keep momentum
                if( decision.accelerationMode == ArduinoAccelerationModeAccelerate && oldArduinoState.motorSpeed > newArduinoState.motorOffset )
                {
                    newArduinoState = [self swapArduinoStateMotorOffset:newArduinoState withMotorSpeed:oldArduinoState.motorSpeed];
                }
                
                if( decision.accelerationMode == ArduinoAccelerationModeDecelerate && oldArduinoState.motorSpeed < newArduinoState.motorOffset )
                {
                    newArduinoState = [self swapArduinoStateMotorOffset:newArduinoState withMotorSpeed:oldArduinoState.motorSpeed];
                }
            }
            // ignore other settings for now since we have no priority queue
            
            
            // calculate the new arduino speed based on the decision struct
            float speed = [self calculateArduinoSpeedBasedOnDecision:decision arduinoState:newArduinoState];
            newArduinoState.motorSpeed = speed;
            
            /**
             * correct motor speed if out of bounds
             * also correct motorOffset, motorX etc,
             **/
            if( newArduinoState.motorSpeed > 255 )
            {
                // force the arduino to keep it steady
                forcedAccelerationMode = ArduinoAccelerationModeSteady;
                
                // set some forced stuff
                newArduinoState.motorSpeed = 255;
                newArduinoState = [self swapArduinoStateMotorOffset:newArduinoState withMotorSpeed:newArduinoState.motorSpeed];
            }
            
            // if arduino speed drops below default offset, keep the speed steady
            if( newArduinoState.motorSpeed < _PDDDefaultMotorOffset_ && decision.accelerationMode != ArduinoAccelerationModeNone )
            {
                // force the arduino to keep it steady
                forcedAccelerationMode = ArduinoAccelerationModeSteady;
                
                // set some forced stuff
                newArduinoState.motorSpeed = _PDDDefaultMotorOffset_;
                newArduinoState = [self swapArduinoStateMotorOffset:newArduinoState withMotorSpeed:newArduinoState.motorSpeed];
            }
        }
        
        // if we keep an acceleration mode 'none', set speed to 0 to stop all
        if( decision.accelerationMode == ArduinoAccelerationModeNone )
        {
            newArduinoState.motorSpeed = 0;
            newArduinoState.motorOffset = _PDDDefaultMotorOffset_;
        }
        
		/**
         * Steering
         * determine the new steering mode and compose a serial command
         **/
        NSString *serialCommand = nil;
		if( oldArduinoState.steeringMode != newArduinoState.steeringMode  && !serialCommandInProgress )
		{
			NSLog(@"*** sending steering mode over serial: %d", newArduinoState.steeringMode);
            
            switch (newArduinoState.steeringMode) {
                case ArduinoSteeringModeNone:
                    serialCommand = _PDDSerialCommunicationTokenSetSteeringNone_;
                    break;
                    
                case ArduinoSteeringModeLeft:
                    serialCommand = _PDDSerialCommunicationTokenSetSteeringLeft_;
                    break;
                    
                case ArduinoSteeringModeRight:
                    serialCommand = _PDDSerialCommunicationTokenSetSteeringRight_;
                    break;
                    
                default:
                    break;
            }
		}
		
		/**
         * Direction
         * determine the new direction mode and compose a serial command
         **/
		if( oldArduinoState.motorDirection != newArduinoState.motorDirection && !serialCommandInProgress )
		{
			NSLog(@"*** sending motor direction over serial: %d", newArduinoState.motorDirection);
            
            switch (newArduinoState.motorDirection) {
                case ArduinoMotorDirectionFoward:
                    serialCommand = _PDDSerialCommunicationTokenSetDirectionForward_;
                    break;
                    
                case ArduinoMotorDirectionBackward:
                    serialCommand = _PDDSerialCommunicationTokenSetDirectionBackward_;
                    break;
                    
                default:
                    break;
            }
		}
        
        /**
         * Speed
         * determine the new speed mode and compose a serial command
         **/
        if( (int)oldArduinoState.motorSpeed != (int)newArduinoState.motorSpeed && !serialCommandInProgress )
        {
            NSLog(@"*** sending motor speed over serial: %d", (int)newArduinoState.motorSpeed);
            serialCommand = [NSString stringWithFormat:@"%@%d", _PDDSerialCommunicationTokenSetSpeed_, (int)newArduinoState.motorSpeed];
        }else if( serialCommandInProgress )
        {
            // send debug info
            [[NSNotificationCenter defaultCenter] postNotificationName:_PDDDebugMessageNotification_ object:[NSString stringWithFormat:@"Serial Command Not Send (%@)", [NSString stringWithFormat:@"%@%d", _PDDSerialCommunicationTokenSetSpeed_, (int)newArduinoState.motorSpeed]]];

        }
        
        /**
         * Serial transmission
         * actually send the serial command
         **/
        if( serialCommand != nil )
        {
            NSLog(@"*** sending composed command over serial: %@", serialCommand);
            serialCommandInProgress = YES;
            [serialCommunicationManager sendSerialCommand:serialCommand];
            
            // log the serial command
            //if( PDDDebugMode )
            {
                @synchronized(serialSendLog)
                {
                    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                    NSNumber *timeStampObj = [NSNumber numberWithDouble:timeStamp];
                
                    [serialSendLog addObject:serialCommand];
                    [serialSendLog addObject:timeStampObj];
                }
            }
        }
		
        // increase x (which basically is a representation of time or ticks (if not acceleration mode none)
        if( decision.accelerationMode != ArduinoAccelerationModeNone && decision.accelerationMode != ArduinoAccelerationModeSteady && forcedAccelerationMode != ArduinoAccelerationModeSteady )
        {
            newArduinoState.motorX += 1;
        }else{
            newArduinoState.motorX = 0;
        }
		
		// save the new arduino state
		arduinoState = newArduinoState;
		
		// sleep (if needed? timestamp?)
		[NSThread sleepForTimeInterval:0.04];
        
        [pool drain];
	}
    
    // call this loop again (after some delay), to resume if software interrupt is revoked
    [self performSelector:@selector(arduinoLoop) withObject:nil afterDelay:0.1];
    return;
}

#pragma mark -
#pragma mark PDDSerialCommunicationManagerProtocol
- (void)serialCommandSuccess:(NSString *)command
{
    // log the serial command
    if( PDDDebugMode )
    {
        @synchronized(serialACKLog)
        {
            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
            NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
                
            [serialACKLog addObject:command];
            [serialACKLog addObject:timeStampObj];
        }
    }
    
	// catch the following states here (and set them, because the command succeeded):
	//	- Steering
	//	- Direction changes
	
	// save adruino state, but do not save from here (dangerous!)
	// queue the save, and merge it in the actual loop
	if( [command isEqualToString:_PDDSerialCommunicationTokenSetDirectionBackward_] )
	{
		queuedMotorDirection = ArduinoMotorDirectionBackward;
	}
	
	if( [command isEqualToString:_PDDSerialCommunicationTokenSetDirectionForward_] )
	{
		queuedMotorDirection = ArduinoMotorDirectionFoward;
	}
	
	if( [command isEqualToString:_PDDSerialCommunicationTokenSetSteeringLeft_] )
	{
		queuedSteeringMode = ArduinoSteeringModeLeft;
	}
	
	if( [command isEqualToString:_PDDSerialCommunicationTokenSetSteeringRight_] )
	{
		queuedSteeringMode = ArduinoSteeringModeRight;
	}
	
	if( [command isEqualToString:_PDDSerialCommunicationTokenSetSteeringNone_] )
	{
		queuedSteeringMode = ArduinoSteeringModeNone;
	}
	
	serialCommandInProgress = NO;
}

- (void)serialCommandFailed:(NSString *)command
{
	// do not save anything, just set the serial pending state to NO
	serialCommandInProgress = NO;
}

#pragma -
#pragma Remote Logging
- (void)saveLogs
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    // perform a software interupt to pause the current arduino loop (not realtime)
    softwareInterrupt = YES;
    
    // lock log, and send it
    @synchronized(serialSendLog)
    {
        // write logs to URL and clear
        NSString *serialSendLogString = [serialSendLog componentsJoinedByString:@","];
        
        NSString *requestString = [NSString stringWithFormat:@"%@%@", _PDDRemoteURLBase_, @"iphone-bin/data.php"];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
        
        [request addPostValue:serialSendLogString forKey:@"logdata"];
        [request addPostValue:@"./serialSendLog.txt" forKey:@"logfile"];
        
        [request startSynchronous];
        
        [serialSendLog removeAllObjects];
    }
    
    @synchronized(serialACKLog)
    {
        // TODO: write this one too
        [serialACKLog removeAllObjects];
    }
    
    // resume the arduino loop (trigger it)
    softwareInterrupt = NO;
    
    [pool drain];
}

@end
