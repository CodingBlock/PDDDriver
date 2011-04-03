//
//  PDDDriverViewController.m
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/3/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import "PDDDriverViewController.h"
#import "PDDDataStructures.h"
#import "PDDDecisionManager.h"
#import "PDDLogViewController.h"

@implementation PDDDriverViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // register as an observer for special events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEstablishSerialConnectionWithNotification:) name:_PDDSerialConnectionEstablishedNotification_ object:nil];
    
    // setup PDDLogViewController
    PDDLogViewController *logViewController = [[PDDLogViewController alloc] initWithNibName:@"PDDLogViewController" bundle:nil];
    
    // setup navigation UI
    [self pushViewController:logViewController animated:NO];
    
    [logViewController release], logViewController = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Events
- (void)didEstablishSerialConnectionWithNotification:(NSNotification *)notification
{
    // TODO: init camera and push camera module to start making decisions
    NSLog(@"*** init camera module");
    
    
    // TODO: remove this
    // as a little test, push a decision
    sleep(2);
    
    Decision decision = PDDDecisionMake(0.2, ArduinoAccelerationModeAccelerate, ArduinoMotorDirectionFoward, ArduinoSteeringModeNone);
    [[PDDDecisionManager defaultManager] setDecision:decision];
}

@end
