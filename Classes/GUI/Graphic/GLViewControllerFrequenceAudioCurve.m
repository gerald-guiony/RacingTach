//
//  GLViewControllerAutoCorrelationAudioCurve.h
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

#import "GLViewControllerFrequenceAudioCurve.h"

#define kNbSegment 40

// ------------------------------------------------------------------------------------------------------------------------------------
// Les méthodes privées de cette classe ...
// ------------------------------------------------------------------------------------------------------------------------------------
@interface GLViewControllerFrequenceAudioCurve (private)
-(void) allocBuffers;
-(void) deleteBuffers;
@end

@implementation GLViewControllerFrequenceAudioCurve

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithTachAudio: (TachometerAudioSignal *)tachAudio
{
	self = [super init];
	if (self != nil)
	{
		_tachoAudioSignal = [tachAudio retain];

		_audioSignalVertex = NULL;
		_spectrumOutputVertex = NULL;

		[self allocBuffers];
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Dessine la vue
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) drawView: (GLView *)view
{
	static GLfloat maxMaxAudioSignalValue = 0.0f;

	// ------------------------------------------------------------------------------------
	// Mise à jour des valeurs

	[_tachoAudioSignal update];

	UInt16 nbPoints = _tachoAudioSignal.numPoints;
	id fundFreqFinder = _tachoAudioSignal.fundFreqFinder;

	GLfloat maxAudioSignalValue = [GLTool convertInputBuffer: _tachoAudioSignal.audioSignalData
													toVertex: _audioSignalVertex
												fromMinIndex: 0
												withNbPoints: _tachoAudioSignal.numPoints];

	GLfloat maxDetectionOutputValue = [GLTool convertOutputBuffer: _tachoAudioSignal.spectrumOutputData
														 toVertex: _spectrumOutputVertex
													 fromMinIndex: 0
													 withNbPoints: [fundFreqFinder nbOutputElem]];

	if (maxAudioSignalValue > maxMaxAudioSignalValue)
	{
		maxMaxAudioSignalValue = maxAudioSignalValue;
	}

	// ------------------------------------------------------------------------------------
	// Calcul des points de la droite segmentée sur l'abscisse de la période fund

	static GLfloat periodVertex [2 * kNbSegment];
	static GLfloat step = 2.0f  / (kNbSegment - 1.0f);

	GLfloat * pPeriodVertex	= periodVertex;

	// Dessin d'une ligne segmentée
	for (int i = 0; i < kNbSegment; i++)
	{
		*pPeriodVertex++ = [fundFreqFinder fundamentalFreq];
		*pPeriodVertex++ = -1.0f + i * step;
	}

	// ------------------------------------------------------------------------------------
	// Affichage graphique

	// Clear The Screen
	glClear (GL_COLOR_BUFFER_BIT);

	// In order to use vertex arrays, we have to enable that feature in OpenGL, like so :
	glEnableClientState (GL_VERTEX_ARRAY);

	// Enable Antialiased lines
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable (GL_LINE_SMOOTH);

	// Reset The Current Modelview Matrix
	glLoadIdentity ();

	// ===== Affiche le signal =====
	glPushMatrix();	// Sauvegarde de la matrice courante
	{
		// The glScalef functions multiply the current matrix by a general scaling matrix.
		glScalef (1.0f / nbPoints, 0.9f / maxMaxAudioSignalValue, 1.0f);

		// flat coloring : Set the color to blue
		// Anything we draw from now on will be blue until we change the color to something other than red
		glColor4f (0.0f, 0.0f, 1.0f, 1.0f);

		glVertexPointer (2, GL_FLOAT, 0, _audioSignalVertex);
		glDrawArrays (GL_LINE_STRIP, 0, nbPoints);
	}
	glPopMatrix(); // Rétablit la matrice sauvegardée

	// ===== Affiche le calcul d'autocorrelation =====
	glPushMatrix();	// Sauvegarde de la matrice courante
	{
		// The glScalef functions multiply the current matrix by a general scaling matrix.
		glScalef (1.0f / [fundFreqFinder nbOutputElem], 1.0f / maxDetectionOutputValue, 1.0f);

		// flat coloring : Set the color to green
		glColor4f (0.0f, 1.0f, 0.0f, 1.0f);

		glVertexPointer (2, GL_FLOAT, 0, _spectrumOutputVertex);
		glDrawArrays (GL_LINE_STRIP, 0, [fundFreqFinder nbOutputElem]);
	}
	glPopMatrix(); // Rétablit la matrice sauvegardée

	// --- Affiche la période du signal
	glPushMatrix();	// Sauvegarde de la matrice courante
	{
		// The glScalef functions multiply the current matrix by a general scaling matrix.
		glScalef (1.0f / [fundFreqFinder nbOutputElem], 1.0f, 1.0f);

		// flat coloring : Set the color to red
		glColor4f (1.0f, 0.0f, 0.0f, 1.0f);

		//glEnable (GL_LINE_STIPPLE);

		glVertexPointer (2, GL_FLOAT, 0, periodVertex);
		glDrawArrays (GL_LINES, 0, kNbSegment);
	}
	glPopMatrix(); // Rétablit la matrice sauvegardée

	// The call to glEnableClientState can be either in the setup code, or in the drawing code, depending on your needs, and states can
	// be enabled and disabled during the life of the application, so if you only use vertex arrays in one part, you could enable it,
	// do your vertex array drawing, then disable it by calling glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState (GL_VERTEX_ARRAY);

	// --- Affiche la valeur chiffrée du compte tour
	{
		// The glScalef functions multiply the current matrix by a general scaling matrix.
		glScalef (0.5f, 1.0f, 1.0f);

		NSString * rpmText = [NSString stringWithFormat: @"RPM: %05d", [_tachoAudioSignal getCurrentRPM]];
		[GLTool drawText: rpmText AtX: 1.25f Y: -0.8f WithFontSize: 16
			AndTextColor: ([_tachoAudioSignal headsetPluggedIn] ? [UIColor orangeColor] : [UIColor yellowColor])];
	}

	//NSLog(@"Graph ok");
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
	glOrthof (0.0f, 1.0f, -1.0f, 1.0f, 0.0f, 1.0f);

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

	// Black Background
	// The following line sets the color of the screen when it clears.
	// The color values range from 0.0f to 1.0f. 0.0f being the darkest and 1.0f being the brightest.
	// The first parameter after glClearColor is the Red Intensity, the second parameter is for Green and the third is for Blue.
	// The closer the number is to 1.0f, the brighter that specific color will be.
	// The last number is an Alpha value. When it comes to clearing the screen, we wont worry about the 4th number.
	// The Alpha value can be considered as the opacity or transparency of the pixel. Alpha component of the color is associated with
	// blending.
	glClearColor (0.0f, 0.0f, 0.0f, 1.0f);

	/*
	// Label de la valeur du compte tours
	UILabel * textView = [[UILabel alloc] initWithFrame: CGRectMake(rect.size.width - 100.0f, rect.size.height - 20.0f, 100.0f, 20.0f)];
	textView.textAlignment = UITextAlignmentLeft;
	textView.textColor = [UIColor yellowColor];
	textView.backgroundColor = [UIColor blackColor];
	[self.view addSubview: textView];
	[self.view bringSubviewToFront: textView];
	self.rpmTextView = textView;
	[textView release];
	*/
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
// Allocation des buffers internes
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) allocBuffers
{
	// To protect sections of code from being executed by more than one thread at a time
	@synchronized (self)
	{
		[self deleteBuffers];

		_audioSignalVertex = (GLfloat *) malloc (2 * [_tachoAudioSignal numPoints] * sizeof (GLfloat));  // Vertices pour Open GL => contient x & y
		_spectrumOutputVertex =  (GLfloat *) malloc (2 * [_tachoAudioSignal numPoints] * sizeof (GLfloat)); // 2 * ... car contient x & y

		bzero (_audioSignalVertex, 2 * [_tachoAudioSignal numPoints] * sizeof (GLfloat));
		bzero (_spectrumOutputVertex, 2 * [_tachoAudioSignal numPoints] * sizeof (GLfloat));
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
		if (_audioSignalVertex != NULL) free (_audioSignalVertex);
		if (_spectrumOutputVertex != NULL) free (_spectrumOutputVertex);
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	// Stopper l'animation avant tout !
	[self stopAnimation];

	// Release l'audio
	[_tachoAudioSignal release];

	[self deleteBuffers];

	//[_rpmTextView release];

    [super dealloc];
}

@end
