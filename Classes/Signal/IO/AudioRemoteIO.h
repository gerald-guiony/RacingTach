//
//  AudioRemoteIO.h
//  RacingTach
//
//  Created by Gérald GUIONY on 05/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioToolbox/AudioToolbox.h"

//#include <AudioUnit/AudioUnit.h>

#define kAudioDataType kInputDataType	// SInt16

#define kSampleRate 	44100
//#define kSampleRate 	8000

//#define kLatency 		0.003			// In seconds (minimum possible sur device)
#define kLatency 		0

// ------------------------------------------------------------------------------------------------------------------------------------
// AudioRemoteIODelegate Protocol Reference
//
// The AudioRemoteIODelegate protocol defines a method for receiving audio data from the system and a method for sending audio data to
// the system.
//
// Protocols are not classes themselves. They simply define an interface that other objects are responsible for implementing. When you
// implement the methods of a protocol in one of your classes, your class is said to conform to that protocol.
// Protocols are used frequently to specify the interface for delegate objects. A delegate object is an object that acts on behalf of,
// or in coordination with, another object.
// Protocols do not have a parent class and they do not define instance variables.
//
// If you use any of the NSObject protocol methods such as retain, release, class, classname, the compiler will give you warnings unless
// your Protocol also includes the NSObject protocol. NSObject is not only a class but there is also an NSObject protocol that declares
// the same methods as the class
// ------------------------------------------------------------------------------------------------------------------------------------
@protocol AudioRemoteIODelegate <NSObject>

// Delivers the latest audio data to the delegate
-(void) getAudioBufferList: (AudioBufferList *)ioData;

// Delegate creates the audio data
-(void) setAudioBufferList: (AudioBufferList *)ioData;

@optional
// Les écouteurs avec micro sont ils connectés ?
-(void) headsetPlugged: (BOOL)pluggedIn;

@end


// ------------------------------------------------------------------------------------------------------------------------------------
// Analyse audio with RemoteIO : it lets us drill down to sound samples and sound analysis
//
// http://www.iwillapps.com/wordpress/?m=200906
// http://atastypixel.com/blog/2008/11/04/using-remoteio-audio-unit/
// http://sites.google.com/site/iphonecoreaudiodevelopment/remoteio-playback
// http://developer.apple.com/mac/library/technotes/tn2002/tn2091.html
// http://snowymonkey.wordpress.com/2010/02/06/my-iphone-audio-code/
// http://code.google.com/p/ofxiphone/source/browse/trunk/src/ofxiPhoneSoundStream.mm?spec=svn41&r=41
// http://pastebin.com/m55fd29d6
// ------------------------------------------------------------------------------------------------------------------------------------
@interface AudioRemoteIO : NSObject
{
	// The Audio Remote IO delegate
	id <AudioRemoteIODelegate>		_audioDelegate;

	// The rioUnit is simply an identifier for the recording unit we have started
	AudioUnit 						_audioUnit;

	// Defines information like the sample rate
	AudioStreamBasicDescription 	_audioFormat;

	// Buffer for the recorder
	AudioBufferList  				_recorderBufferList;

	// Started ?
	BOOL							_started;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

// It's a standard to not retain the delegate but only assign it :
// Because in most cases, the delegate owns (and therefore retains) the delegating object. If both objects retained each other, the
// delegate would not be deallocated when it is released by its own parent (because its retain count is still > 0). In the end, both
// delegate and delegating object will never be deallocated.
@property (nonatomic, assign) id <AudioRemoteIODelegate>	audioDelegate;		// it's an NSObject but without retain !!!


@property (nonatomic, assign) AudioUnit						audioUnit;			// struct n'est pas un objet
@property (nonatomic, assign) AudioStreamBasicDescription	audioFormat;		// struct n'est pas un objet
@property (nonatomic, assign) AudioBufferList 				recorderBufferList;	// struct n'est pas un objet

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithAudioDelegate: (id <AudioRemoteIODelegate>)audioDelegate andIsRemoteRecording: (BOOL)isRemoteRecording
		andIsRemotePlayback: (BOOL)isRemotePlayback;
-(NSString *) currentAudioRoute;
-(void) start;
-(void) stop;
-(void) shutdown;

@end