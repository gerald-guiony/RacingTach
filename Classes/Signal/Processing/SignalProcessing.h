/*
 *  SignalProcessing.h
 *  RacingTach
 *
 *  Created by Gérald GUIONY on 28/06/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _SIGNAL_PROCESSING_H_
#define _SIGNAL_PROCESSING_H_

#include "MacTypes.h" 

#if !defined(MIN)
#define MIN(A,B)	((A) < (B) ? (A) : (B))
#endif

#if !defined(MAX)
#define MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

void searchLocalHeights 		(kOutputDataType * buffer, UInt16 bufferSize, kOutputDataType * heightBuffer); 
UInt16 searchLocalMinimum 		(kOutputDataType * buffer, UInt16 bufferSize, double threshold, UInt16 * index);
UInt16 searchGlobalMinimum 		(kOutputDataType * buffer, UInt16 begin, UInt16 end);
UInt16 searchGlobalMaximum 		(kOutputDataType * buffer, UInt16 begin, UInt16 end);
double computeAverage 			(kOutputDataType * buffer, UInt16 begin, UInt16 end);
double parabolicInterpolation 	(kOutputDataType * buffer, UInt16 begin, UInt16 end, UInt16 estimatedResult); 
double smoothStepResult 		(double result, double lastResult, UInt16 begin, UInt16 end);

UInt16 minAbsoluteThreshold		(kOutputDataType * buffer, UInt16 begin, UInt16 end, double threshold, UInt16 lastResult, bool isTrustLevel);
UInt16 minThresholdTrustLevel 	(kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio);
double getFundamentalPeriod 	(kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio);

double getFundamentalPeriod2	(kOutputDataType * buffer, UInt16 begin, UInt16 end, kOutputDataType fundHarmonicRatio);

#endif
