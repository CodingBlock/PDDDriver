//
//  PDDDataStructures.h
//  PDDDriver
//
//  Created by Jan Willem de Birk on 3/22/11.
//  Copyright 2011 WoodWing Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Type Defs
 **/
typedef enum {
	DecisionPriorityDefault = 0,
	DecisionPrioritySteering,
    DecisionPriorityMotorDirection,
    DecisionPriorityMotorAcceleration = DecisionPriorityDefault
} DecisionPriority;

typedef enum {
	ArduinoMotorDirectionFoward = 0,
	ArduinoMotorDirectionBackward,
} ArduinoMotorDirection;

typedef enum {
	ArduinoSteeringModeNone = 0,
	ArduinoSteeringModeLeft,
	ArduinoSteeringModeRight
} ArduinoSteeringMode;

typedef enum {
	ArduinoAccelerationModeNone = 0,    // as in stop
    ArduinoAccelerationModeSteady,      // as in, keep going this speed
	ArduinoAccelerationModeAccelerate,
	ArduinoAccelerationModeDecelerate
} ArduinoAccelerationMode;

struct ArduinoState {
    float	motorAcceleration;
	float	motorSpeed;
	int		motorOffset;
	int		motorX;
	
	ArduinoMotorDirection	motorDirection;
	ArduinoSteeringMode		steeringMode;
};
typedef struct ArduinoState ArduinoState;

struct Decision {
    float acceleration;
    ArduinoAccelerationMode accelerationMode;
    
	ArduinoMotorDirection	motorDirection;
    ArduinoSteeringMode     steeringMode;
    
    DecisionPriority decisionPriority;
};
typedef struct Decision Decision;

/**
 * Function Declarations
 **/
CG_INLINE ArduinoState PDDArduinoStateMake(float motorAcceleration, float motorSpeed, int motorOffset, int motorX, ArduinoMotorDirection motorDirection, ArduinoSteeringMode steeringMode);

CG_INLINE ArduinoState PDDArduinoStateClone(ArduinoState oldArduinoState);

CG_INLINE Decision PDDDecisionMake(float acceleration, ArduinoAccelerationMode accelerationMode, ArduinoMotorDirection motorDirection, ArduinoSteeringMode steeringMode);

CG_INLINE Decision PDDDecisionClone(Decision oldDecision);

/**
 * Function Implementations
 **/
CG_INLINE ArduinoState
PDDArduinoStateMake(float motorAcceleration, float motorSpeed, int motorOffset, int motorX, ArduinoMotorDirection motorDirection, ArduinoSteeringMode steeringMode)
{
    ArduinoState arduinoState;
    
    arduinoState.motorAcceleration = motorAcceleration;
    arduinoState.motorSpeed = motorSpeed;
    arduinoState.motorOffset = motorOffset;
    arduinoState.motorX = motorX;
    arduinoState.motorDirection = motorDirection;
    arduinoState.steeringMode = steeringMode;
    
    return arduinoState;
}

CG_INLINE ArduinoState
PDDArduinoStateClone(ArduinoState oldArduinoState)
{
    ArduinoState arduinoState = PDDArduinoStateMake(oldArduinoState.motorAcceleration, oldArduinoState.motorSpeed, oldArduinoState.motorOffset, oldArduinoState.motorX, oldArduinoState.motorDirection, oldArduinoState.steeringMode);
    
    return arduinoState;
}

CG_INLINE Decision
PDDDecisionMake(float acceleration, ArduinoAccelerationMode accelerationMode, ArduinoMotorDirection motorDirection, ArduinoSteeringMode steeringMode)
{
    Decision decision;
    
    decision.acceleration = acceleration;
    decision.accelerationMode = accelerationMode;
    decision.motorDirection = motorDirection;
    decision.steeringMode = steeringMode;
    
    decision.decisionPriority = DecisionPriorityDefault; // set decision priority to acceleration mode

    return decision;
}

CG_INLINE Decision
PDDDecisionClone(Decision oldDecision)
{
    Decision decision;
    
    decision.acceleration = oldDecision.acceleration;
    decision.accelerationMode = oldDecision.accelerationMode;
    decision.motorDirection = oldDecision.motorDirection;
    decision.steeringMode = oldDecision.steeringMode;
    decision.decisionPriority = oldDecision.decisionPriority;
    
    return decision;
}