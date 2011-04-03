//
//  PDDDecisionManager.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/22/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDDDataStructures.h"

typedef enum {
	PDDDecisionModeRandom = 0,
	PDDDecisionModeCamera,
    PDDDecisionModeRemote,
} PDDDecisionMode;

#define _PDDDecisionMode_   PDDDecisionModeCamera

@interface PDDDecisionManager : NSObject {
    Decision _internalDecision;
    Decision _previousDecision;
    
    //
    int testCounter;
    NSArray *remoteDecisionArray;
}

@property Decision _internalDecision;
@property Decision _previousDecision;

//
@property int testCounter;
@property (nonatomic, retain) NSArray *remoteDecisionArray;

+ (PDDDecisionManager *)defaultManager;
+ (id)alloc;
+ (id)copy;
+ (void)initialize;
- (id)init;

- (Decision)decision;
- (Decision)previousDecision;

@end
