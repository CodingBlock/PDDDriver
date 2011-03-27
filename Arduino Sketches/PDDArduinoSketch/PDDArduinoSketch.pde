#include <AFMotor.h>

char  rxBuffer[25];
int   rxCounter;

// create motor #2, 8KHz pwm
AF_DCMotor motor(2, MOTOR12_64KHZ);

// create motor #1, 8KHz pwm
AF_DCMotor motor2(1, MOTOR12_8KHZ);

void setup()
{
  // set up serial
  Serial.begin(9600);

  // set up rx buffer
  rxCounter = 0;
  rxBuffer[0] = '\0';
  
  // set up light (for debugging)
  pinMode(13, OUTPUT); 
  
  // set up motors
  motor.run(FORWARD);
  motor.setSpeed(0);
  motor2.setSpeed(0);
}

void loop()
{
  boolean tokenReceived = false;
  if( Serial.available() > 0 )
  {
    // start reading from the serial buffer
    char readByte = Serial.read();
    if( readByte == '[' ) // we have an opening byte
    {
      // put on the light
      digitalWrite(13, HIGH);
      
      // reset counter
      rxCounter = 0;
      // clean the buffer
      rxBuffer[0] = '\0';
      // add byte to the array
      rxBuffer[rxCounter] = readByte;
    }
    else if( readByte == ']' ) // we have a closing byte
    {
      if( rxCounter > 2 )
      {
        // turn off the light
        digitalWrite(13, LOW);
        
        // add byte to the array
        rxBuffer[rxCounter] = readByte;
        // close the char array
        rxBuffer[rxCounter+1] = '\0';
        // mark the token as received
        tokenReceived = true;
      }
    }else{
      if( rxCounter > 0 && rxBuffer[0] == '[' )
      {
        // we have a normal character, add it to the array
        rxBuffer[rxCounter] = readByte;
      }
    }
    
    rxCounter++;
  }
  
  // we have recieved a token, do stuff with it
  if( tokenReceived )
  {
      // transform the token into a command string
      String tokenString = String(rxBuffer);
      String commandString = tokenString.substring(1, (tokenString.length()-1));
      
      // interpret the command
      if( commandString.substring(0,1) == "V" )
      {
         // speed command
         String speedString = commandString.substring(1);
         char speedCharArray[4];
         speedString.toCharArray(speedCharArray, 4);
         int motorSpeed = atoi(speedCharArray);
         
         if( motorSpeed >= 0 && motorSpeed <= 255 )
         {
            motor.setSpeed(motorSpeed);
         }
      }
      else if( commandString == "DMF" )
      {
        // set motor direction forward (which is also the default)
        motor.run(FORWARD);
      }
      else if( commandString == "DMB" )
      {
         // set motor direction backward 
         motor.run(BACKWARD);
      }
      else if( commandString == "SMN" )
      {
         // set motor 2 OFF
         motor2.setSpeed(0);
      }
      else if( commandString == "SML" )
      {
         // set motor 2 to steer left
         motor2.setSpeed(255);
         motor2.run(FORWARD);
      }
      else if( commandString == "SMR" )
      {
         // set motor 2 to steer right
         motor2.setSpeed(255);
         motor2.run(BACKWARD);
      }
      
      // at the end, send an ACK to confirm the message
      Serial.println("[ACK]");
      // flush serial cache (we don't like cache, we want real time updates!)
      Serial.flush();
  }
}
