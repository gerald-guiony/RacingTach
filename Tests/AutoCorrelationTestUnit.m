//
//  AutoCorrelationTestUnit.m
//  RacingTach
//
//  Created by Gérald GUIONY on 27/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AutoCorrelationTestUnit.h"


// Unit-Test Result Macro Reference :
// http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/905-A-Unit-Test_Result_Macro_Reference/unit-test_results.html#//apple_ref/doc/uid/TP40007959-CH21-SW2

@implementation AutoCorrelationTestUnit

#pragma mark Test Setup/teardown

//
// The setUp method is called automatically before each test-case method (methods whose name starts with 'test').
//
- (void) setUp 
{
	NSLog(@"%@ setUp", self.name);
}

//
// The tearDown method is called automatically after each test-case method (methods whose name starts with 'test').
//
- (void) tearDown 
{
	NSLog(@"%@ tearDown", self.name);
}

//
// Test d'une FFT basique
//
- (void) testBasicAutoCorrelation 
{
	NSLog(@"%@ start", self.name);   // self.name is the name of the test-case method.
	
	int numPoints = 1024;  
	short buffer [numPoints];
			
	// Il faut au moins le double de points par rapport a la période !
	for (int period = 3; period < numPoints/2; period++)	
	{
		NSLog(@"--------- Period %d ---------", period);
		
		for (int i=0; i<numPoints; i++)
		{
			buffer [i] = (int) (0.5 + (32500.0 * sin(i * (2.0 * M_PI / period))));
		}	
		
		//int periodFound = findPeriodWithACF (buffer, numPoints, 3, numPoints - 1, 50);
		int periodFound = findPeriodWithMACF (buffer, numPoints, 3, numPoints - 1, 50, 50);
		
		NSLog(@"=> Period found = %d", periodFound);
		
		STAssertTrue((period - 3 <= periodFound) && (periodFound <= period + 3), @"Period found doesn't match !");
	}
		 
	NSLog(@"%@ end", self.name);
}
@end
