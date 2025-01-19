//
//  vDspFFTHandler.m
//  RacingTach
//
//  Created by Gérald GUIONY on 30/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "vDspFundamentalFreqFinder.h"

#include "SignalProcessing.h"


@implementation vDspFundamentalFreqFinder

// Entrées
@synthesize nbPoints				= _nbPoints;
@synthesize lowFreq					= _lowFreq;
@synthesize highFreq				= _highFreq;
@synthesize fundVsHarmonicPercent	= _fundVsHarmonicPercent;

// Sorties
@synthesize	nbOutputElem			= _nbOutputElem;
@synthesize	fundamentalFreq			= _fundamentalFreq;

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur par défaut
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithNbPoints: (UInt32)nbPoints andLowFreq: (double)lFreq andHighFreq: (double)hFreq andFundVsHarmonicPercent: (UInt8)fundHarmonicPercent
{
	self = [super init];
	if (self != nil)
	{
		self.nbPoints = nbPoints;		// puissance de 2
		self.lowFreq = lFreq;
		self.highFreq = hFreq;
		self.fundVsHarmonicPercent = fundHarmonicPercent;

		_nbOutputElem = 0;
		_fundamentalFreq = 0.0;

		// Set the size of FFT.
		// Parameter log2n must equal or exceed the largest power of 2 that any subsequent function processes using the weights array.
		UInt32 log2n = (UInt32) log2f (nbPoints); // ici on a 2^log2n = nbPoints si nbPoints est une puissance de 2, sinon 2^log2n <= nbPoints
		UInt32 n = 1 << log2n; 			 		  // ici on a 2^log2n = n
		UInt32 nOver2 = n / 2;

		// On s'assure que nbPoints est bien une puissance de 2
		NSAssert(nbPoints == n, @"nbPoints is not a power of two !!!");

		_complexData.realp = (kOutputDataType *) malloc (nOver2 * sizeof(kOutputDataType));
		_complexData.imagp = (kOutputDataType *) malloc (nOver2 * sizeof(kOutputDataType));

		// Set up the required memory for the FFT routines and check its availability.
		_fftSetup = vDSP_create_fftsetup (log2n, FFT_RADIX2);
		if (_fftSetup == NULL)
		{
			NSLog (@"FFT_Setup failed to allocate enough memory for the real FFT.");
			exit(0);
		}

		// Allocation de la fenetre de Hamming
		_windowFilter = (kOutputDataType *) malloc (nbPoints * sizeof(kOutputDataType));

		// Creates a single-precision Hamming window.
		//vDSP_hamm_window (_windowFilter, _nbPoints, 0);
		// Creates a single-precision Hanning window.
		//vDSP_hann_window (_windowFilter, _nbPoints, vDSP_HANN_NORM);
		// Creates a single-precision Blackman window.
		vDSP_blkman_window (_windowFilter, _nbPoints, 0);
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Setter de la borne supérieure de l'interval de recherche de la période fondamentale
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setThresholdPercent: (UInt8)fundHarmonicPercent
{
	if ((fundHarmonicPercent > 0) && (fundHarmonicPercent <= 100))
	{
		_fundVsHarmonicPercent = fundHarmonicPercent;
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Calcul de la FFT et recherche de la période fondamentale
// outputBuffer : The buffer that stores the calculated values. It is exactly half the size of the input buffer.
//
// Help :
// http://www.ffnn.nl/pages/articles/apple-mac-os-x/vectorizing-with-vdsp-and-veclib.php
// http://developer.apple.com/library/mac/#documentation/Accelerate/Reference/vDSPRef/Reference/reference.html
// Alignement : http://www.gamasutra.com/view/feature/3942/data_alignment_part_1.php?print=1
//
// ----------
// Real FFT
// ----------
// The real FFT, unlike the complex FFT, may possibly have to use two transformation functions, one before the FFT call and one after.
// This is if the input array is not in the even-odd split configuration.
//
// A real array A = {A[0],...,A[n]} has to be transformed into an even-odd array AEvenOdd = {A[0],A[2],...,A[n-1],A[1],A[3],...A[n]}
// via the vDSP_ctoz call.
//
// The result of the real FFT of AEvenOdd of dimension n is a complex array of the dimension 2n, with a special format:
// {[DC,0],C[1],C[2],...,C[n/2],[NY,0],Cc[n/2],...,Cc[2],Cc[1]}
// where
// 1. DC and NY are the dc and nyquist components (real valued),
// 2. C is complex in a split representation,
// 3. Cc is the complex conjugate of C in a split representation.
//
// For an n size real array A, the complex results require 2n spaces.  In order to fit the 2n size result into an n size  input and
// since the complex conjugates are duplicate information, the  real FFT produces its results as follows:
// {[DC,NY],C[1],C[2],...,C[n/2]}.
//
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) computeWithInputData: (kInputDataType *)signalBuffer toOutputData: (kOutputDataType *)outputBuffer
{
	UInt32 nOver2 = _nbPoints / 2;
	float maxSpectrum;

	// Copie du buffer audio (int16 *) dans le buffer d'entrée FFT (float *)
	// Converts an array of signed 16-bit integers to single-precision floating-point values.
	vDSP_vflt16 (signalBuffer, 1, outputBuffer, 1, _nbPoints);

	// Multiplies vector A by vector B and leaves the result in vector C; single precision.
	vDSP_vmul (outputBuffer, 1, _windowFilter, 1, outputBuffer, 1, _nbPoints);

	// Convert real input to even-odd :
	// Look at the real signal as an interleaved complex vector by casting it. Then call the transformation function vDSP_ctoz to
    // get a split complex vector, which for a real signal, divides into an even-odd configuration.
    vDSP_ctoz ((COMPLEX *) outputBuffer, 2, &_complexData, 1, nOver2); // stride 2, as each complex # is 2 floats

    // Calculate the FFT
    vDSP_fft_zrip (_fftSetup, &_complexData, 1, (UInt32) log2f(_nbPoints), FFT_FORWARD);

	// Normalize ...
	// Verify correctness of the results, but first scale it by 2n.
    //float scale = (float) (1.0 / (2.0 * _nbPoints));

	// Multiplies vector signal1 by scalar signal2 and leaves the result in vector result; single precision
    //vDSP_vsmul(_complexData.realp, 1, &scale, _complexData.realp, 1, nOver2);
    //vDSP_vsmul(_complexData.imagp, 1, &scale, _complexData.imagp, 1, nOver2);

	// Convert the complex data into something usable
    // spectrumData is also a (float*) of size mNumFrequencies
    vDSP_zvabs (&_complexData, 1, outputBuffer, 1, nOver2);

	// Valeur maximale du spectre
	// Vector maximum value; single precision.
	vDSP_maxv (&(outputBuffer[(int)_lowFreq]), 1, &maxSpectrum, _highFreq - _lowFreq + 1);

	// Rempli sur [0; _lowFreq - 1] le vecteur de sorties avec la valeur maxSpectrum
	// Vector fill; single precision.
	vDSP_vfill (&maxSpectrum, outputBuffer, 1, _lowFreq);

	// Multiplie par -1 les valeur sur [_lowFreq; _highFreq]
	// Vector negative values; single precision.
	vDSP_vneg (&(outputBuffer[(int)_lowFreq]), 1, &(outputBuffer[(int)_lowFreq]), 1, _highFreq - _lowFreq + 1);

	// Additionne maxSpectrum sur [_lowFreq; _highFreq]
	// Vector scalar add; single precision.
	vDSP_vsadd (&(outputBuffer[(int)_lowFreq]), 1, &maxSpectrum, &(outputBuffer[(int)_lowFreq]), 1, _highFreq - _lowFreq + 1);

	// Trouve l'index du premier pic : la fréquence fondamentale
	_fundamentalFreq = getFundamentalPeriod (outputBuffer, _lowFreq, _highFreq, _fundVsHarmonicPercent / 100.0);

	_nbOutputElem = _highFreq;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Destructeur
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	//	when you synthesize a property, the compiler only creates any absent accessor methods. There is no direct interaction with the
	//	dealloc method â€” properties are not automatically released for you !

	vDSP_destroy_fftsetup (_fftSetup);

    free (_complexData.realp);
    free (_complexData.imagp);

	free (_windowFilter);

	[super dealloc];
}

@end
