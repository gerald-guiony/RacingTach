//
//  MedianFilterTestUnit.m
//  RacingTach
//
//  Created by Gérald GUIONY on 27/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MedianFilterTestUnit.h"


// Unit-Test Result Macro Reference :
// http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/905-A-Unit-Test_Result_Macro_Reference/unit-test_results.html#//apple_ref/doc/uid/TP40007959-CH21-SW2

@implementation MedianFilterTestUnit

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
// Test d'un filtre médian basique
//
- (void) testBasicMedianFilter 
{
	NSLog(@"%@ start", self.name);   // self.name is the name of the test-case method.
	
	WindowElem * pFirstWindowElem = NULL;
	UInt16 windowSize = 5;
		
	STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, 100, windowSize) == 100, @"Median found doesn't match !");

	for (int i=0; i<windowSize; i++)
	{
		if (i<windowSize/2)
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, 200, windowSize) == 100, @"Median found doesn't match !");
		else
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, 200, windowSize) == 200, @"Median found doesn't match !");
	}

	for (int i=0; i<windowSize; i++)
	{
		if (i<windowSize/2)
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, 0, windowSize) == 200, @"Median found doesn't match !");
		else
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, 0, windowSize) == 0, @"Median found doesn't match !");
	}
	
	for (int i=0; i<=1000; i++)
	{
		if (i<windowSize/2)
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, i, windowSize) == 0, @"Median found doesn't match !");
		else
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, i, windowSize) == (i - (windowSize/2)), @"Median found doesn't match !");
	}
	
	for (int i=999; i>=0; i--)
	{
		if ((999 - i)<=windowSize/2)
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, i, windowSize) == 999, @"Median found doesn't match (i = %d) !", i);
		else
			STAssertTrue(computeWindowMedianfilter (&pFirstWindowElem, i, windowSize) == (i + (windowSize/2)), @"Median found doesn't match (i = %d) !", i);
	}	
	
	deleteWindowElemList (&pFirstWindowElem);	
	STAssertTrue(pFirstWindowElem == NULL, @"List is not null !");
	
	NSLog(@"%@ end", self.name);
}
@end
