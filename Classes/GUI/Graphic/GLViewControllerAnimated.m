//
//  GLViewControllerAnimated.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// http://iphonedevelopment.blogspot.com/2008/12/opengl-project-template-for-xcode.html


#import "GLViewControllerAnimated.h"

@implementation GLViewControllerAnimated

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) init
{
	self = [super init];
	if (self != nil)
	{
		_animated = NO;
	}
	return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Dessine la vue
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) drawView: (GLView *)view
{
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
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Surcharge du setter de la view
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) setView: (UIView *)v
{
	// It’s important to set the autoresizing properties of views so that when they are displayed or the orientation changes, the views
	// are displayed correctly within the superview’s bounds. Use the autoresizesSubviews property, especially if you subclass UIView,
	// to specify whether the view should automatically resize its subviews. Use the autoresizingMask property with the constants
	// described in UIViewAutoresizing to specify how a view should automatically resize.
	v.autoresizesSubviews = YES;
	v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	// Affectation du controlleur à la vue
	//((GLView *)v).controller = self;

	// Appel du setter de la classe parent
	super.view = v;
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
			_animated = YES;
			// Redémarre le timer d'affichage
			[(GLView *)self.view startAnimation];
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
			// Arrete le timer d'affichage
			[(GLView *)self.view stopAnimation];
			_animated = NO;
		}
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Autorise la rotation de la vue
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Sent to the view controller before the user interface rotates.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation duration: (NSTimeInterval)duration
{
	// Arrete le timer d'affichage
	[self stopAnimation];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Sent to the view controller after the user interface rotates.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation)fromInterfaceOrientation
{
	if ((fromInterfaceOrientation == UIInterfaceOrientationPortrait) ||
	    (fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown))
	{
	}

	// Réinitialise les dimentions du viewport par rapport à la rotation de la fenetre
	[self setupView: nil];

	// Redémarre l'affichage
	[self startAnimation];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Notifies the view controller that its view is about to be become visible.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewWillAppear: (BOOL)animated
{
	// Affectation du controlleur à la vue
	[(GLView *)self.view setController: self];

	// Réinitialise les dimentions du viewport par rapport à l'éventuelle rotation précédente de la fenetre
	[self setupView: nil];

	// Démarre le timer d'affichage
	[self startAnimation];

    [super viewWillAppear: animated];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Notifies the view controller that its view is about to be dismissed, covered, or otherwise hidden from view.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewWillDisappear: (BOOL)animated
{
	// Arrete le timer d'affichage ...
	[self stopAnimation];

    [super viewWillDisappear: animated];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Surcharge
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	// Stop l'affichage
	[self stopAnimation];

    [super dealloc];
}

@end
