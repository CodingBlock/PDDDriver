//
//  PDDDriverAppDelegate.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/3/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PDDDriverViewController;

@interface PDDDriverAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    PDDDriverViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet PDDDriverViewController *viewController;

@end

