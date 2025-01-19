//
//  vDspFFTHandler.h
//  RacingTach
//
//  Created by Gérald GUIONY on 30/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <Accelerate/Accelerate.h>
//#include <vDSP.h>

// ------------------------------------------------------------------------------------------------------------------------------------
//
// Interface objet du calcul de détection de période grâce aux API FFT d'Apple
//
// ------------------------------------------------------------------------------------------------------------------------------------
@interface vDspFundamentalFreqFinder : NSObject
{
	// Entrées
	UInt32				_nbPoints;
	double 				_lowFreq;
	double 				_highFreq;
	UInt8				_fundVsHarmonicPercent;				// The threshold value

	// Données de travail
	//COMPLEX_SPLIT		_complexData;
	DSPSplitComplex 	_complexData;
	FFTSetup 			_fftSetup;
	float *				_windowFilter;


	// Sorties
	UInt16				_nbOutputElem;
	double				_fundamentalPeriod;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

// Entrées
@property (nonatomic, assign) UInt32	nbPoints;
@property (nonatomic, assign) double	lowFreq;
@property (nonatomic, assign) double	highFreq;
@property (nonatomic, assign) UInt8		fundVsHarmonicPercent;

// Sortie
@property (nonatomic, assign, readonly) UInt16 nbOutputElem;
@property (nonatomic, assign, readonly) double fundamentalFreq;

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

-(id) initWithNbPoints: (UInt32)nbPoints andLowFreq: (double)lFreq andHighFreq: (double)hFreq andFundVsHarmonicPercent: (UInt8)fundHarmonicPercent;

-(void) computeWithInputData: (kInputDataType *)signalBuffer toOutputData: (kOutputDataType *)outputBuffer;

@end
