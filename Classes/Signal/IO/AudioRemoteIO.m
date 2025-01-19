//
//  AudioRemoteIO.m
//  RacingTach
//
//  Created by Gérald GUIONY on 05/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import "AudioRemoteIO.h"

#define kOutputBus	0
#define kInputBus	1

// Flag d'allocation automatique des buffers d'enregistrement audio
BOOL IsAutoAllocRecordBuffer = NO;


// ------------------------------------------------------------------------------------------------------------------------------------
// Parameters on entry to this function are :-
//
// *inRefCon - used to store whatever you want, can use it to pass in a reference to an objectiveC class
//			 The line below :
//				callbackStruct.inputProcRefCon = self;
//			 in the initialiseAudio method sets this to "self" (i.e. this instantiation of AudioRemoteIO).
//			 This is a way to bridge between objectiveC and the straight C callback mechanism, another way
//			 would be to use an "evil" global variable by just specifying one in theis file and setting it
//			 to point to inMemoryAudiofile whenever it is set.
//
// *inTimeStamp - the sample time stamp, can use it to find out sample time (the sound card time), or the host time
//
// inBusnumber - the audio bus number, we are only using 1 so it is always 0
//
// inNumberFrames - the number of frames we need to fill. In this example, because of the way audioformat is
//				  initialised below, a frame is a 32 bit number, comprised of two signed 16 bit samples.
//
// *ioData - holds information about the number of audio buffers we need to fill as well as the audio buffers themselves
// ------------------------------------------------------------------------------------------------------------------------------------
static OSStatus playbackCallback (void *inRefCon,
								  AudioUnitRenderActionFlags *ioActionFlags,
								  const AudioTimeStamp *inTimeStamp,
								  UInt32 inBusNumber,
								  UInt32 inNumberFrames,
								  AudioBufferList *ioData )
{
    // Each thread that uses Obj-C objects (appkit, foundation etc, directly or indirectly) must have an autorelease pool in place
	NSAutoreleasePool * autoreleasepool = [[NSAutoreleasePool alloc] init];

	// Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.

	// Get a copy of the objectiveC class "self" we need this to get the next sample to fill the buffer
	AudioRemoteIO *remoteIOplayer = (AudioRemoteIO *)inRefCon;

	/*
	 // Loop through all the buffers that need to be filled
	 for (int i = 0 ; i<ioData->mNumberBuffers; i++)
	 {
	 // i = 0 : right stereo channels, i = 1 : left stereo channels ?

	 // Get the buffer to be filled
	 AudioBuffer buffer = ioData->mBuffers[i];

	 // If needed we can get the number of bytes that will fill the buffer using
	 // int numberOfSamples = ioData->mBuffers[i].mDataByteSize;

	 // Get the buffer and point to it as an UInt32 (as we will be filling it with 32 bit samples)
	 // if we wanted we could grab it as a 16 bit and put in the samples for left and right seperately
	 // but the loop below would be for(j = 0; j < inNumberFrames * 2; j++) as each frame is a 32 bit number
	 UInt32 * frameBuffer = buffer.mData;

	 // Loop through the buffer and fill the frames
	 for (int j = 0; j<inNumberFrames; j++)
	 {
	 // frameBuffer[j] = ...
	 }
	 }
	 */

	/*
	 // Exemple :

	 static int phase = 0;

	 for (UInt32 i = 0; i < ioData->mNumberBuffers; i++)
	 {
	 int samples = ioData->mBuffers[i].mDataByteSize / sizeof(SInt16);
	 SInt16 values [samples];
	 float waves;

	 for (int j = 0; j < samples; j++)
	 {
	 waves = 0;

	 waves += sin(kWaveform * 440.0f * phase);
	 waves += sin(kWaveform * 659.3f * phase);
	 waves += sin(kWaveform * 1760.3f * phase);
	 waves += sin(kWaveform * 880.0f * phase);

	 waves *= 32500/4;// / 4; // <--------- make sure to divide by how many waves you're stacking

	 values[j] = (SInt16)waves;
	 //values[j] += values[j]<<16; // ???????????

	 phase++;
	 if (phase > 1000) phase = 0;
	 }

	 memcpy(ioData->mBuffers[i].mData, values, samples * sizeof(SInt16));
	 }
	 */

	if (remoteIOplayer.audioDelegate && [remoteIOplayer.audioDelegate respondsToSelector:@selector(setAudioBufferList:)])
	{
		[remoteIOplayer.audioDelegate setAudioBufferList: ioData];
	}

	// Release the pool
	[autoreleasepool release];

    return noErr;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Acquiring data from the AudioOutputUnit
// Try not to do too much here.
// ------------------------------------------------------------------------------------------------------------------------------------
static OSStatus recordingCallback (void* inRefCon,
								   AudioUnitRenderActionFlags* ioActionFlags,
								   const AudioTimeStamp* inTimeStamp,
								   UInt32 inBusNumber,
								   UInt32 inNumberFrames,
								   AudioBufferList* ioData )
{
	// Each thread that uses Obj-C objects (appkit, foundation etc, directly or indirectly) must have an autorelease pool in place
	NSAutoreleasePool * autoreleasepool = [[NSAutoreleasePool alloc] init];

	// This method is our callback method, it will be called every time RemoteIO has filled its buffer, and will then
	// pass the buffer along to us for us to do what we want with it. You have to be very careful with the AudioUnitRender,
	// and if your having any problems in your code make sure you check the logs to see if it has returned noErr (no error)

	// Use inRefCon to access our interface object to do stuff
    // Then, use inNumberFrames to figure out how much data is available, and make
    // that much space available in buffers in an AudioBufferList.

	AudioRemoteIO * remoteIORecorder = (AudioRemoteIO *) inRefCon;
	AudioBufferList * bufferList = &(remoteIORecorder->_recorderBufferList);

	if (ioData != nil)
	{
		NSLog(@"recordingCallback : 'AudioBufferList* ioData' is not null ???");
	}

	if (IsAutoAllocRecordBuffer)
	{
		/*
		UInt32 numChannels = 0;
		UInt32 sizeOfNumChannels = sizeof(UInt32);
		OSStatus status = AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareInputNumberChannels, &sizeOfNumChannels, &numChannels);
		if (status != noErr)
		{
			NSLog(@"couldn't get input channel count");
		}
		*/

		bufferList->mNumberBuffers = remoteIORecorder.audioFormat.mChannelsPerFrame; //numChannels;
		for (int i=0; i<bufferList->mNumberBuffers; ++i)
		{
			bufferList->mBuffers[i].mNumberChannels = 1;
			bufferList->mBuffers[i].mDataByteSize = inNumberFrames * remoteIORecorder.audioFormat.mBytesPerFrame;
			bufferList->mBuffers[i].mData = NULL;
		}
	}

	// The AudioBufferList, ioData will be NULL, therefore you must provide your own allocated AudioBufferList.
	// Fill this up with buffers (you will want to malloc it, as it's a dynamic-length list)
	ioData = bufferList;

	// Obtain recorded samples
	// we will call AudioUnitRender from within the input proc. The input proc's render action flags, time stamp,
	// bus number and number of frames requested should be propagated down to the AudioUnitRender call.
	OSStatus status = AudioUnitRender (	remoteIORecorder.audioUnit,
									   ioActionFlags,
									   inTimeStamp,
									   inBusNumber, 	// will be '1' for input data
									   inNumberFrames, 	// # of frames requested
									   ioData );
	if (status == noErr)
	{
		// Now, we have the samples we just read sitting in buffers in bufferList
		// doSomethingWithAudioBuffer((SInt16*)audioRIO.bufferList->mBuffers[0].mData, inNumberFrames);
		//
		// SInt8 *data_ptr = (SInt8 *)(ioData->mBuffers[0].mData);
		// for (i=0; i<inNumberFrames; i++)
		// {
		//	drawBuffers[0][i] = data_ptr[2];
		//	data_ptr += 4;
		// }

		if (remoteIORecorder.audioDelegate && [remoteIORecorder.audioDelegate respondsToSelector: @selector(getAudioBufferList:)])
		{
			if (ioData) [remoteIORecorder.audioDelegate getAudioBufferList: ioData];
		}

		//NSLog(@"Audio ok");
	}
	else
	{
		// To get an idea about what an OSStatus represent, you can use thoses 2 functions (from CarbonCore):
		// const char* GetMacOSStatusErrorString(OSStatus err);
		// const char* GetMacOSStatusCommentString(OSStatus err);
		// Un truc pas mal pour debugger : http://stackoverflow.com/questions/558568/how-do-i-debug-with-nsloginside-of-the-iphone-simulator

		// Dans le fichier MacErrors.h
		switch (status)
		{
			case kAudioUnitErr_InvalidProperty:
				NSLog(@"AudioUnitRender Failed: Invalid Property");
				break;
			case -50:
				NSLog(@"AudioUnitRender Failed: Invalid Parameter(s)");
				break;
			default:
				NSLog(@"AudioUnitRender Failed: Unknown (%d)", status);
				break;
		}
	}

	// Release the pool
	[autoreleasepool release];

	return status;
}


// ------------------------------------------------------------------------------------------------------------------------------------
// ... because the call back is only informed that a device has changed
// ------------------------------------------------------------------------------------------------------------------------------------
void audioRouteChangeListenerCallback (void * inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void * inPropertyValue)
{
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;

	AudioRemoteIO * self = (AudioRemoteIO *)inUserData;

	/*
	// ReceiverAndMicrophone : sans écouteurs
	// HeadphonesAndMicrophone : écouteurs sans micro intégré
	// HeadsetInOut: écouteurs avec micro intégré comme celui de Apple

 	if ([[self currentAudioRoute] isEqualToString: @"HeadsetInOut"])
	{
		if (self.audioDelegate && [(NSObject *)self.audioDelegate respondsToSelector: @selector(headsetPlugged:)])
		{
			[self.audioDelegate headsetPlugged: YES];
		}
	}
	else
	{
		if (self.audioDelegate && [(NSObject *)self.audioDelegate respondsToSelector: @selector(headsetPlugged:)])
		{
			[self.audioDelegate headsetPlugged: NO];
		}
	}
	*/

	CFDictionaryRef routeChangeDictionary = inPropertyValue;
	CFNumberRef routeChangeReasonRef = CFDictionaryGetValue (routeChangeDictionary,	CFSTR (kAudioSession_AudioRouteChangeKey_Reason));

	SInt32 routeChangeReason;
	CFNumberGetValue (routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);

	if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
	{
		// Headset is unplugged..
		if (self.audioDelegate && [(NSObject *)self.audioDelegate respondsToSelector: @selector(headsetPlugged:)])
		{
			[self.audioDelegate headsetPlugged: NO];
		}
	}
	if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable)
	{
		// Headset is plugged in..
		if (self.audioDelegate && [(NSObject *)self.audioDelegate respondsToSelector: @selector(headsetPlugged:)])
		{
			[self.audioDelegate headsetPlugged: YES];
		}
	}
}



