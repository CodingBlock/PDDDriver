//
//  PDDDriverViewController.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/3/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDDSerialCommunicationManager.h"

@class PDDArduinoController;

@interface PDDDriverViewController : UIViewController {
	PDDSerialCommunicationManager *serialCommunicationManager;
	PDDArduinoController *arduinoController;
	
	UIActivityIndicatorView *activityIndicator;
    UITextView *logTextView;
	
	UITextField *commandTextField;
	UIButton *logButton;
}

@property (nonatomic, retain) IBOutlet UIButton *logButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UITextView *logTextView;

@property (nonatomic, retain) PDDSerialCommunicationManager *serialCommunicationManager;
@property (nonatomic, retain) PDDArduinoController *arduinoController;

- (IBAction)sendLog;

@end

