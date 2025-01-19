//
//  AudioRemoteIOTestUnit.h
//  DynOnTrack
//
//  Created by Gérald GUIONY on 16/02/10.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

//  Dependent unit tests mean unit test code depends on an application to be injected into.
//  Setting this to 0 means the unit test code is designed to be linked into an independent executable.



//#define TESTING 

#ifdef TESTING
#import <SenTestingKit/SenTestingKit.h>
#endif

#import <UIKit/UIKit.h>

//#import "application_headers" as required
#import "OouraFFT.h"
#import "AutoCorrelation.h"
#import "AudioRemoteIO.h"

#define kNbBuffers 	2
#define kNbValues 	1024



#ifdef TESTING
@interface AudioRemoteIOTestUnit : SenTestCase <AudioRemoteIODelegate>
#else
@interface AudioRemoteIOTestUnit : NSObject <AudioRemoteIODelegate>
#endif
{
	int				_numPoints;
	int				_numberOfWindows;
	int				_period;
	OouraFFT *		_oouraFFT;
	
	UInt32			_nbGetAudio;
	UInt32			_nbSetAudio;

	kAudioDataType	_playerValues [kNbBuffers][kNbValues];
}

#ifndef TESTING

-(void) setUp;
-(void) tearDown;
-(void) testRecorder;
-(void) testPlayer;
-(void) testRecorderAndPlayer;

#endif

@end
