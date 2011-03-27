//
//  PDDDriverViewController.m
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/3/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import "PDDDriverViewController.h"
#import "PDDArduinoController.h"

@implementation PDDDriverViewController
@synthesize serialCommunicationManager;
@synthesize arduinoController;
@synthesize activityIndicator;
@synthesize logTextView;
@synthesize logButton;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    // set up log text view
    [logTextView setText:@"Initializing..."];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextView:) name:_PDDDebugMessageNotification_ object:nil];
    
	// create a serial communication manager, assign as delegate and wait for a connection to be established
	serialCommunicationManager = [[PDDSerialCommunicationManager alloc] initWithDelegate:self];
	
	// nil arduino controller
	arduinoController = nil;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setLogTextView:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [logTextView release];
    [super dealloc];
}

#pragma mark -
#pragma mark PDDSerialCommunicationManagerProtocol
- (void)serialConnectionEstablished
{
    // send debug info
    [[NSNotificationCenter defaultCenter] postNotificationName:_PDDDebugMessageNotification_ object:@"Serial Connection Established"];
    
	// create an arduino controller to push changes to the Arduino (and do some calculations)
	if( arduinoController == nil )
        arduinoController = [[PDDArduinoController alloc] initWithSerialCommunicationManager:serialCommunicationManager];

	
	// TODO: init camera stuff and the logic behind it (decision base)
		
	// enable button for test purposes
	logButton.enabled = YES;
}

- (void)serialCommandFailed:(NSString *)command
{	
	// do nothing here? pass on to arduino controller?
    // send debug info
    [[NSNotificationCenter defaultCenter] postNotificationName:_PDDDebugMessageNotification_ object:@"Serial Command Failed"];
}

- (void)serialCommandSuccess:(NSString *)command
{
    // send debug info
    [[NSNotificationCenter defaultCenter] postNotificationName:_PDDDebugMessageNotification_ object:[NSString stringWithFormat:@"Serial Command Succes (%@)", command]];
    
	if( arduinoController != nil )
		[arduinoController serialCommandSuccess:command];
}

#pragma mark -
#pragma mark Text Code
- (IBAction)sendLog
{
    [activityIndicator startAnimating];

    // save current log
    [arduinoController saveLogs];
    
    [activityIndicator stopAnimating];
}

- (void)updateTextView:(NSNotification *)notification
{
    NSMutableString *logText = [[logTextView text] mutableCopy];
    [logText appendFormat:@"\n%@", [notification object]];
    [logTextView performSelectorOnMainThread:@selector(setText:) withObject:logText waitUntilDone:YES];
    [logText release];
}

@end
