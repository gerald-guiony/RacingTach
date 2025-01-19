//
//  GLView.m
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// http://iphonedevelopment.blogspot.com/2008/12/opengl-project-template-for-xcode.html

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "GLView.h"
#import "GLViewController.h"

#define SCREEN_WIDTH	320
#define SCREEN_HEIGHT	480

// ------------------------------------------------------------------------------------------------------------------------------------
// Quelques méthodes privées de cette classe ...
// ------------------------------------------------------------------------------------------------------------------------------------
@interface GLView (private)

-(id) initGLES;
-(BOOL) createFramebuffer;
-(void) destroyFramebuffer;

@end


@implementation GLView

@synthesize	controller = _controller;
@synthesize animationInterval = _animationInterval;

// ------------------------------------------------------------------------------------------------------------------------------------
// la fenètre dans laquelle notre vue va s'afficher, va lui demander quel est le type de ce que l'on affiche (grosso modo).
// Il faut donc répondre que c'est de l'OpenGL, or la seule classe qui permet d'afficher de l'OpenGL est CAEAGLLayer
// ------------------------------------------------------------------------------------------------------------------------------------
+(Class) layerClass
{
	return [CAEAGLLayer class];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur à partir d'une frame (de ses dimentions)
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithFrame: (CGRect)frame
{
	self = [super initWithFrame: frame];
	if (self != nil)
	{
		self = [self initGLES];
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désérialisation
// Returns an object initialized from data in a given unarchiver.
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithCoder: (NSCoder *)coder
{
	if ((self = [super initWithCoder: coder]))
	{
		self = [self initGLES];
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Initialisation de la view OpenGL / QuartzCore
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initGLES
{
	CAEAGLLayer * eaglLayer = (CAEAGLLayer *) self.layer;

	//---------------------------------------------------------------------------------------------------------------------------------
	// Prise en compte éventuelle de l'écran Retina sur les iphones 4G

	// Avant d'appeler glGetRenderbufferParameterivOES, il faut faire cela :
	int w = SCREEN_WIDTH;
	int h = SCREEN_HEIGHT;

	float ver = [[[UIDevice currentDevice] systemVersion] floatValue];
	// You can't detect screen resolutions in pre 3.2 devices, but they are all 320x480
	if (ver >= 3.2f)
	{
		UIScreen * mainscr = [UIScreen mainScreen];
		w = mainscr.currentMode.size.width;
		h = mainscr.currentMode.size.height;
	}

	if ((w == 2 * SCREEN_WIDTH  && h == 2 * SCREEN_HEIGHT) ||	// Retina display detected
		(w == 2 * SCREEN_HEIGHT && h == 2 * SCREEN_WIDTH))		// Retina display detected en mode paysage ...
	{
		// Set contentScale Factor to 2
		self.contentScaleFactor = 2.0;
		// Also set our glLayer contentScale Factor to 2
		eaglLayer.contentsScale = 2; // new line
	}

	// Ainsi le contentsScale stocke l'information du doublage du nombre de pixels. Ainsi, on peut réutiliser cette info lors :
	// - Du gLViewport
	// - De touchesMoved / touchesBegan / touchesEnd (ou il faut appliquer le contentsScale sur UITouch locationInView
	// [touch locationInView:self].x * eaglLayer.contentsScale
	//---------------------------------------------------------------------------------------------------------------------------------

	// Configure it so that it is opaque, does not retain the contents of the backbuffer when displayed, and uses RGBA8888 color.
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool: FALSE], kEAGLDrawablePropertyRetainedBacking,
										kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
										nil];

	// Create our EAGLContext, and if successful make it current and create our framebuffer.
	_context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES1];
	if (!_context || ![EAGLContext setCurrentContext: _context] || ![self createFramebuffer])
	{
		[self release];
		return nil;
	}

	// Default the animation interval to 1/60th of a second.
	_animationInterval = 1.0 / kRenderingFrequency;
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Setter du controlleur
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setController: (id <GLViewController>) ctroller
{
	// ATTENTION : pas de 'retain' ici car le controlleur retiens déjà la vue (UIViewController : @property(nonatomic, retain) UIView *view)
	// => risque cyclique de non désallocation si les 2 objets se retiennent mutuellement ...
	// [ctroller retain]; 			// On incrémente le compteur de 1...
	// [_controller release]; 		// Pour qu’il ne risque pas de tomber à zero ici (au cas où _controller == ctroller)
	// _controller = ctroller; 		// Mais on ne réexécute pas de "retain" ici !
	_controller = ctroller;		// 'assign' uniquement

	_controllerSetup = ![_controller respondsToSelector: @selector(setupView:)];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// If our view is resized, we'll be asked to layout subviews. This is the perfect opportunity to also update the framebuffer so that it
// is the same size as our display area.
//
// Lors de l'affichage d'une vue, plusieurs méthodes sont appelées. La méthode - (void) layoutSubviews; en fait partie.
// Son role est de mettre à jour l'affichage des vues contenues dans notre vue. Dans notre cas, nous n'en avons pas, mais c'est bien
// ici que nous allons mettre à jour des données pour l'affichage OpenGL
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) layoutSubviews
{
	// On bascule dans notre contexte maison, car c'est lui qui va rendre notre code
	[EAGLContext setCurrentContext: _context];
	// On appelle une méthode que l'on va définir apres, detruisant nos buffers pour en assurer la mise a jour
	[self destroyFramebuffer];
	// On appelle la méthode qui va (re)créer les tampons
	[self createFramebuffer];
	// Enfin, la méthode qui dessine ce qu'il y a à afficher
	[self drawView];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Création des tampons d'affichage
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) createFramebuffer
{
	// On génère les tampons
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES (1, &_viewFramebuffer);
	glGenRenderbuffersOES (1, &_viewRenderbuffer);

	// Et on indique au système quelles variables les représentent
	glBindFramebufferOES (GL_FRAMEBUFFER_OES, _viewFramebuffer);
	glBindRenderbufferOES (GL_RENDERBUFFER_OES, _viewRenderbuffer);

	// On relie notre tampon de rendu à la couche où il va s'afficher
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen whereever the layer is (which corresponds with our view).
	[_context renderbufferStorage: GL_RENDERBUFFER_OES fromDrawable: (id<EAGLDrawable>)self.layer];

	// On paramètre le tampon de rendu :
	// - avec le niveau de couleur que l'on veut
	glFramebufferRenderbufferOES (GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _viewRenderbuffer);
	// - avec les dimensions de l'écran
	glGetRenderbufferParameterivOES (GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
	glGetRenderbufferParameterivOES (GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);

	// On génère le tampon de profondeur -- bah oui, on fait de la 3D
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES (1, &_depthRenderbuffer);
	glBindRenderbufferOES (GL_RENDERBUFFER_OES, _depthRenderbuffer);
	// On paramétre le tampon :
	// - avec les dimensions que l'on veut
	glRenderbufferStorageOES (GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, _backingWidth, _backingHeight);
	// - avec la profondeur que l'on veut
	glFramebufferRenderbufferOES (GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthRenderbuffer);

	// Si ca n'a pas réussi à créer notre bouzin, on dégage !
	if (glCheckFramebufferStatusOES (GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES (GL_FRAMEBUFFER_OES));
		return NO;
	}

	return YES;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Clean up any buffers we have allocated.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) destroyFramebuffer
{
	// Les méthodes pour les destructions des tampons...
	glDeleteFramebuffersOES (1, &_viewFramebuffer);
	_viewFramebuffer = 0;

	glDeleteRenderbuffersOES (1, &_viewRenderbuffer);
	_viewRenderbuffer = 0;

	if (_depthRenderbuffer)
	{
		glDeleteRenderbuffersOES (1, &_depthRenderbuffer);
		_depthRenderbuffer = 0;
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
		if (_animationInterval > 0)
		{
			// Lancement du timer qui va appeler la méthode 'drawview' de cet objet
			_animationTimer = [NSTimer scheduledTimerWithTimeInterval: _animationInterval
															   target: self
															 selector: @selector(drawView)
															 userInfo: nil
															  repeats: YES];
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
		if (_animationInterval > 0)
		{
			[_animationTimer invalidate];
			_animationTimer = nil;
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Setter du délais de l'interval de la mise à jour de l'affichage
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setAnimationInterval: (NSTimeInterval)interval
{
	_animationInterval = interval;

	if (_animationTimer)
	{
		[self stopAnimation];
		[self startAnimation];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Updates the OpenGL view when the timer fires
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) drawView
{
	// On bascule dans le contexte qu'on s'est défini
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext: _context];

	// If our drawing delegate needs to have the view setup, then call -setupView: and flag that it won't need to be called again.
	if (!_controllerSetup)
	{
		[_controller setupView: self];
		_controllerSetup = YES;
	}

	// On lie au tampon viewFramebuffer (le tampon mémoire d'affichage ???)
	glBindFramebufferOES (GL_FRAMEBUFFER_OES, _viewFramebuffer);

	// Appel de la méthode 'drawview' du controlleur associé
	[_controller drawView: self];

	// On lie au tampon viewRenderbuffer (Le tampon réel de l'affichage ???)
	glBindRenderbufferOES (GL_RENDERBUFFER_OES, _viewRenderbuffer);
	// Et on le présente dans le contexte pour affichage
	[_context presentRenderbuffer: GL_RENDERBUFFER_OES];

	// Y'a t'il une erreur ?
	GLenum err = glGetError();
	if (err)
	{
		NSLog(@"%x error", err);
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Stop animating and release resources when they are no longer needed.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	[self stopAnimation];

	// Libération du controlleur qui était retenu
	[_controller release];

	// On teste si le contexte de rendu OpenGL qui est actif et est le notre
	if ([EAGLContext currentContext] == _context)
	{
		[EAGLContext setCurrentContext:nil];
	}

	// Libération du context crée dans la méthode 'initGLES'
	[_context release];
	_context = nil;

	[super dealloc];
}

@end
