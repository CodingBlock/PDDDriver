//
//  PDDSerialCommunicationManager.m
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/3/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import "PDDSerialCommunicationManager.h"
#import "PDDDriverViewController.h"

#include <stdio.h>   /* Standard input/output definitions */
#include <string.h>  /* String function definitions */
#include <unistd.h>  /* UNIX standard function definitions */
#include <fcntl.h>   /* File control definitions */
#include <errno.h>   /* Error number definitions */
#include <termios.h> /* POSIX terminal control definitions */

@interface PDDSerialCommunicationManager ()

// declare functions that are private
- (const char *)composeValidCStringCommandToken:(NSString *)baseToken;
- (NSString *)composeValidCommandToken:(NSString *)baseToken;
- (void)initiateSerialCommuncation;
- (BOOL)internalSendSerialCommand:(NSString *)command;

@end

@implementation PDDSerialCommunicationManager
@synthesize delegate;
@synthesize connectionAvailable;
@synthesize commandInProgress;

#pragma mark -
#pragma mark NSObject
- (void)dealloc
{	
	delegate = nil;
	[super dealloc];
}

- (id)initWithDelegate:(id)sender
{
	if( (self = [super init]) )
	{
		// set ivars
		commandInProgress = NO;
		connectionAvailable = NO;
		
		// set delegate
		self.delegate = sender;
		
		// set up a serial connection in a seperate thread and hope for the best..
		[self performSelectorInBackground:@selector(initiateSerialCommuncation) withObject:nil];
	}
	
	return self;
}

#pragma mark -
#pragma mark C functions for serial communication setup
static struct termios gOriginalTTYAttrs;

int OpenSerialPort()
{
    int fileDescriptor = -1;
    struct termios  options;
	
    // Open the serial port read/write, with no controlling terminal, and don't wait for a connection.
    // The O_NONBLOCK flag also causes subsequent I/O on the device to be non-blocking.
    // See open(2) ("man 2 open") for details.
	
    fileDescriptor = open("/dev/tty.iap", O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fileDescriptor == -1)
    {
        printf("Error opening serial port %s - %s(%d).\n",
               "/dev/tty.iap", strerror(errno), errno);
        goto error;
    }
	
    // Note that open() follows POSIX semantics: multiple open() calls to the same file will succeed
    // unless the TIOCEXCL ioctl is issued. This will prevent additional opens except by root-owned
    // processes.
    // See tty(4) ("man 4 tty") and ioctl(2) ("man 2 ioctl") for details.
	
    if (ioctl(fileDescriptor, TIOCEXCL) == -1)
    {
        printf("Error setting TIOCEXCL on %s - %s(%d).\n",
			   "/dev/tty.iap", strerror(errno), errno);
        goto error;
    }
	
    // Now that the device is open, clear the O_NONBLOCK flag so subsequent I/O will block.
    // See fcntl(2) ("man 2 fcntl") for details.
	
    if (fcntl(fileDescriptor, F_SETFL, 0) == -1)
    {
        printf("Error clearing O_NONBLOCK %s - %s(%d).\n",
			   "/dev/tty.iap", strerror(errno), errno);
        goto error;
    }
	
    // Get the current options and save them so we can restore the default settings later.
    if (tcgetattr(fileDescriptor, &gOriginalTTYAttrs) == -1)
    {
        printf("Error getting tty attributes %s - %s(%d).\n",
			   "/dev/tty.iap", strerror(errno), errno);
        goto error;
    }
	
    // The serial port attributes such as timeouts and baud rate are set by modifying the termios
    // structure and then calling tcsetattr() to cause the changes to take effect. Note that the
    // changes will not become effective without the tcsetattr() call.
    // See tcsetattr(4) ("man 4 tcsetattr") for details.
	
    options = gOriginalTTYAttrs;
	
    // Print the current input and output baud rates.
    // See tcsetattr(4) ("man 4 tcsetattr") for details.
	
    printf("Current input baud rate is %d\n", (int) cfgetispeed(&options));
    printf("Current output baud rate is %d\n", (int) cfgetospeed(&options));
	
    // Set raw input (non-canonical) mode, with reads blocking until either a single character
    // has been received or a one second timeout expires.
    // See tcsetattr(4) ("man 4 tcsetattr") and termios(4) ("man 4 termios") for details.
	
    cfmakeraw(&options);
    options.c_cc[VMIN] = 1;
    options.c_cc[VTIME] = 10;
	
    // The baud rate, word length, and handshake options can be set as follows:
	
    cfsetspeed(&options, B9600);    // Set 19200 baud
    options.c_cflag |= (CS8);  // RTS flow control of input
	
	
    printf("Input baud rate changed to %d\n", (int) cfgetispeed(&options));
    printf("Output baud rate changed to %d\n", (int) cfgetospeed(&options));
	
    // Cause the new options to take effect immediately.
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1)
    {
        printf("Error setting tty attributes %s - %s(%d).\n",
			   "/dev/tty.iap", strerror(errno), errno);
        goto error;
    }
    // Success
    return fileDescriptor;
	
    // Failure "/dev/tty.iap"
