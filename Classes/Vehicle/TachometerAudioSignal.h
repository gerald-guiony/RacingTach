//
//  GLTachometerAudioSignal.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AudioRemoteIO.h"
#import "vDspFundamentalFreqFinder.h"


// ------------------------------------------------------------------------------------------------------------------------------------
// Délégué de l'audio remote IO pour les controlleurs des vues OpenGL 'GLView'
// ------------------------------------------------------------------------------------------------------------------------------------
@interface TachometerAudioSignal : NSObject <AudioRemoteIODelegate>
{
	vDspFundamentalFreqFinder *	_fundFreqFinder; 
	AudioRemoteIO *				_audioRemote;
	
	kAudioDataType *			_audioSignalData;		// Tableau des données du signal audio	
	kAudioDataType *			_audioSignalDataCopy;	
	kOutputDataType *			_spectrumOutputData;	// Tableau de sortie du calcul du spectre du signal

	UInt32						_numPoints;	
	UInt32						_shiftLightRPM;		
	BOOL						_shiftLightSound;	
	float						_sparksPerRev;			// Etincelles par tour : pour un 4 temps à allumage classique, 1 étincelle tous les deux 
														// tours (0.5 par tour), mais pour un allumage à étincelle perdue, il y a une étincelle 
														// par tour
	BOOL						_headsetPluggedIn;
	
	UInt16						_lastAudioNbPointRemains;
	UInt16						_updatedWithoutGetAudio;
	
	NSTimeInterval				_lastTime;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

@property (nonatomic, assign, readonly) kAudioDataType *	audioSignalData;
@property (nonatomic, assign, readonly) kOutputDataType *	spectrumOutputData;

@property (nonatomic, retain, readonly) vDspFundamentalFreqFinder * fundFreqFinder;

@property (nonatomic, assign) UInt32	numPoints;
@property (nonatomic, assign) UInt32	shiftLightRPM;
@property (nonatomic, assign) BOOL		shiftLightSound;
@property (nonatomic, assign) float		sparksPerRev;

@property (nonatomic, assign) BOOL		headsetPluggedIn;

@property (nonatomic, assign) UInt32	lowRPM;
@property (nonatomic, assign) UInt32	highRPM;
@property (nonatomic, assign) UInt8		fundVsHarmonicPercent;

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

-(id) init;
-(id) initWithSparksPerRev: (float)sparksPerRev	andLowRPM: (UInt32)lowRPM andHighRPM: (UInt32)highRPM 
  andFundVsHarmonicPercent: (UInt8)fundHarmonicPercent andShiftLightRPM: (UInt32)shiftLightRpm andShiftLightSound: (BOOL)shiftLightSound;

-(void) startAcquisition;
-(void) stopAcquisition;

-(void) update;

-(double) rpmToRate: (double)rpm;
-(double) rateToRpm: (double)rate;
-(double) valueToRate: (double)value;

-(UInt32) getCurrentRPM;

-(BOOL) isShiftLightAlarm;

+(UInt32) getRpmLimitWithRpm: (float)rpm;
-(UInt32) getRpmLimit;
	
@end