@implementation AudioRemoteIO

@synthesize audioDelegate		= _audioDelegate;
@synthesize audioUnit			= _audioUnit;
@synthesize audioFormat			= _audioFormat;
@synthesize recorderBufferList	= _recorderBufferList;

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur par défaut
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithAudioDelegate: (id <AudioRemoteIODelegate>)audioDelegate andIsRemoteRecording: (BOOL)isRemoteRecording andIsRemotePlayback: (BOOL)isRemotePlayback
{
	self = [super init];
	if (self != nil)
	{
		@try
		{
			NSAssert(isRemoteRecording || isRemotePlayback, @"At least one of the remote mode (recording or playback) must be enabled !");

			OSStatus status;

			// Initialisation du flag
			_started = NO;

			// Délégué pour traiter les données audio
			_audioDelegate = audioDelegate;

			// -------------------------------------------------------------------------------------------------------------
			// Initialize and configure the audio session

			AudioSessionInitialize (NULL, NULL, NULL, nil);	// Pas d'interruptions

			UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
			AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);

			// Le simulateur s'en fou royalement, la taille de son buffer est toujours 512
			if (isRemoteRecording && IsAutoAllocRecordBuffer && (kLatency > 0))
			{
				// You can adjust the latency of RemoteIO (and, in fact, any other audio framework)
				// by setting the kAudioSessionProperty_PreferredHardwareIOBufferDuration property.
				// This adjusts the length of buffers that’re passed to you – if buffer length was
				// originally, say, 1024 samples, then halving the number of samples halves the amount
				// of time taken to process them.
				// => The simulator doesn't seem to respect this property !
				Float32 preferredBufferSize = kLatency;
				AudioSessionSetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
			}

			// register the property change listener;
			AudioSessionPropertyID routeChangeID = kAudioSessionProperty_AudioRouteChange;
			AudioSessionAddPropertyListener (routeChangeID, audioRouteChangeListenerCallback, self);

			// *** Activate the Audio Session before asking for the "Current" properties ***
			AudioSessionSetActive (true);

			Float64 mHWSampleRate = 0.0;
			UInt32 size = sizeof (mHWSampleRate);
			AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareSampleRate, &size, &mHWSampleRate);
			NSLog(@"Current hardware sample rate : %lf", mHWSampleRate);

			Float32 mHWBufferDuration = 0.0;
			size = sizeof (mHWBufferDuration);
			AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareIOBufferDuration, &size, &mHWBufferDuration);
			NSLog(@"Current hardware IO buffer duration : %f", mHWBufferDuration);

			// -------------------------------------------------------------------------------------------------------------
			// Describe audio component

			AudioComponentDescription desc;
			// There are several different types of Audio Units.
			// Some audio units serve as Outputs, Mixers, or DSP units. See AUComponent.h for listing
			desc.componentType = kAudioUnitType_Output;
			// Every Component has a subType, which will give a clearer picture of what this components function will be.
			desc.componentSubType = kAudioUnitSubType_RemoteIO;
			// All Audio Units in AUComponent.h must use "kAudioUnitManufacturer_Apple" as the Manufacturer
			desc.componentFlags = 0;
			desc.componentFlagsMask = 0;
			desc.componentManufacturer = kAudioUnitManufacturer_Apple;

			// Finds a component that meets the desc spec's
			// Get component
			AudioComponent inputComponent = AudioComponentFindNext (NULL, &desc);

			// Gains access to the services provided by the component
			// Get audio units
			status = AudioComponentInstanceNew (inputComponent, &_audioUnit);
			NSAssert(status == noErr, @"Failed AudioComponentInstanceNew");

			// Because the AUHAL (audio unit hardware abstraction layer) can be used for both input and output, we must
			// eventually also disable IO on the input or output scope.

			// -------------------------------------------------------------------------------------------------------------
			// Enable or disable IO

			// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
			// Enable or disable IO for playback
			UInt32 enableIO = isRemotePlayback ? 1 : 0;
			status = AudioUnitSetProperty (	_audioUnit,
										   kAudioOutputUnitProperty_EnableIO,
										   kAudioUnitScope_Output,
										   kOutputBus,
										   &enableIO,
										   sizeof(enableIO) );
			NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Enable IO for playback");
			// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			// Enable or disable IO for recording
			enableIO = isRemoteRecording ? 1 : 0;

			// When using AudioUnitSetProperty the 4th parameter in the method refer to an AudioUnitElement. When using
			// an AudioOutputUnit the input element will be '1' and the output element will be '0'
			// Voir "The signal flow of the AUHAL" : http://developer.apple.com/mac/library/technotes/tn2002/tn2091.html
			status = AudioUnitSetProperty (	_audioUnit,
										   kAudioOutputUnitProperty_EnableIO,
										   kAudioUnitScope_Input,
										   kInputBus,
										   &enableIO,
										   sizeof(enableIO) );
			NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Enable IO for recording");

			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
