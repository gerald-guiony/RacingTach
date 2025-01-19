//
//  GLView.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

// How many times a second to refresh the screen
#define kRenderingFrequency 60.0

@protocol GLViewController;

// ------------------------------------------------------------------------------------------------------------------------------------
// Une vue OpenGL
// http://iphonedevelopment.blogspot.com/2008/12/opengl-project-template-for-xcode.html
// ------------------------------------------------------------------------------------------------------------------------------------
@interface GLView : UIView
{
@private
	// The pixel dimensions of the backbuffer
	GLint _backingWidth;
	GLint _backingHeight;

	// Cette fameuse classe gère à peu près tout lorsque l'on veut faire de l'OpenGL ES...
	// c'est elle qui va "encapsuler" notre OpenGL au sein de l'interface et de son monde haut niveau.
	EAGLContext * _context;

	GLuint _viewRenderbuffer;
	GLuint _viewFramebuffer;
	GLuint _depthRenderbuffer;

	NSTimer * _animationTimer;
	NSTimeInterval _animationInterval;

	id <GLViewController> _controller;
	BOOL _controllerSetup;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

@property (nonatomic, assign) id <GLViewController>	controller;
@property (nonatomic, assign) NSTimeInterval		animationInterval;

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

-(void) startAnimation;
-(void) stopAnimation;
-(void) drawView;

@end
