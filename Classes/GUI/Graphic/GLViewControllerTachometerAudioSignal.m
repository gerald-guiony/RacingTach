//
//  GLViewControllerTachometerAudioSignal.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// http://iphonedevelopment.blogspot.com/2008/12/opengl-project-template-for-xcode.html

#import <QuartzCore/QuartzCore.h>

#import "GLTool.h"
#import "GLViewControllerAnimated.h"
#import "TachometerAudioSignal.h"

#import "GLViewControllerTachometerAudioSignal.h"


// Le 0 dans l'image texture du Compte-tours est positionné à 45°
#define kNeedleOffsetAngle			45.0

// La valeur limite des RPM dans l'image texture du Compte-tours est positionné à 270°
#define kNeedleMaximumAngle 		270.0



// Le son de l'alarme shift light est il complétement joué ?
static BOOL ShiftLightSoundCompletion = YES;

// ------------------------------------------------------------------------------------------------------------------------------------
// When the sound is done, it will call this function (a regular C function, not an objective-C method) with your object as a parameter
// ------------------------------------------------------------------------------------------------------------------------------------
static void shiftLightSoundCompletionCallback (SystemSoundID newPlayer, void * myself)
{
	ShiftLightSoundCompletion = YES;
}



@implementation GLViewControllerTachometerAudioSignal

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithTachAudio: (TachometerAudioSignal *)tachAudio
{
	self = [super init];
	if (self != nil)
	{
		_tachoAudioSignal = [tachAudio retain];

		// Affectation de la valeur limite des RPM (suivant le type de compte-tours)
		_rpmLimit = [_tachoAudioSignal getRpmLimit];

		// Initialisation des handles des textures
		_tachoTexture = _slightOnTexture = _needleTexture = 0;

		// Chargement des textures
		[self loadTextures];

		// Chargement des sons
		[self loadAudio];
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Dessine la vue
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) drawView: (GLView *)view
{
	// Mise à jour de la valeur limite du compte tours (si besoin)
	if (_rpmLimit != [_tachoAudioSignal getRpmLimit])
	{
		_rpmLimit = [_tachoAudioSignal getRpmLimit];
		// Mise à jour de la texture du compte-tours
		[self loadTachoTexture];
	}

	// Mise à jour des valeurs
	[_tachoAudioSignal update];

	// Affichage graphique
	[self drawBackground];

	// Affiche la valeur du compte tour
	NSString * rpmText = [NSString stringWithFormat: @"%05d", [_tachoAudioSignal getCurrentRPM]];
	[GLTool drawText: rpmText AtX: -0.22f Y: -0.52f WithFontSize: 24 AndTextColor: [UIColor whiteColor]];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Prépare la vue avant qu'elle soit dessinée
// http://jerome.jouvie.free.fr/OpenGl/Lessons/Lesson1.php
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setupView: (GLView *)view
{
	// Lorsque l'on a besoin de mettre a jour la configuration de l'affichage sans pour autant changer la vue
	if (view == nil)
		view = (GLView *)self.view;

	// 2D means no depth!
	// The depth buffer is what OpenGL uses to determine which objects are infront or behind each other in 3D space, based on their
	// pixel's Z coordinates
	glDisable (GL_DEPTH_TEST);

	// glMatrixMode(GL_PROJECTION) indicates that the next 2 lines of code will affect the projection matrix.
	// The projection matrix is responsible for adding perspective to our scene. glLoadIdentity() is similar to a reset.
	// It restores the selected matrix to it's original state. After we set up our perspective view for the scene.
	// glMatrixMode(GL_MODELVIEW) indicates that any new transformations will affect the modelview matrix.
	// The modelview matrix is where our object information is stored. Lastly we reset the modelview matrix.

	// Specifies which matrix stack is the target for subsequent matrix operations
	// Select The Projection Matrix
	glMatrixMode (GL_PROJECTION);

	// Reset The Projection Matrix (replace the current matrix with the identity matrix)
	glLoadIdentity ();

	// Orthographic Projection
	CGRect rect = view.bounds;

	// Proportion de l'écran 320 * 480
	double k = (double)rect.size.height / (double)rect.size.width;
	if (rect.size.height > rect.size.width)
	{
		// Ecran en mode portrait
		glOrthof (-1.0f, 1.0f, -1.0f * k, 1.0f * k, 0.0f, 1.0f);
	}
	else
	{
		// Ecran en mode paysage
		glOrthof (-1.0f / k, 1.0f / k, -1.0f, 1.0f, 0.0f, 1.0f);
	}

	// Reset The Current Viewport
	// x, y = Specify the lower left corner of the viewport rectangle, in pixels. The initial value is 0, 0
	// width, height = Specify the width and height of the viewport. When a GL context is first attached to a window, width and height
	// are set to the dimensions of that window.
	CAEAGLLayer * eaglLayer = (CAEAGLLayer *) view.layer; // Prise en compte de l'écran rétina avec la mise à l'échelle 'contentsScale'
	glViewport (0, 0, rect.size.width * eaglLayer.contentsScale, rect.size.height * eaglLayer.contentsScale);

	// Select The Modelview Matrix
	glMatrixMode (GL_MODELVIEW);

	// Reset The Modelview Matrix (replace the current matrix with the identity matrix)
	glLoadIdentity ();

	// Displacement trick for exact pixelization
	//glTranslatef (0.375f, 0.375f, 0.0f);

	// Black Background
	// The following line sets the color of the screen when it clears.
	// The color values range from 0.0f to 1.0f. 0.0f being the darkest and 1.0f being the brightest.
	// The first parameter after glClearColor is the Red Intensity, the second parameter is for Green and the third is for Blue.
	// The closer the number is to 1.0f, the brighter that specific color will be.
	// The last number is an Alpha value. When it comes to clearing the screen, we wont worry about the 4th number.
	// The Alpha value can be considered as the opacity or transparency of the pixel. Alpha component of the color is associated with
	// blending.
	glClearColor (0.0f, 0.0f, 0.0f, 1.0f);
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Affiche le compte tours avec son aiguille
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) drawBackground
{
	// Les coordonnées pour l'affichage des textures
	static const GLfloat vertices[] = {
		-1.0f, -1.0f,	// bas gauche
		-1.0f, +1.0f,	// Haut gauche
		+1.0f, -1.0f,	// bas droit
		+1.0f, +1.0f,	// haut droit
	};
	static const GLshort texCoords[] = {
		0, 0,       // bas gauche
		0, 1,       // Haut gauche
		1, 0,       // bas droit
		1, 1        // haut droit
	};

	static BOOL showShiftLightAlarm = false;

	// Clignotement
	showShiftLightAlarm = ((!showShiftLightAlarm) && ([_tachoAudioSignal isShiftLightAlarm]));

	// Clear The Screen (les buffers)
	glClear (GL_COLOR_BUFFER_BIT);

	// Definir la couleur d'arrier plan
	glClearColor (showShiftLightAlarm ? 1.0f : 0.0f, showShiftLightAlarm ? 1.0f : 0.0f, showShiftLightAlarm ? 1.0f : 0.0f, 1.0f);

	// Pas de transparence ni de mélange de couleur : This causes the destination color to not be used. The new color is simply used
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	// Flat coloring : Set the color to white
	glColor4f (1.0, 1.0, 1.0, 1.0);

	// Enable use of the texture
	glEnable (GL_TEXTURE_2D);

	// In order to use vertex arrays, we have to enable that feature in OpenGL, like so :
	glEnableClientState (GL_VERTEX_ARRAY);

	// Tell OpenGL that you will use a texture array and the data for that texture array is specified by glTexCoordPointer
	glEnableClientState (GL_TEXTURE_COORD_ARRAY);


	// Draw our background tachometer screen
	{
		glBindTexture (GL_TEXTURE_2D, _tachoTexture);

		glVertexPointer (2, GL_FLOAT, 0, vertices);
		glTexCoordPointer (2, GL_SHORT, 0, texCoords);

		glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
	}


	// Draw the shift-light
	if (showShiftLightAlarm)
	{
		glBindTexture (GL_TEXTURE_2D, _slightOnTexture);

		glVertexPointer (2, GL_FLOAT, 0, vertices);
		glTexCoordPointer (2, GL_SHORT, 0, texCoords);

		glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
	}

	// Draw the needle
	{
		glBindTexture (GL_TEXTURE_2D, _needleTexture);

		glLoadIdentity();
		glPushMatrix();	// Sauvegarde de la matrice courante
		{
			// 360 - 90 = 270° pour 10000 tr/min
			glRotatef (kNeedleOffsetAngle - [_tachoAudioSignal getCurrentRPM] * kNeedleMaximumAngle / _rpmLimit, 0.0f, 0.0f, 1.0f);
			glVertexPointer (2, GL_FLOAT, 0, vertices);
			glTexCoordPointer (2, GL_SHORT, 0, texCoords);
			glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
		}
		glPopMatrix();	// Rétablit la matrice sauvegardée
	}

	glDisableClientState (GL_TEXTURE_COORD_ARRAY);

	// The call to glEnableClientState can be either in the setup code, or in the drawing code, depending on your needs, and states can
	// be enabled and disabled during the life of the application, so if you only use vertex arrays in one part, you could enable it,
	// do your vertex array drawing, then disable it by calling glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState (GL_VERTEX_ARRAY);

	glDisable (GL_TEXTURE_2D);

	// Jouer le son de l'alarme du shift light si les écouteurs sont branchés (ou si le micro est branché)
	if ((_tachoAudioSignal.shiftLightSound)	 &&
//		(_tachoAudioSignal.headsetPluggedIn) &&
		(showShiftLightAlarm) 				 &&
		(ShiftLightSoundCompletion))
	{
		ShiftLightSoundCompletion = NO;

		// ???
		UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
		AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute, sizeof (audioRouteOverride), &audioRouteOverride);

		AudioServicesPlaySystemSound (_soundID);
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Chargement de la texture du compte-tours
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) loadTachoTexture
{
	if (_tachoTexture != 0)	glDeleteTextures(1, &_tachoTexture);
	NSString * imageName = [NSString stringWithFormat: @"Tacho%d.png", _rpmLimit];
	UIImage * imgTacho = [UIImage imageNamed: imageName];
	if (imgTacho == nil) {
        NSLog(@"Failed to load the image '%@' !", imageName);
        return;
    }
	[GLTool createGLTexture: &_tachoTexture fromUIImage: imgTacho];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Chargement des textures de l'animation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) loadTextures
{
	// Load our GL textures
	[self loadTachoTexture];

	// Load our GL textures
	if (_slightOnTexture != 0)	glDeleteTextures(1, &_slightOnTexture);
	UIImage * imgShiftLightOn = [UIImage imageNamed: @"ShiftLightAlarmOn.png"];
	if (imgShiftLightOn == nil) {
        NSLog(@"Failed to load the image 'ShiftLightAlarmOn.png' !");
        return;
    }
	[GLTool createGLTexture: &_slightOnTexture fromUIImage: imgShiftLightOn];

	// Load our GL textures
	if (_needleTexture != 0)	glDeleteTextures(1, &_needleTexture);
	UIImage * imgNeedle = [UIImage imageNamed: @"Needle.png"];
	if (imgNeedle == nil) {
        NSLog(@"Failed to load the image 'Needle.png' !");
        return;
    }
	[GLTool createGLTexture: &_needleTexture fromUIImage: imgNeedle];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Chargement des fichiers sons de l'animation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) loadAudio
{
	NSString * path = [[NSBundle mainBundle] pathForResource: @"ShiftLight" ofType: @"wav"];
	NSURL * aFileURL = [NSURL fileURLWithPath: path isDirectory: NO];

	if (aFileURL != nil)
	{
		SystemSoundID aSoundID;
		OSStatus error = AudioServicesCreateSystemSoundID ((CFURLRef)aFileURL, &aSoundID);

		if (error == kAudioServicesNoError)  // success
		{
			_soundID = aSoundID;
			AudioServicesAddSystemSoundCompletion (_soundID, NULL, NULL, shiftLightSoundCompletionCallback, (void*) self);
		}
		else
		{
			NSLog (@"Error %d loading sound at path: %@", error, path);
			[self release], self = nil;
		}
	}
	else
	{
		NSLog (@"NSURL is nil for path: %@", path);
		[self release], self = nil;
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Lance la mise à jour de l'affichage a interval réguliers
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) startAnimation
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		if (!_animated)
		{
			// Démarre l'audio
			[_tachoAudioSignal startAcquisition];

			// Redémarre le timer d'affichage
			[super startAnimation];

			// Mise en veille OFF de l'iphone
			[UIApplication sharedApplication].idleTimerDisabled = YES;
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Arret de ma mise à jour de l'affichage
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) stopAnimation
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		if (_animated)
		{
			// Mise en veille ON
			[UIApplication sharedApplication].idleTimerDisabled = NO;

			// Arrete le timer d'affichage
			[super stopAnimation];

			// Stop l'audio
			[_tachoAudioSignal stopAcquisition];
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	// Stopper l'animation avant tout !
	[self stopAnimation];

	// Clean up textures
	glDeleteTextures(1, &_tachoTexture);
	glDeleteTextures(1, &_slightOnTexture);
	glDeleteTextures(1, &_needleTexture);

	// Release l'audio
	[_tachoAudioSignal release];

	// Release le son du shift light
	AudioServicesRemoveSystemSoundCompletion (_soundID);
	AudioServicesDisposeSystemSoundID (_soundID);

    [super dealloc];
}

@end