error:
    if (fileDescriptor != -1)
    {
        close(fileDescriptor);
    }
	
    return -1;
}

#pragma mark -
#pragma mark Serial Communication Methods
// this function will 'initiate' a serial connection (poll the serial receiver with a [SYN] token and wait for a [ACK] token)
- (void)initiateSerialCommuncation
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	if( [self internalSendSerialCommand:_PDDSerialCommunicationTokenSYN_] )
	{
		connectionAvailable = YES;
				
		// a connection has been established; send a notification to the delegate
		if( [delegate respondsToSelector:@selector(serialConnectionEstablished)] )
			[delegate performSelectorOnMainThread:@selector(serialConnectionEstablished) withObject:nil waitUntilDone:NO];
        
        // let observers know of this event
        [[NSNotificationCenter defaultCenter] postNotificationName:_PDDSerialConnectionEstablishedNotification_ object:nil];
	}else{
		connectionAvailable = NO;
		
		// a connection has not been made, try again
		[self initiateSerialCommuncation];
		[pool drain];
		return;
	}
	
	[pool release];
}

// async wrapper for internalSendSerialCommand
- (void)sendSerialCommand:(NSString *)command
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL commandSend = YES;
	
	// do some checks
	if( !connectionAvailable || commandInProgress || command == nil )
		commandSend = NO;
	
	// set 'commandInProgress' flag to avoid multiple commands without an [ACK] token received
	commandInProgress = YES;
	   
	// actually send the command and return the result to the delegate
	if( ![self internalSendSerialCommand:command] )
	{
		commandSend = NO;
	}
	
	commandInProgress = NO;
	
	SEL delegateSelector = nil;
	if( !commandSend )
	{
		delegateSelector = @selector(serialCommandFailed:);
	}else{
		delegateSelector = @selector(serialCommandSuccess:);
	}
	
	if( [delegate respondsToSelector:delegateSelector] )
		[delegate performSelectorOnMainThread:delegateSelector withObject:command waitUntilDone:NO];
	
	[pool drain];
}

// this function will send a serial command, and waits for [ACK] to confirm
- (BOOL)internalSendSerialCommand:(NSString *)command
{
    if( PDDDebugMode )
    {
        // if debug mode is enabled, skip all the other stuff that will not work without a serial connection anyway
        return YES;
    }
    
	BOOL commandReceived = NO;
	int fd;
    char inputbuffer[8];
	NSMutableString *rxString = [NSMutableString string];
	
    fd = OpenSerialPort(); // Open tty.iap with no hardware control, 8 bit and at 9600 baud
    if(fd>-1)
    {
		// our file is open, send the command
		const char *synToken = [self composeValidCStringCommandToken:command];
		
		// write token over serial (mind the strlen + 1 ... )
		write(fd, synToken, strlen(synToken)+1);
		
        // now read for a response
        read(fd, &inputbuffer[0], 1); // read 1 byte  over serial.  This will block (wait) untill the byte has been received
        if(inputbuffer[0]=='[')		// check if this byte is a "start" byte
        {
			// add the start byte to our rx command string
			[rxString appendFormat:@"%c", inputbuffer[0]];
			
			// we have a start byte, lets build up a string
			BOOL endByteReceived = NO;
			while( !endByteReceived )
			{
				read(fd, &inputbuffer[0], 1);  // read the next char over serial
				
				// store the received char
				[rxString appendFormat:@"%c", inputbuffer[0]];
				
				// do this until we hit the "end" byte
				if( inputbuffer[0] == ']' )
					endByteReceived = YES;
			}
			
			// now analyze our response (should be ACK)
			if( [rxString isEqualToString:[self composeValidCommandToken:_PDDSerialCommunicationTokenACK_]] )
				commandReceived = YES;
        }
		
		// close filedescriptor
		close(fd);
    }
	
	return commandReceived;
}

#pragma mark -
#pragma mark Serial Communication Helper Methods
- (NSString *)composeValidCommandToken:(NSString *)baseToken
{
	return [NSString stringWithFormat:@"[%@]", baseToken];
}

- (const char *)composeValidCStringCommandToken:(NSString *)baseToken
{
	return [[self composeValidCommandToken:baseToken] cStringUsingEncoding:NSASCIIStringEncoding];
}

@end
