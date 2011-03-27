//
//  PDDSerialCommunicationManager.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/3/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <Foundation/Foundation.h>

// communication tokens
#define _PDDSerialCommunicationTokenACK_			@"ACK"
#define _PDDSerialCommunicationTokenSYN_			@"SYN"

// partial (parameterized) tokens
#define	_PDDSerialCommunicationTokenSetSpeed_		@"V"

// direction modes (forward / backward)
#define	_PDDSerialCommunicationTokenSetDirectionForward_	@"DMF"
#define	_PDDSerialCommunicationTokenSetDirectionBackward_	@"DMB"

// steering modes (left / right / none)
#define	_PDDSerialCommunicationTokenSetSteeringNone_		@"SMN"
#define	_PDDSerialCommunicationTokenSetSteeringLeft_		@"SML"
#define	_PDDSerialCommunicationTokenSetSteeringRight_		@"SMR"

@protocol PDDSerialCommunicationManagerProtocol

// @note: all delegate functions are called on the main thread.
@optional
- (void)serialConnectionEstablished;
- (void)serialCommandFailed:(NSString *)command;
- (void)serialCommandSuccess:(NSString *)command;

@end


@interface PDDSerialCommunicationManager : NSObject {
	id delegate;
	BOOL connectionAvailable;
	BOOL commandInProgress;
}

@property (nonatomic, assign) id delegate;
@property BOOL connectionAvailable;
@property BOOL commandInProgress;

// init
- (id)initWithDelegate:(id)sender;

// send a serial command (this blocks the thread)
- (void)sendSerialCommand:(NSString *)command;

@end
