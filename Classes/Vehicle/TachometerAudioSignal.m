//
//  GLTachometerAudioSignal.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "TachometerAudioSignal.h"

#include "AntiPiracy.h"

#define MIN_ELAPSED_TIME		0.050			// 25 ms

#define kMinRpm					600
#define kMaxRpm					8000
#define kShiftLight				kMaxRpm
#define kSparkPerRev			2.0

#define kFundVsHarmonicPercent	70				// 20, 25, 33
#define kMaxUpdateWithoutAudio	20


// En 44100 hz : il faut une plage minimum d'a peu prés 16000 points (= kNumPoints * kSamplingStep), 32000 pour une fft plus précise
#define kNumPoints				16384			// 2048, 4096, 8192, 16384, 32768, 65536 Une puissance de 2 ...
#define kSamplingStep			2				// 1 donnée audio sur 'kSamplingStep' est pris en compte pour la détection de la période


// Tableau des limites maximales des RPM suivant le type de compte-tours (voiture, moto, voiture radiocommandée ...)
static UInt32 TachoRpmLimitTab [] = { 10000, 15000, 50000, 100000 };

// ------------------------------------------------------------------------------------------------------------------------------------
// Les méthodes privées de cette classe ...
// ------------------------------------------------------------------------------------------------------------------------------------
@interface TachometerAudioSignal (private)

-(double) rpmToRateRatio;
-(void) allocBuffers;
-(void) deleteBuffers;

@end


@implementation TachometerAudioSignal

@synthesize audioSignalData		= _audioSignalData;
@synthesize spectrumOutputData = _spectrumOutputData;

@synthesize fundFreqFinder		= _fundFreqFinder;

@synthesize numPoints			= _numPoints;
@synthesize shiftLightRPM		= _shiftLightRPM;
@synthesize shiftLightSound		= _shiftLightSound;
@synthesize sparksPerRev		= _sparksPerRev;

@synthesize headsetPluggedIn	= _headsetPluggedIn;

