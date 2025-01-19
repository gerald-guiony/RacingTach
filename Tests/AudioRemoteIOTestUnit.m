//
//  AudioRemoteIOTestUnit.m
//  RacingTach
//
//  Created by Gérald GUIONY on 16/02/10.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <unistd.h>

#import "AudioRemoteIOTestUnit.h"

// Unit-Test Result Macro Reference :
// http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/905-A-Unit-Test_Result_Macro_Reference/unit-test_results.html#//apple_ref/doc/uid/TP40007959-CH21-SW2

#define WAIT 20


BOOL ShowValues = true;
BOOL CalculateFreq = true;
BOOL AutoCorrelation = true;

@implementation AudioRemoteIOTestUnit

#pragma mark Test Setup/teardown

//
// The setUp method is called automatically before each test-case method (methods whose name starts with 'test').
//
-(void) setUp 
{
	NSLog(@"setUp");
	
	_numPoints = 1024; //512;  // puissance de 2
	_numberOfWindows = 3;
	_period = 100;
	
	_oouraFFT = [[OouraFFT alloc] initForSignalsOfLength: _numPoints andNumWindows: _numberOfWindows];
	
	// Remplissage du buffer des valeurs	
	for (UInt32 i = 0; i < kNbBuffers; i++) 
	{
		for (int j = 0; j < kNbValues; j++) 
		{
			_playerValues[i][j] = (kAudioDataType) (32500.0 * sin(j * (2 * M_PI / _period)));
		}
	}	
}

//
// The tearDown method is called automatically after each test-case method (methods whose name starts with 'test').
//
-(void) tearDown 
{	
	NSLog(@"tearDown");
}

//
// Delivers the latest audio data to the delegate
//
-(void) getAudioBufferList: (AudioBufferList *)ioData
{	
	_nbGetAudio++;
	
	NSLog(@"--- getAudioBufferList ---");
	
	// uniquement la première fois
	//if (_nbGetAudio == 1)
	{
		
		if (ShowValues)
		{
			// mNumberBuffers = mChannelsPerFrame
			for (UInt32 i = 0; i < ioData->mNumberBuffers; i++) 
			{
				kAudioDataType * data_ptr = (kAudioDataType *)(ioData->mBuffers[i].mData);	
				for (int j=0; j < ioData->mBuffers[i].mDataByteSize / sizeof(kAudioDataType); j++)
				{
					NSLog(@"<<< GetAudio: ioData [%d, %d] = %d", i, j, data_ptr[0]);
					data_ptr++;
				}	
			}
		}
		
		if (CalculateFreq)
		{
			// Remplissage du buffer d'entrée pour le calcul de la FFT
			kAudioDataType * data_ptr = (kAudioDataType *)(ioData->mBuffers[0].mData);	
			for (int j=0; j < ioData->mBuffers[0].mDataByteSize / sizeof(kAudioDataType); j++)
			{
				_oouraFFT.inputData[j] = data_ptr[0];
				data_ptr++;
			}
		
			[_oouraFFT calculateWelchPeriodogramWithNewSignalSegment];
		
			int frequenceWithMaxNrj = 0;
		
			for (int i=0; i<_oouraFFT.numFrequencies; i++)
			{
				//NSLog(@"fréquence %d = %f", i, oouraFFT.spectrumData[i]);
				if (_oouraFFT.spectrumData[i] > _oouraFFT.spectrumData[frequenceWithMaxNrj])
				{
					frequenceWithMaxNrj = i;
				}
			}
		
			// Check that frequence == numPoints / period
			int frequenceToFound = (int)(_numPoints / _period);
			//NSLog(@"Fréquence to found %d", frequenceToFound);
		
			NSLog(@"fréquence found : %d with max energie (%f)", frequenceWithMaxNrj, _oouraFFT.spectrumData[frequenceWithMaxNrj]);
			
			// Si le nombre de periodograms est supérieur au nombre de fenêtres
			if (_nbGetAudio+1 >= _numberOfWindows)
			{
				if ((frequenceToFound > frequenceWithMaxNrj) || (frequenceWithMaxNrj > frequenceToFound + 1))
				{
					//NSLog(@"Periodogram %d with period %d : frequence %d doesn't match ! fréquence to found is between %d and %d", 
					//	 _nbGetAudio+1, _period, frequenceWithMaxNrj, frequenceToFound, frequenceToFound+1);
				}
			}			
		}
		
		if (AutoCorrelation)
		{
			kAudioDataType * data_ptr = (kAudioDataType *)(ioData->mBuffers[0].mData);	
		
			_period = 200;
			//int periodFound = findPeriodWithACF (data_ptr, ioData->mBuffers[0].mDataByteSize / sizeof(kAudioDataType), _period - 50, _period + 50, 50);
			int periodFound = findPeriodWithACF (data_ptr, ioData->mBuffers[0].mDataByteSize / sizeof(kAudioDataType), _period - 50, _period + 50, 10);
			//int periodFound = findPeriodWithMACF (data_ptr, ioData->mBuffers[0].mDataByteSize / sizeof(kAudioDataType), _period - 50, _period + 50, 10, 20);
			
			NSLog(@"Period found : %d", periodFound);
		}		
	}		
}

