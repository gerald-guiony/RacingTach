//
//  OouraFFTTestUnit.m
//  RacingTach
//
//  Created by Gérald GUIONY on 27/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OouraFFTTestUnit.h"


// Unit-Test Result Macro Reference :
// http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/905-A-Unit-Test_Result_Macro_Reference/unit-test_results.html#//apple_ref/doc/uid/TP40007959-CH21-SW2

@implementation OouraFFTTestUnit

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
- (void) testBasicFFT 
{
	NSLog(@"%@ start", self.name);   // self.name is the name of the test-case method.
	
	int numPoints = 256;  // puissance de 2
	int numberOfWindows = 3;
	int numberOfTotalSegments = 20;
	
	oouraFFT = [[OouraFFT alloc] initForSignalsOfLength: numPoints andNumWindows: numberOfWindows];
	
	for (int period = 3; period < numPoints; period++)
	{
		for (int j=0; j<numberOfTotalSegments; j++)
		{
			//NSLog(@"-------- Periodogram %d with period %d ---------", j+1, period);
		
			for (int i=0; i<numPoints; i++)
			{
				oouraFFT.inputData[i] = sin(i * (2 * M_PI / period));	
				//NSLog(@"input %d = %f", i, oouraFFT.inputData[i]);
			}
		
			[oouraFFT calculateWelchPeriodogramWithNewSignalSegment];
		
			int frequenceWithMaxNrj = 0;
		
			for (int i=0; i<oouraFFT.numFrequencies; i++)
			{
				//NSLog(@"fréquence %d = %f", i, oouraFFT.spectrumData[i]);
				if (oouraFFT.spectrumData[i] > oouraFFT.spectrumData[frequenceWithMaxNrj])
				{
					frequenceWithMaxNrj = i;
				}
			}
		
			// Check that frequence == numPoints / period
			int frequenceToFound = (int)(numPoints / period);
			//NSLog(@"fréquence found : %d with max energie (%f)", frequenceWithMaxNrj, oouraFFT.spectrumData[frequenceWithMaxNrj]);
			
			// Si le nombre de periodograms est supérieur au nombre de fenêtres
			if (j+1 >= numberOfWindows)
			{
				STAssertTrue((frequenceToFound <= frequenceWithMaxNrj) && (frequenceWithMaxNrj <= frequenceToFound + 1), 
							 @"Periodogram %d with period %d : frequence %d doesn't match ! fréquence to found is between %d and %d", 
							 j+1, period, frequenceWithMaxNrj, frequenceToFound, frequenceToFound+1);
			}
		}
	}
	
	[oouraFFT release];
	 
	NSLog(@"%@ end", self.name);
}
@end