@dynamic lowRPM;
@dynamic highRPM;
@dynamic fundVsHarmonicPercent;

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur par défaut
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) init
{
	// Par défault
	return [self initWithSparksPerRev: kSparkPerRev andLowRPM: kMinRpm andHighRPM: kMaxRpm
			 andFundVsHarmonicPercent: kFundVsHarmonicPercent andShiftLightRPM: kShiftLight andShiftLightSound: NO];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithSparksPerRev: (float)sparksPerRev	andLowRPM: (UInt32)loRPM andHighRPM: (UInt32)hiRPM
	andFundVsHarmonicPercent: (UInt8)fundHarmonicPercent andShiftLightRPM: (UInt32)shiftLightRpm andShiftLightSound: (BOOL)shiftLightSound
{
	self = [super init];
	if (self != nil)
	{
		_audioSignalData = NULL;
		_spectrumOutputData = NULL;
		_lastAudioNbPointRemains = 0;
		_updatedWithoutGetAudio = 0;
		_lastTime = 0;

		// Allocation des tableaux
		self.numPoints = kNumPoints;

		// Nombre d'étincelle par tour moteur
		self.sparksPerRev = sparksPerRev;

		// Le régime moteur du shift-light pour l'alarme de changement de vitesse
		self.shiftLightRPM = shiftLightRpm;

		// Son du shift-light activé ?
		self.shiftLightSound = shiftLightSound;

		// Ecouteurs connectés ?
		self.headsetPluggedIn = NO;

		_fundFreqFinder = [[vDspFundamentalFreqFinder alloc] initWithNbPoints: self.numPoints
																   andLowFreq: [self rpmToRate: loRPM]
																  andHighFreq: [self rpmToRate: hiRPM]
													 andFundVsHarmonicPercent: fundHarmonicPercent];

		// Initialize l'audio
		_audioRemote = [[AudioRemoteIO alloc] initWithAudioDelegate: self
											   andIsRemoteRecording: true
												andIsRemotePlayback: false];
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Delivers the latest audio data to the delegate
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) getAudioBufferList: (AudioBufferList *)ioData
{
	// ------------------------------------------------------------------------------------
	// Ajout des nouvelles données dans le buffer du signal audio et le buffer 'Vertices'

	// Si dans ioData nous avons les données audio en stéréo => on ne considère qu'un seul channel soit une donnée sur deux
	// static UInt16 SamplingStep = kSamplingStep * 2;	// Si kAudioDataType = SInt8 ou SInt16 ???
	// Si dans ioData nous avons les données audio en mono => on ne considère le seul channel soit toutes les données
	static UInt16 SamplingStep = kSamplingStep;		// Si kAudioDataType = SInt8 ou SInt16 ???

	UInt16 nbDatas = ioData->mBuffers[0].mDataByteSize / sizeof(kAudioDataType);
	nbDatas -= _lastAudioNbPointRemains;

	// Nombre de points a prendre en compte
	UInt16 nbPointsToAdd = (nbDatas / SamplingStep);
	UInt16 nbPointsRemains = 0;

	if (nbPointsToAdd > _numPoints)
	{
		nbPointsToAdd = _numPoints;
	}
	else
	{
		// Le reste de la division
		nbPointsRemains = (nbDatas % SamplingStep);
		if (nbPointsRemains > 0)
		{
			nbPointsToAdd += 1;
			nbPointsRemains = SamplingStep - nbPointsRemains;
		}
	}

	kAudioDataType * pData = (kAudioDataType *)(ioData->mBuffers[0].mData);
	kAudioDataType * pAudioData = &(_audioSignalData [_numPoints - nbPointsToAdd]);

	pData += _lastAudioNbPointRemains;

	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		// Cycle the points in our draw buffer so that they age and fade. The oldest points are discarded.
		memmove (&(_audioSignalData[0]), &(_audioSignalData[nbPointsToAdd]), (_numPoints - nbPointsToAdd) * sizeof(kAudioDataType));

		// Copie des nouvelles données
		if (SamplingStep == 1)
		{
			// memcpy a un comportement indéterminé si les deux adresses se chevauchent et ont donc des parties communes.
			// Dans ce cas il est préférable d'utiliser la fonction c_memmove !
			memcpy (pAudioData, pData, nbPointsToAdd * sizeof(kAudioDataType));
		}
		else
		{
			while (nbPointsToAdd--)
			{
				*pAudioData++ = *pData;

				// Dans ioData nous avons les données audio en stéréo ou mono
				pData += SamplingStep;
			}
		}
	}

	_lastAudioNbPointRemains = nbPointsRemains;
	_updatedWithoutGetAudio = 0;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Delegate creates the audio data
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setAudioBufferList: (AudioBufferList *)ioData
{
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Setter du nombre de points
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setNumPoints: (UInt32)numPoints
{
	if (numPoints > 0)
	{
		_numPoints = numPoints;
		[self allocBuffers];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Setter du nombre d'étincelles par tours
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setSparksPerRev: (float)sparksPerRev
{
	if ((sparksPerRev > 0) && (sparksPerRev < 10))
	{
		_sparksPerRev = sparksPerRev;

		if (_fundFreqFinder != nil)
		{
			_fundFreqFinder.lowFreq = [self rpmToRate: kMinRpm];
			_fundFreqFinder.highFreq = [self rpmToRate: kMaxRpm];
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Delegate Method
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) headsetPlugged: (BOOL)pluggedIn
{
	_headsetPluggedIn = pluggedIn;

	// Relancer l'acquisition ?
//	[self stopAcquisition];
//	[self startAcquisition];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// When you’re ready to start
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) startAcquisition
{
	checkPiracy ();

	_lastAudioNbPointRemains = 0;

	// Start the audio data acquisition
	[_audioRemote start];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// When you want to stop
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) stopAcquisition
{
	// Stop the audio data acquisition
	[_audioRemote stop];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour des valeurs calculées avec les nouvelles données audio
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) update
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		memcpy (_audioSignalDataCopy, _audioSignalData, _numPoints * sizeof(kAudioDataType));
	}

	// Calcul de l'autocorrelation
	[_fundFreqFinder computeWithInputData: _audioSignalDataCopy toOutputData: _spectrumOutputData];

	// Contournement d'un bug : Il arrive que l'acquisition de l'audio par l'audioremote s'arrete de lui même...
	_updatedWithoutGetAudio++;
	if (_updatedWithoutGetAudio >= kMaxUpdateWithoutAudio)
	{
		NSLog(@"Restart the AudioRemote !!!");

		// Restart the AudioRemote
		[self stopAcquisition];
		[self startAcquisition];

		_updatedWithoutGetAudio = 0;
	}

//#if TARGET_IPHONE_SIMULATOR
//	// Ralentissement pour mieux simuler l'iphone avec le simulateur ...
//	[NSThread sleepForTimeInterval: 0.025];
//#endif

	// Ralentissement pour mieux simuler le temps de traitement entre l'iphone et le simulateur et les iphone entre eux (3G / 4G ...)
	// laisse également du temps au processeur

	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval elapsedTime = currentTime - _lastTime;
	if (elapsedTime < MIN_ELAPSED_TIME)
	{
		[NSThread sleepForTimeInterval: (MIN_ELAPSED_TIME - elapsedTime)];
	}

	checkPiracy ();

	_lastTime = [NSDate timeIntervalSinceReferenceDate];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Rapport de convertion régime moteur / tau
// ------------------------------------------------------------------------------------------------------------------------------------
-(double) rpmToRateRatio
{
	return ((60.0 * kSampleRate) / (_numPoints * _sparksPerRev * kSamplingStep));
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Convertion d'un régime moteur en une valeur de nombre de points signal audio
// ------------------------------------------------------------------------------------------------------------------------------------
-(double) rpmToRate: (double)rpm
{
	return (rpm / [self rpmToRateRatio]);
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Convertion d'un nombre de points du signal audio en une valeur du régime moteur
// ------------------------------------------------------------------------------------------------------------------------------------
-(double) rateToRpm: (double)rate
{
	// Il y a kSampleRate (44100) valeurs relevées par seconde pour le signal audio
	// On a _sparksPerRev étincelles par tour moteur

	// Temps
	// -------------------------------------
	// kSampleRate			-> 1 seconde
	// rate	* kSamplingStep	-> X secondes
	// X = (rate * kSamplingStep) / kSampleRate;

	// 1 étincelle toutes les 'X' secondes
	// donc (1 / _sparksPerRev) tours moteur toutes les 'X' secondes
	// donc (1 / ( _sparksPerRev * X)) tours par seconde
	// soit ( kSampleRate / ( _sparksPerRev * rate * kSamplingStep))

	// en minutes : (60.0 * kSampleRate) / (_sparksPerRev * kSamplingStep)

	UInt16 tabLen = sizeof(TachoRpmLimitTab) / sizeof(UInt16);

	// Maximum possible
	if (rate > [self rpmToRate: TachoRpmLimitTab[tabLen-1]])
		return TachoRpmLimitTab[tabLen-1];

	return (rate * [self rpmToRateRatio]);
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Conversion de la valeur en fréquence (ou vice-versa)
// ------------------------------------------------------------------------------------------------------------------------------------
-(double) valueToRate: (double)value
{
	if (value != 0)
		return (((double)_numPoints) / value);

	return 0.0;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le régime moteur courant
// ------------------------------------------------------------------------------------------------------------------------------------
-(UInt32) getCurrentRPM
{
	return ((UInt32) nearbyint ([self rateToRpm: _fundFreqFinder.fundamentalFreq]));
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le régime moteur min Setter
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setLowRPM: (UInt32)rpm
{
	_fundFreqFinder.lowFreq = [self rpmToRate: rpm];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le régime moteur min Getter
// ------------------------------------------------------------------------------------------------------------------------------------
-(UInt32) lowRPM
{
	return ((UInt32) nearbyint ([self rateToRpm: _fundFreqFinder.lowFreq]));
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le régime moteur min Setter
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setHighRPM: (UInt32)rpm
{
	_fundFreqFinder.highFreq = [self rpmToRate: rpm];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le régime moteur max Getter
// ------------------------------------------------------------------------------------------------------------------------------------
-(UInt32) highRPM
{
	return ((UInt32) nearbyint ([self rateToRpm: _fundFreqFinder.highFreq]));
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Getter
// ------------------------------------------------------------------------------------------------------------------------------------
-(UInt8) fundVsHarmonicPercent
{
	return _fundFreqFinder.fundVsHarmonicPercent;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Setter
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setFundVsHarmonicPercent: (UInt8)fundHarmonicPercent
{
	_fundFreqFinder.fundVsHarmonicPercent = fundHarmonicPercent;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// L'alarme shift light doit elle se déclencher ?
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) isShiftLightAlarm
{
	return ([self getCurrentRPM] > [self shiftLightRPM]);
}

// ------------------------------------------------------------------------------------------------------------------------------------
// La valeur limite maximale de l'affichage du compte tours en fonction de la valeur du régime rpm.
// Cette valeur différe suivant le type de compte-tours (voiture, moto, voiture radiocommandée ...)
// ------------------------------------------------------------------------------------------------------------------------------------
+(UInt32) getRpmLimitWithRpm: (float)rpm
{
	UInt8 tabLen = sizeof(TachoRpmLimitTab) / sizeof(TachoRpmLimitTab[0]);

	// Retourne le max des limites des types de compteurs
	if (rpm < 0) return TachoRpmLimitTab[tabLen-1];

	for (UInt8 i=0; i<tabLen; i++)
	{
		if (rpm < TachoRpmLimitTab[i]) return TachoRpmLimitTab[i];
	}

	// Par defaut retourne la valeur limite maximale
	return TachoRpmLimitTab[tabLen-1];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// La valeur limite maximale de l'affichage du compte tours en fonction de la valeur max du régime rpm.
// ------------------------------------------------------------------------------------------------------------------------------------
-(UInt32) getRpmLimit
{
	return [TachometerAudioSignal getRpmLimitWithRpm: [self rateToRpm: _fundFreqFinder.highFreq]];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Allocation des buffers internes
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) allocBuffers
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		[self deleteBuffers];

		_audioSignalData = (kAudioDataType *) malloc (_numPoints * sizeof (kAudioDataType)); // Allocation du tableau des data audio
		_audioSignalDataCopy = (kAudioDataType *) malloc (_numPoints * sizeof (kAudioDataType));
		_spectrumOutputData = (kOutputDataType *) malloc (_numPoints * sizeof (kOutputDataType)); // Allocation du tableau Yin ou autocorr

		// Initialize le buffer des données audio à 0 (RAZ)
		bzero (_audioSignalData, _numPoints * sizeof (kAudioDataType));
		bzero (_audioSignalDataCopy, _numPoints * sizeof (kAudioDataType));
		bzero (_spectrumOutputData, _numPoints * sizeof (kOutputDataType));
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Libération des buffers
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) deleteBuffers
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		if (_audioSignalData != NULL) free (_audioSignalData);
		if (_audioSignalDataCopy != NULL) free (_audioSignalDataCopy);
		if (_spectrumOutputData != NULL) free (_spectrumOutputData);
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	// Stop the audio
	[_audioRemote stop];
	[_audioRemote release];

	[_fundFreqFinder release];

	[self deleteBuffers];

    [super dealloc];
}

@end
