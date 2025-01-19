//
//  GLViewControllerTachometerAudioSignal.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLViewControllerAnimated;
@class TachometerAudioSignal;

// ------------------------------------------------------------------------------------------------------------------------------------
// Graphique du compte-tours sur signal audio
// ------------------------------------------------------------------------------------------------------------------------------------
@interface GLViewControllerTachometerAudioSignal : GLViewControllerAnimated
{
	TachometerAudioSignal * _tachoAudioSignal;

	UInt32					_rpmLimit;

	GLfloat					_maxAutoCorrelationValue;

	GLuint					_tachoTexture;
	GLuint					_slightOnTexture;
	GLuint					_needleTexture;

	SystemSoundID			_soundID;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

-(id) initWithTachAudio: (TachometerAudioSignal *)tachAudio;

-(void) loadTachoTexture;
-(void) loadTextures;
-(void) loadAudio;
-(void) drawBackground;

@end