/*
			// todo => Chercher le micro :)
			// Use default input device
			AudioDeviceID inputDeviceID;
			UInt32 size = sizeof(AudioDeviceID);
			status = AudioHardwareGetProperty(	kAudioHardwarePropertyDefaultInputDevice,
												&size,
												&inputDeviceID);
			NSAssert(status == noErr, @"Failed AudioHardwareGetProperty: Obtaining the default input device");

			// Set the Current Device to the AUHAL.
			// this should be done only after IO has been enabled on the AUHAL.
			status = AudioUnitSetProperty(	_audioFormat,
											kAudioOutputUnitProperty_CurrentDevice,
											kAudioUnitScope_Global,
											0, 						// kInputBus ??
											&inputDeviceID,
											size);
			NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Associating the default input device to inputUnit as the current device");
*/
			// -------------------------------------------------------------------------------------------------------------
			// Describe format

			// The audio format described below uses SInt16 for samples (i.e. signed, 16 bits per sample)
			_audioFormat.mSampleRate 		= kSampleRate;
			// linear pulse-code-modulated (linear PCM), the most common uncompressed data format for digital audio
			_audioFormat.mFormatID 			= kAudioFormatLinearPCM;
			_audioFormat.mFormatFlags 		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
			//_audioFormat.mFormatFlags 	= kAudioFormatFlagsCanonical | kAudioFormatFlagIsNonInterleaved;
			_audioFormat.mFramesPerPacket 	= 1;  // 1 => 512 points, 2 => 1024 points
			_audioFormat.mChannelsPerFrame 	= 1;  // 1; 2 => for iphone simulator ??? 2 => stereo output
			_audioFormat.mBitsPerChannel	= sizeof(kAudioDataType) * 8;  // 16-bit ?
			_audioFormat.mBytesPerFrame		= (_audioFormat.mBitsPerChannel / 8)  /* * _audioFormat.mChannelsPerFrame*/;
			_audioFormat.mBytesPerPacket	= _audioFormat.mBytesPerFrame * _audioFormat.mFramesPerPacket;
			_audioFormat.mReserved 			= 0;

			// -------------------------------------------------------------------------------------------------------------
			// Apply format

			// Apply format for playback
			status = AudioUnitSetProperty (	_audioUnit,
										   kAudioUnitProperty_StreamFormat,
										   kAudioUnitScope_Input,
										   kOutputBus,
										   &_audioFormat,
										   sizeof(_audioFormat) );
			NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Apply format for playback");

			// Apply format for recording
			// set format to output scope
			status = AudioUnitSetProperty (	_audioUnit,
										   kAudioUnitProperty_StreamFormat,
										   kAudioUnitScope_Output,
										   kInputBus,
										   &_audioFormat,
										   sizeof(_audioFormat) );
			NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Apply format for recording");

			// -------------------------------------------------------------------------------------------------------------
			// Set callback

			// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
			// Set output callback for playing
			if (isRemotePlayback)
			{
				AURenderCallbackStruct callbackStruct;
				callbackStruct.inputProc = playbackCallback;
				callbackStruct.inputProcRefCon = self;
				status = AudioUnitSetProperty (	_audioUnit,
											   kAudioUnitProperty_SetRenderCallback,
											   kAudioUnitScope_Global,
											   kOutputBus,
											   &callbackStruct,
											   sizeof(callbackStruct) );
				NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Set output callback for playing");
			}
			// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			// Set input callback for recording
			if (isRemoteRecording)
			{
				// Register the input procedure for the AUHAL. This procedure will be called when the AUHAL has
				// received new data from your input device.
				// set the reference to "self" this becomes *inRefCon in the playback callback
				// as the callback is just a straight C method this is how we can pass it an objective-C class
				AURenderCallbackStruct callbackStruct;
				callbackStruct.inputProc = recordingCallback;
				callbackStruct.inputProcRefCon = self;
				status = AudioUnitSetProperty (	_audioUnit,
											   kAudioOutputUnitProperty_SetInputCallback,
											   kAudioUnitScope_Global,	// kAudioUnitScope_Output ??
											   kInputBus, 				// 0 ??
											   &callbackStruct,
											   sizeof(callbackStruct) );
				NSAssert(status == noErr, @"Failed AudioUnitSetProperty: Set input callback for recording");
			}
			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


			// -------------------------------------------------------------------------------------------------------------
			// Buffer allocation for the recorder

			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			if (isRemoteRecording)
			{
				if (!IsAutoAllocRecordBuffer)
				{
					// The bufferList is a bufferList we shall allocate at the start to preventing allocation from happening
					// in the audio callback, the reason for this is because RemoteIO does not take kindly to people using
					// allocation methods during its callback (I have no idea why, but it slows down the entire program to
					// a crawl for 9 seconds if you)

					// Enable buffer allocation for the recorder (optional - do this if we want to pass in our own)
					UInt32 allocFlag = 1;
					status = AudioUnitSetProperty (	_audioUnit,
												   kAudioUnitProperty_ShouldAllocateBuffer,
												   kAudioUnitScope_Output,	// kAudioUnitScope_Global, kAudioUnitScope_Input, kAudioUnitScope_Output ??
												   kInputBus,				// kOutputBus, kInputBus ??
												   &allocFlag,
												   sizeof(allocFlag) );
					NSAssert(status == noErr, @"Failed AudioUnitSetProperty ShouldAllocateBuffer");

					_recorderBufferList.mNumberBuffers = _audioFormat.mChannelsPerFrame;
					for (UInt32 i=0; i<_recorderBufferList.mNumberBuffers; i++)
					{
						_recorderBufferList.mBuffers[i].mNumberChannels = 1;
#if TARGET_IPHONE_SIMULATOR
						// Number of interleaved channels in the buffer
						_recorderBufferList.mBuffers[i].mDataByteSize = 512 * _audioFormat.mBytesPerFrame;	// 512 with simulator !
#else
						// Number of interleaved channels in the buffer
						_recorderBufferList.mBuffers[i].mDataByteSize = 1024 * _audioFormat.mBytesPerFrame;	// The size of the buffer pointed to by mData
#endif
						_recorderBufferList.mBuffers[i].mData = malloc(_recorderBufferList.mBuffers[i].mDataByteSize);
					}
				}
			}
			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

			// -------------------------------------------------------------------------------------------------------------
			// Initialise

			status = AudioUnitInitialize(_audioUnit);
			NSAssert(status == noErr, @"Failed AudioUnitInitialize");
		}
		@catch (NSException * e)
		{
			NSLog (@"%@", e.reason);
			[self shutdown];
		}
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// A useful method to get the current audio route ...
// ------------------------------------------------------------------------------------------------------------------------------------
-(NSString *) currentAudioRoute
{
	CFStringRef route;
	UInt32 propertySize = sizeof (CFStringRef);

	if (AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &propertySize, &route)==0)
	{
		NSLog (@"Current audio route : %@", (NSString *)route);
		return (NSString *)route;  // this is called "toll-free bridging"
	}
	else
	{
		// most likely we are in simulator
		return @"Speaker";
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// When you’re ready to start
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) start
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		if (!_started)
		{
			if (AudioOutputUnitStart(_audioUnit) != noErr) // Takes a long time
			{
				NSLog (@"Failed AudioOutputUnitStart");
			}
			else
			{
				_started = YES;
			}
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// When you want to stop
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) stop
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		if (_started)
		{
			if (AudioOutputUnitStop(_audioUnit) != noErr)
			{
				NSLog (@"Failed AudioOutputUnitStop");
			}
			else
			{
				_started = NO;
			}
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// shut down the RemoteIO without causing any unstability in the program
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) shutdown
{
	[self stop];

	if (AudioUnitUninitialize(_audioUnit) != noErr) NSLog (@"Failed AudioUnitUninitialize");

	if (AudioComponentInstanceDispose(_audioUnit) != noErr) NSLog (@"Failed AudioComponentInstanceDispose");
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Destructeur
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	//	when you synthesize a property, the compiler only creates any absent accessor methods. There is no direct interaction with the
	//	dealloc method-properties are not automatically released for you !

	if (!IsAutoAllocRecordBuffer)
	{
		for (UInt32 i=0; i<_recorderBufferList.mNumberBuffers; i++)
		{
			free(_recorderBufferList.mBuffers[i].mData);
		}
	}

	[self shutdown];
	[super dealloc];
}

@end
