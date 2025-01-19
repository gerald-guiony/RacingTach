//
//  GLViewControllerAutoCorrelationAudioCurve.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLViewControllerAnimated;
@class TachometerAudioSignal;

// ------------------------------------------------------------------------------------------------------------------------------------
// Exemple d'un controlleur d'une vue OpenGL 2D
// http://iphonedevelopment.blogspot.com/2008/12/opengl-project-template-for-xcode.html
// ------------------------------------------------------------------------------------------------------------------------------------
@interface GLViewControllerFrequenceAudioCurve : GLViewControllerAnimated
{
	TachometerAudioSignal * _tachoAudioSignal;

	GLfloat					_maxOutputValue;

	GLfloat	*				_audioSignalVertex;		// Vertices pour Open GL => contient le signal audio x & y
	GLfloat *				_spectrumOutputVertex;	// Vertices pour Open GL => contient le calcul de la detection de la période
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

-(id) initWithTachAudio: (TachometerAudioSignal *)tachAudio;

@end
