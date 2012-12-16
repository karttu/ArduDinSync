
/* Dial successive digits with an Old Ericsson Telephone rotary dial,
   and display them on 8-digit (later 16-digit) MAX7219 controlled 7-SEG LED display.
   
   This version sends synchronization pulse with the frequency
   1000/dialedValue Hz, with 50/50 duty cycle.
   
   Initial version coded by karttu, Jan 16-19 2010, and placed in Public Domain.
   This version April 24 2010.
 */

/* 
 * (See: http://www.arduino.cc/playground/Main/LedControl )
 *
 * Create a new controller 
 * LedControl(int dataPin, int clkPin, int csPin, int numDevices);
 * Params :
 * int dataPin    The pin on the Arduino where data gets shifted out
 * int clockPin   The pin for the clock
 * int csPin      The pin for selecting the device when data is to be sent
 * int numDevices The maximum number of devices that can be controled
*/

/* we have to include the library */
#include "LedControl.h"


// Create a LedControl for 1 MAX7219/7221 device. Use pins 23, 31 & 22:
LedControl lc1=LedControl(23,21,22,1); 

int syncPin =  11;    // To the pind 1 of DIN female plug.
int debugPin = 20;    // Copy of sync pulse is shown here (connected to LED).

volatile unsigned long prevIntrpTime = 0;

volatile int dialedValue = 0; // One-based index, which digit we are tolling. 0 if none.


void setup()
{
  pinMode(syncPin, OUTPUT);
  pinMode(debugPin, OUTPUT);
  
  attachInterrupt(2, rotIntrp, RISING);
  
  for(int dev=0;dev<lc1.getDeviceCount();dev++)
   { 
     lc1.shutdown(dev,false);
   //set a maximum brightness for the Leds
     lc1.setIntensity(dev,15);
     lc1.clearDisplay(dev);
   }

}


// the loop() method runs over and over again,
// as long as the Arduino has power

void loop()                     
{
  outputDecimal(dialedValue);

  if(dialedValue) // If it's zero, do not send sync pulse.
   {
     digitalWrite(syncPin, HIGH);
     digitalWrite(debugPin, HIGH);
     delay(dialedValue>>1);
     digitalWrite(syncPin, LOW);
     digitalWrite(debugPin, LOW);
     delay(dialedValue>>1);
   }
}

void rotIntrp()
{
   unsigned long msnow, delta;
  
   msnow = millis();
   delta = msnow - prevIntrpTime;
   prevIntrpTime = msnow;
   
// Empirically found values for old Ericsson telephone with a rotary dial.
// If 250 ms has elapsed since the last rising edge, then the user
// has started dialing a new digit.
// If more than 50 ms (but less than 250 ms) has elapsed since the last rising edge,
// then we can acknowledge this pulse. (Note that there's a lots of bouncing!)

   if(delta > 3000) // User starts dialing a new value.
    {
      dialedValue = 0;
    }
   else if(delta > 250) // Next digit.
    {
      dialedValue *= 10;
    }
   else if(delta > 50) // Increment the lsd of dialedValue.
    {
// Otherwise dialedValue++ would be sufficient, bu we want to handle
// the digit '0' correctly:
      dialedValue = (10*(dialedValue/10)) + ((dialedValue+1)%10);
    }

}


/* 
 * Display a (hexadecimal) digit on a 7-Segment Display
 * Params:
 * addr  address of the display
 * digit the position of the digit on the display (0..7)
 * value the value to be displayed. (0x00..0x0F)
 * dp    sets the decimal point.

void setDigit(int addr, int digit, byte value, boolean dp);

 * The digit-argument must be from the range 0..7 because the MAX72XX can drive
   up to eight 7-segment displays. The index starts at 0 as usual. 

 */


void outputDecimal(volatile int n)
{
    int i=0;

    do
     {
       lc1.setDigit(0,i,(byte)(n%10),false);
       i++;
       n /= 10;
     } while(n);
  
//  Clear the rest of digits with blanks:
    while(i < 8) { lc1.setChar(0,i++,' ',false); }
}


