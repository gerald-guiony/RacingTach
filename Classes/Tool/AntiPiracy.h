/*
 *  antiPiracy.h
 *  RacingTach
 *
 *  Created by Gérald GUIONY on 30/03/11.
 *  Copyright 2011 Gérald GUIONY. All rights reserved.
 *
 */

#ifndef _ANTI_PIRACY_H_
#define _ANTI_PIRACY_H_

#include "MacTypes.h"

// Obfuscation des noms des méthodes ...
// Les nom des méthodes sont obfusquées car elles ne sont pas enlevées dans le binaire release d'un programme
// iphone même en compilant avec l'option RTTI enlevé

#define userIsNotRoot				_getRpmValue_
#define checkDebugIntegrity			_betterRpm_
#define isEncrypted					_setRpmValue_

#define randomInt					_rpmHarmonic_
#define punishThreadRoutine			_rpmStatus_
#define sleepThreadRoutine			_rpmFactor_
#define launchThread				_manageRpmValue_
#define checkPiracy					_checkRpmValue_

// Les différentes méthodes de détection du piratage
bool userIsNotRoot 			(void);
bool isEncrypted 			(void);

int randomInt				(int min, int max);
void * punishThreadRoutine 	(void * data);
void * sleepThreadRoutine 	(void * data);
void launchThread			(void *(* routine)(void *));
void checkPiracy 			(void);

#endif