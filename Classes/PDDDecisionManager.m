//
//  PDDDecisionManager.m
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/22/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import "PDDDecisionManager.h"

@interface PDDDecisionManager()
- (void)setDecision:(Decision)decision;

//
- (void)makeRandomDecision;
- (void)makeRemoteDecision;
@end

@implementation PDDDecisionManager
@synthesize _internalDecision;
@synthesize _previousDecision;

//
@synthesize testCounter;
@synthesize remoteDecisionArray;

static PDDDecisionManager *defaultManager;

#pragma mark -
#pragma mark NSObject
+ (PDDDecisionManager *)defaultManager
{
    if (!defaultManager)
        defaultManager = [[PDDDecisionManager alloc] init];
		
    return defaultManager;
}

+ (id)alloc
{
    NSAssert(defaultManager == nil, @"Attempted to allocate a second instance of a singleton.");
    defaultManager = [super alloc];
    return defaultManager;
}

+ (id)copy
{
    NSAssert(defaultManager == nil, @"Attempted to copy the singleton.");
    return defaultManager;
}

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized) {		
        initialized = YES;
    }
}

- (id)init
{
	if( (self = [super init]) )
	{		
		_internalDecision = PDDDecisionMake(0.053, ArduinoAccelerationModeNone, ArduinoMotorDirectionFoward, ArduinoSteeringModeNone);
        _previousDecision = _internalDecision;
        
        testCounter = 0;
	}
	
	return self;
}

#pragma mark -
#pragma mark Decision getter/setter
- (void)setDecision:(Decision)decision
{
    // save the current internal decision as the old one
    _previousDecision = _internalDecision;
    
    // save the internal decision
    _internalDecision = decision;
}

- (Decision)decision
{
    // decide which decision mode we are in (determines what should be returned)
    switch (_PDDDecisionMode_) 
    {
        case PDDDecisionModeRandom:
            [self makeRandomDecision];
            break;
            
        case PDDDecisionModeRemote:
            [self makeRemoteDecision];
            break;
            
        // default: just return the decision that has already been set (because camera always pushes data to the manager and pre-sets a decision
        default:
            break;
    }
    
    return _internalDecision;
}

- (Decision)previousDecision
{
    return _previousDecision;
}

#pragma mark -
#pragma mark Test
- (void)makeRandomDecision
{
    // test code below: this function should only return the internal decision struct    
    float acceleration = _internalDecision.acceleration;
    ArduinoAccelerationMode accelerationMode = _internalDecision.accelerationMode;
    
    if( testCounter == 150 )
    {
        testCounter = 0;
        
        // Because I'm an idiot, and didn't bother to find out how to get random numbers between 0.053 and 0.2
        // I use a percentage system. Who uses random data anyway (unless it is for test purposes)?
        double val = floorf(((double)arc4random() / 0x100000000) * 100); // get value between 0 and 100
        acceleration = (0.053 + (0.00147 * val));
        
        // randomly let it switch acceleration / deceleration
        double val2 = floorf(((double)arc4random() / 0x100000000) * 4);
        accelerationMode = (ArduinoAccelerationMode)val2;
    }
    
    testCounter++;
    
    Decision newDecision = PDDDecisionClone(_internalDecision);
    newDecision.acceleration = acceleration;
    newDecision.accelerationMode = accelerationMode;
    
    [self setDecision:newDecision];
}

- (void)makeRemoteDecision
{
    // if remote decision is empty, get one from our remote location (array with pre-set decision dictionaries)
    if( remoteDecisionArray == nil )
    {
        NSString *requestString = [NSString stringWithFormat:@"%@%@", _PDDRemoteURLBase_, @"iphone-bin/decision-preset.plist"];
        self.remoteDecisionArray = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:requestString]];
    }
    
    for( NSDictionary *remoteDecision in remoteDecisionArray )
    {
        if( [[remoteDecision objectForKey:@"tick"] intValue] == testCounter )
        {
            // set this decision
            Decision newDecision = PDDDecisionClone(_internalDecision);
            newDecision.acceleration        = [[remoteDecision objectForKey:@"acceleration"] floatValue];
            newDecision.accelerationMode    = [[remoteDecision objectForKey:@"accelerationMode"] intValue];
            newDecision.motorDirection      = [[remoteDecision objectForKey:@"motorDirection"] intValue];
            newDecision.steeringMode        = [[remoteDecision objectForKey:@"steeringMode"] intValue];
            newDecision.decisionPriority    = [[remoteDecision objectForKey:@"decisionPriority"] intValue];
            
            [self setDecision:newDecision];
        }
    }
    
    testCounter++;
}

@end