//
// Delegate creates the audio data 
//
-(void) setAudioBufferList: (AudioBufferList *)ioData
{
	_nbSetAudio++;
	
	NSLog(@"--- setAudioBufferList ---");
	
	// uniquement le première fois
	//if (_nbSetAudio == 1)
	{
		for (UInt32 i = 0; i < MIN (kNbBuffers, ioData->mNumberBuffers); i++) 
		{
			int minSize = MIN (kNbValues, ioData->mBuffers[i].mDataByteSize / sizeof(kAudioDataType));
			memcpy (ioData->mBuffers[i].mData, _playerValues[i], minSize * sizeof(kAudioDataType));       
			
			if (ShowValues)
			{			
				kAudioDataType * data_ptr = (kAudioDataType *)(ioData->mBuffers[i].mData);			
				for (int j=0; j < minSize; j++)
				{				
					NSLog(@">>> SetAudio: ioData [%d, %d] = %d", i, j, data_ptr[0]);
					data_ptr++;
				}
			} 
		}
	}		
}

//
// Test de l'enregistrement
//
-(void) testRecorder 
{
	NSLog(@"testRecorder start");
	
	// Initialisation
	_nbGetAudio = _nbSetAudio = 0;	
	
	ShowValues = false;
	CalculateFreq = false;
	AutoCorrelation = true;
	
	AudioRemoteIO * _audioRemote = [[AudioRemoteIO alloc] initWithAudioDelegate: self andIsRemoteRecording: true andIsRemotePlayback: false]; 
	NSAssert(_audioRemote != nil, @"Cannot create AudioRemoteIO instance");
	
	// Start the audio
	[_audioRemote start];
	
	// Wait 1s before stop
	sleep (20);
	
	// Check
	NSAssert(_nbGetAudio > 0, @"Get Audio fails");

	// Stop the audio
	[_audioRemote stop];
	[_audioRemote release];
	
	NSLog(@"testRecorder end");
}

//
// Test du player
//
-(void) testPlayer
{
	NSLog(@"testPlayer start");   
	
	// Initialisation
	_nbGetAudio = _nbSetAudio = 0;	
	
	ShowValues = true;
	CalculateFreq = false;
	AutoCorrelation = false;
	
	AudioRemoteIO * _audioRemote = [[AudioRemoteIO alloc] initWithAudioDelegate: self andIsRemoteRecording: false andIsRemotePlayback: true]; 
	NSAssert(_audioRemote != nil, @"Cannot create AudioRemoteIO instance");
	
	// Start the audio
	[_audioRemote start];
	
	// Wait 1s before stop
	sleep (WAIT);
	
	// Check
	NSAssert(_nbSetAudio > 0, @"Set Audio fails");

	// Stop the audio
	[_audioRemote stop];
	[_audioRemote release];
	
	NSLog(@"testPlayer end");
}

//
// Test de l'enregistrement et du player
// 
// Un truc pas mal pour debugger : http://stackoverflow.com/questions/558568/how-do-i-debug-with-nsloginside-of-the-iphone-simulator
// There's a far more convenient way to trace with log messages in Xcode, and that's using Breakpoint Actions.
// On the line of code where you'd be tempted to add a printf or NSLog, set a breakpoint, then control-click it and choose "Edit Breakpoint".
// In the blue bubble that appears, click the + button on the right to open the Breakpoint Actions: alt text
// Enter your log text there. Any expression that can be printed in the Debugger can be used when delimited by @ signs.
// For debugging Objective-C it's generally more useful to choose "Debugger Command" from the popup and enter 'po [[object method] method]' 
// to print the description string of an Objective-C object or the result of a method call.
// Make sure to click the "Continue" checkbox at the top right so execution continues after the log.
// Advantages of this over NSLog and printf:
//    * It's on the fly. You don't have to recompile and restart to add or edit log messages. This saves you a lot of time.
//    * You can selectively enable and disable them. If you learn enough from one, but its spew is interfering, just uncheck its Enabled box.
//    * All the output is generated on your Mac, never on the iPhone, so you don't have to download and parse through logs after the fact.
//    * The chance of shipping console spew in your application is significantly decreased.
// Also check out the Speak button; it's great for debugging full-screen apps where you can't see the debug log.
//
//
-(void) testRecorderAndPlayer
{	
	NSLog(@"testRecorderAndPlayer start"); 
	
	NSLog(@"Pour jouer ce test il faut relier la sortie audio avec l'entrée micro !");
	
	// Initialisation
	_nbGetAudio = _nbSetAudio = 0;	
	
	ShowValues = false;
	CalculateFreq = false;
	AutoCorrelation = true;
	
	AudioRemoteIO * recorderRemote = [[AudioRemoteIO alloc] initWithAudioDelegate: self andIsRemoteRecording: true andIsRemotePlayback: false]; 
	NSAssert(recorderRemote != nil, @"Cannot create AudioRemoteIO recorder instance");
	
	AudioRemoteIO * playerRemote = [[AudioRemoteIO alloc] initWithAudioDelegate: self andIsRemoteRecording: false andIsRemotePlayback: true]; 
	NSAssert(playerRemote != nil, @"Cannot create AudioRemoteIO player instance");
		
	// Start the audio
	[recorderRemote start];
	[playerRemote start];
	
	// Wait 1s before stop
	sleep (WAIT);
	
	// Check
	// Les buffers _getValues et _setValues sont ils egaux ?
	
	// Stop the audio
	[recorderRemote stop];	
	[playerRemote stop];
	[recorderRemote release];	
	[playerRemote release];
	
	NSLog(@"testRecorderAndPlayer end");
}

@end
