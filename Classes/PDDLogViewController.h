//
//  PDDLogViewController.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 4/1/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDDSerialCommunicationManager.h"

@class PDDArduinoController;

@interface PDDLogViewController : UIViewController {
	PDDArduinoController *arduinoController;
	
	UIActivityIndicatorView *activityIndicator;
    UITextView *logTextView;
	
	UITextField *commandTextField;
	UIButton *logButton;
}

@property (nonatomic, retain) IBOutlet UIButton *logButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UITextView *logTextView;


@property (nonatomic, retain) PDDArduinoController *arduinoController;

- (IBAction)sendLog;

@end
