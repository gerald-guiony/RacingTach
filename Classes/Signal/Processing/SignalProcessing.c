/*
 *  SignalProcessing.c
 *  RacingTach
 *
 *  Created by Gérald GUIONY on 28/06/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>

#include "SignalProcessing.h"

// ------------------------------------------------------------------------------------------------------------------------------------
// Local Extremas extraction
//
// @param inBuffer the array of values
// @param inBufferSize the size of the array of values
// @param heightBuffer the array of local heights
// ------------------------------------------------------------------------------------------------------------------------------------
void searchLocalHeights (kOutputDataType * buffer, UInt16 bufferSize, kOutputDataType * heightBuffer)
{
	// pass 1: left to right
	kOutputDataType up=0, down=0;
	for (UInt16 i=1; i<bufferSize-1; i++)
	{
		kOutputDataType delta = buffer[i]-buffer[i-1];
		if (delta > 0) {down=0; up += delta;}
		if (delta < 0) {up=0; down += delta;}
		heightBuffer[i] = (up > -down) ? up : down;
	}

	// pass 2: right to left
	up=0; down=0;
	for (SInt16 i=bufferSize-2; i>=0; i--)
	{
		kOutputDataType delta = buffer[i]-buffer[i+1];
		if (delta > 0) {down=0; up += delta;}
		if (delta < 0) {up=0; down += delta;}
		if (up < heightBuffer[i]) heightBuffer[i] = up;
		if (down > heightBuffer[i]) heightBuffer[i] = down;
	}

	// Initialisation des extremas du tableau (non renseigné par le calcul)
	heightBuffer [0] = 0;
	heightBuffer [bufferSize-1] = 0;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Recherche d'un minimum local en dessous d'un seuil et à partir d'un index (index)
// ------------------------------------------------------------------------------------------------------------------------------------
UInt16 searchLocalMinimum (kOutputDataType * buffer, UInt16 bufferSize, double threshold, UInt16 * index)
{
	UInt16 i = *index;
	UInt16 newIndex = i;

	// Recherche du mimima local
	while ((i < bufferSize) && (buffer [i] < threshold))
	{
		if (buffer [newIndex] > buffer [i])
		{
			newIndex = i;
		}
		i++;
	}

	// La valeur de i maximale de notre interval de recherche
	*index = i;

	return newIndex;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Recherche de la valeur minimal du signal 'buffer'
// ------------------------------------------------------------------------------------------------------------------------------------
UInt16 searchGlobalMinimum (kOutputDataType * buffer, UInt16 begin, UInt16 end)
{
	UInt16 min = begin;
	kOutputDataType valueForMin = buffer [begin];

	// Minimum du signal sur [begin, end]
	for (UInt16 i = begin; i <= end; i++)
	{
		if (valueForMin > buffer [i])
		{
			min = i;
			valueForMin = buffer [i];
		}
	}
	return min;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Recherche de la valeur maximale du signal 'buffer'
// ------------------------------------------------------------------------------------------------------------------------------------
UInt16 searchGlobalMaximum (kOutputDataType * buffer, UInt16 begin, UInt16 end)
{
	UInt16 max = begin;
	kOutputDataType valueForMax = buffer [begin];

	// Maximum du signal sur [begin, end]
	for (UInt16 i = begin; i <= end; i++)
	{
		if (valueForMax < buffer [i])
		{
			max = i;
			valueForMax = buffer [i];
		}
	}
	return max;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Calcul de la moyenne du signal
// ------------------------------------------------------------------------------------------------------------------------------------
double computeAverage (kOutputDataType * buffer, UInt16 begin, UInt16 end)
{
	double average = 0.0;
	kOutputDataType * pBuffer = buffer + begin;

	while (pBuffer <= buffer + end)
	{
		average += *pBuffer;
		pBuffer++;
	}

	// Moyenne du signal
	return (average / (end - begin + 1));
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Implements step 5 of the YIN paper. It refines the estimated result value
// using parabolic interpolation. This is needed to detect higher
// frequencies more precisely.
//
// @param estimatedResult
//            the estimated result value.
// @return a better, more precise result value.
// ------------------------------------------------------------------------------------------------------------------------------------
double parabolicInterpolation (kOutputDataType * buffer, UInt16 begin, UInt16 end, UInt16 estimatedResult)
{
	kOutputDataType s0, s1, s2;

	UInt16 x0 = (estimatedResult - 1 >= begin) ? estimatedResult - 1 : estimatedResult;
	UInt16 x2 = (estimatedResult + 1 <= end)   ? estimatedResult + 1 : estimatedResult;

	if (x0 == estimatedResult)
		return (buffer [estimatedResult] <= buffer [x2]) ? estimatedResult : x2;

	if (x2 == estimatedResult)
		return (buffer [estimatedResult] <= buffer [x0]) ? estimatedResult : x0;

	s0 = buffer [x0];
	s1 = buffer [estimatedResult];
	s2 = buffer [x2];

	// fixed AUBIO implementation, thanks to Karl Helgason:
	// (2.0f * s1 - s2 - s0) was incorrectly multiplied with -1
	double div = 2.0 * s1 - s2 - s0;
	if (div != 0)
	{
		double result = estimatedResult + 0.5 * (s2 - s0 ) / div;
		if ((x0 <= result) && (result <= x2))
			return result;
	}

	return estimatedResult;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Lisse le résultat par rapport au résultat précédent
// ------------------------------------------------------------------------------------------------------------------------------------
#define STEP_DIV				50.0
// ------------------------------------------------------------------------------------------------------------------------------------
double smoothStepResult (double result, double lastResult, UInt16 begin, UInt16 end)
{
	// Pas maximal par rapport au dernier résultat
	double maxStep = (end - begin) / STEP_DIV;

	// Pondération du pas par rapport au dernier résultat
	if (maxStep > 0)
	{
		if (fabs (result - lastResult) > maxStep)
		{
			result = (result > lastResult) ? (lastResult + maxStep) : (lastResult - maxStep);
		}
	}

	return result;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Implements step 4 of the YIN paper
// Prise en compte éventuel du dernier résultat
// ------------------------------------------------------------------------------------------------------------------------------------
UInt16 minAbsoluteThreshold (kOutputDataType * buffer, UInt16 begin, UInt16 end, double threshold, UInt16 lastResult, bool isTrustLevel)
{
	// --------------------------------------------------------------------------------------------------------------------------------
	// Recherche des premiers minima locaux a partir de begin

	bool minTauFound = false;

	UInt16	firstMinTau = begin,
	newMinTau			= begin,
	tau					= begin;

	// Tant que l'on atteind pas la fin
	while (tau < end)
	{
		// Tant que l'on est pas sous le seuil
		while ((tau < end) && (buffer [tau] > threshold))
		{
			tau++;
		}

		if (tau >= end) break;

		// Si on a pas encore trouvé de candidat
		if (!minTauFound)
		{
			minTauFound = true;

			// Recherche du mimima local
			newMinTau = firstMinTau = searchLocalMinimum (buffer, end, threshold, &tau);
		}
		else
		{
			// Recherche du mimima local
			UInt16 minTau = searchLocalMinimum (buffer, end, threshold, &tau);

			// La valeur est elle plus proche de la valeur trouvée précédemment ?
			// Si oui on met a jour newMinTau
			if (abs (minTau - lastResult) < abs (newMinTau - lastResult))
			{
				newMinTau = minTau;
			}
		}

		tau++;
	}

	// --------------------------------------------------------------------------------------------------------------------------------
	// Controle des erreurs

	UInt16 result;

	if (minTauFound)
	{
		if (firstMinTau == newMinTau)
		{
			// Le premier pic trouvé est le pic le plus proche de la valeur trouvée précédement
			result = firstMinTau;
		}
		else
		{
			// Le premier pic trouvé n'est pas le pic le plus proche de la valeur trouvée précédement
			result = isTrustLevel ? newMinTau : firstMinTau;
		}
	}
	else
	{
		// If no period has been under the threshold so we used the global minimum
		result = searchGlobalMinimum (buffer, begin, end);
	}

	return result;
}


// ------------------------------------------------------------------------------------------------------------------------------------
// Implements step 4 of the YIN paper
// Prise en compte éventuel du dernier résultat
// ------------------------------------------------------------------------------------------------------------------------------------
#define COEF_NEW_BEGIN			0.4			// 0.4 ou 0.6 ?
#define COEF_NEW_END			1.6			// 1.4 ou 1.8 ?

#define MAX_TRUST_LEVEL			200
#define MIN_TRUST_LEVEL			50

#define DEC_TRUST_LEVEL(X)		if (X > 0) X--
#define INC_TRUST_LEVEL(X)		if (X < MAX_TRUST_LEVEL) X++
#define TRUST_LEVEL_OK(X)		(X > MIN_TRUST_LEVEL)

#define GLOBAL_MAX_THRESHOLD	1
#define AVERAGE_THRESHOLD		2
#define MAX_THRESHOLD			AVERAGE_THRESHOLD 				// GLOBAL_MAX_THRESHOLD ou AVERAGE_THRESHOLD
// ------------------------------------------------------------------------------------------------------------------------------------
UInt16 minThresholdTrustLevel (kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio)
{
	static UInt16 trustLevel = 0;

	static UInt16 lastResult = 0;
	static UInt16 lastResultGlobal = 0;
	static UInt16 lastResultLocal = 0;

	if (lastResult == 0) lastResult = begin;
	if (lastResultGlobal == 0) lastResultGlobal = begin;
	if (lastResultLocal == 0) lastResultLocal = begin;

	// Seuil de la freq (index) à partir duquel on a presque plus de bruit
	double noiseThreshold = begin + ((end - begin) / 8.0);

	if (lastResult < noiseThreshold) trustLevel = 0;

	// --------------------------------------------------------------------------------------------------------------------------------
	// Définition du seuil

#if   MAX_THRESHOLD == GLOBAL_MAX_THRESHOLD
	// Le seuil maximum est la valeur maximale moins un pourcentage de la diff entre cette valeur et le minimum de la courbe
	kOutputDataType thresholdMax = buffer [searchGlobalMaximum (buffer, begin, end)];

#elif MAX_THRESHOLD == AVERAGE_THRESHOLD
	// Le seuil maximum est la valeur moyenne moins un pourcentage de la diff entre cette valeur et le minimum de la courbe
	kOutputDataType thresholdMax = computeAverage (buffer, begin, end);

#endif

	double threshold = thresholdMax - fundHarmonicRatio * (thresholdMax - buffer [searchGlobalMinimum (buffer, begin, end)]);

	// --------------------------------------------------------------------------------------------------------------------------------
	// Recherche sur l'interval complet [begin, end]

	lastResultGlobal = minAbsoluteThreshold (buffer, begin, end, threshold, lastResultGlobal, TRUST_LEVEL_OK(trustLevel));

	// --------------------------------------------------------------------------------------------------------------------------------
	// Recherche sur un interval restreind autour du dernier résultat

	// Redefinition des valeurs de begin et end par rapport au dernier résultat
	// Essayer d'affiner la recherche sur un interval plus petit

	// Parfois la première harmonique est plus grande que la fondamentale donc il faut au moins commencer à la moitié de la dernière
	// valeur trouvée au cas où celle-ci serait l'harmonique (valeur erronée)
	UInt16 newBegin = nearbyint (COEF_NEW_BEGIN * lastResult);
	if ((newBegin > begin) && (newBegin < end))
		begin = newBegin;

	// Evitons de tomber sur la première harmonique qui suit ...
	UInt16 newEnd = nearbyint (COEF_NEW_END * lastResult);
	if ((newEnd > begin) && (newEnd < end))
		end = newEnd;

	lastResultLocal = minAbsoluteThreshold (buffer, begin, end, threshold, lastResultLocal, TRUST_LEVEL_OK(trustLevel));

	// --------------------------------------------------------------------------------------------------------------------------------
	//

	if (lastResultLocal == lastResultGlobal)
	{
		INC_TRUST_LEVEL (trustLevel);
	}
	else
	{
		DEC_TRUST_LEVEL (trustLevel);
	}

	// pour debug
	buffer[0] = trustLevel * thresholdMax / MAX_TRUST_LEVEL;

	lastResult = TRUST_LEVEL_OK(trustLevel) ? lastResultLocal : lastResultGlobal;

	return lastResult;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Recherche de la période ou fréquence fondamentale du buffer contenant le spectre inversé (pic vers le bas) du signal
// ------------------------------------------------------------------------------------------------------------------------------------
double getFundamentalPeriod (kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio)
{
	static double lastResult = 0;
	double result;

	if (lastResult == 0) lastResult = begin;

	result = minThresholdTrustLevel	(buffer, begin, end, fundHarmonicRatio);
	result = parabolicInterpolation	(buffer, begin, end, result);
	result = smoothStepResult		(result, lastResult, begin, end);

	// Mise à jour de la valeur pour la prochaine recherche
	lastResult = result;

	return result;
}






#define MAX_POTENTIAL_HARMONICS 10

typedef struct
{
	UInt16			freq;
	kOutputDataType peak;
} POTENTIAL_HARMONIC ;

typedef struct
{
	UInt16			len;
	double			score;
} GAP;


UInt16 findFundPeriodWithHarmonics (POTENTIAL_HARMONIC * pH, UInt16 phCount)
{
	// enumerate GAPS
    static GAP gap [ MAX_POTENTIAL_HARMONICS ];

    UInt16 gaps = phCount;

    gap[0].len = pH[0].freq;
    for (UInt16 i=1; i < gaps; i++)
    {
        gap[i].len = pH[i].freq - pH[i-1].freq;
    }

    for (UInt16 i=0; i < gaps; i++)
        gap[i].score = 0.;

    // find best scoring gap
    for (UInt16 i=0; i < gaps; i++)
	{
		float a = gap[i].len;

        for (UInt16 j=0; j < gaps; j++)
        {
            if (i == j)
                continue;

            float b = gap[j].len;

            if (a > b)
                continue;

            // a < b donc multiplier >= 1
            int multiplier = (int) nearbyint (b / a);
            b = b / multiplier;

            float dist = fabs(b - a);
            float sc = 1. / (dist + 1.);

            gap[i].score += sc;
            if (multiplier == 1)
                gap[j].score += sc;
        }
	}

    UInt16 best = 0;
    for (UInt16 i=1; i < gaps; i++)
	{
        if (gap[i].score > gap[best].score)
            best = i;
	}

    return gap[best].len;
}


UInt16 getPotentialHarmonics (kOutputDataType * buffer, UInt16 begin, UInt16 end, double threshold, POTENTIAL_HARMONIC * pH)
{
	UInt16 freq = begin;
	UInt16 iPH = 0;

	// Tant que l'on atteind pas la fin
	while (freq < end)
	{
		// Tant que l'on est pas sous le seuil
		while ((freq < end) && (buffer [freq] > threshold))
		{
			freq++;
		}

		if (freq >= end) break;

		// Recherche du mimima local
		pH [iPH].freq = searchLocalMinimum (buffer, end, threshold, &freq);
		pH [iPH].peak = buffer [pH [iPH].freq];

		freq++;
		iPH++;

		if (iPH >= MAX_POTENTIAL_HARMONICS) break;
	}

	return iPH;
}

UInt16 minThresholdTrustLevel2 (kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio)
{
	static POTENTIAL_HARMONIC pH [ MAX_POTENTIAL_HARMONICS ];

	// --------------------------------------------------------------------------------------------------------------------------------
	// Définition du seuil

#if   MAX_THRESHOLD == GLOBAL_MAX_THRESHOLD
	// Le seuil maximum est la valeur maximale moins un pourcentage de la diff entre cette valeur et le minimum de la courbe
	kOutputDataType thresholdMax = buffer [searchGlobalMaximum (buffer, begin, end)];

#elif MAX_THRESHOLD == AVERAGE_THRESHOLD
	// Le seuil maximum est la valeur moyenne moins un pourcentage de la diff entre cette valeur et le minimum de la courbe
	kOutputDataType thresholdMax = computeAverage (buffer, begin, end);

#endif

	double threshold = thresholdMax - fundHarmonicRatio * (thresholdMax - buffer [searchGlobalMinimum (buffer, begin, end)]);

	// --------------------------------------------------------------------------------------------------------------------------------

	UInt16 phCount = getPotentialHarmonics (buffer, begin, end, threshold, pH);

	return findFundPeriodWithHarmonics (pH, phCount);
}


// ------------------------------------------------------------------------------------------------------------------------------------
// Recherche de la période ou fréquence fondamentale du buffer contenant le spectre inversé (pic vers le bas) du signal
// ------------------------------------------------------------------------------------------------------------------------------------
double getFundamentalPeriod2 (kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio)
{
	static double lastResult = 0;
	double result;

	if (lastResult == 0) lastResult = begin;

	result = minThresholdTrustLevel2	(buffer, begin, end, fundHarmonicRatio);
	result = parabolicInterpolation		(buffer, begin, end, result);
	result = smoothStepResult			(result, lastResult, begin, end);

	// Mise à jour de la valeur pour la prochaine recherche
	lastResult = result;

	return result;
}


