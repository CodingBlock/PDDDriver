//
//  PDDLogViewController.m
//  PDDDriver
//
//  Created by Jan Willem de Birk on 4/1/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import "PDDLogViewController.h"
#import "PDDArduinoController.h"

@implementation PDDLogViewController
@synthesize arduinoController;
@synthesize activityIndicator;
@synthesize logTextView;
@synthesize logButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [logTextView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set up log text view
    [logTextView setText:@"Initializing..."];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextView:) name:_PDDDebugMessageNotification_ object:nil];
	
	// init arduino controller
	arduinoController = [[PDDArduinoController alloc] init];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self setLogTextView:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
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
