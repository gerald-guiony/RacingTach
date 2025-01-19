//
//  GLViewController.h
//  RacingTach
//
//  Created by Gérald GUIONY on 18/03/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//


#import <UIKit/UIKit.h>

// Macros
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

#import "GLView.h"

// ------------------------------------------------------------------------------------------------------------------------------------
// Définition d'un controlleur d'une vue OpenGL
// ------------------------------------------------------------------------------------------------------------------------------------
@protocol GLViewController <NSObject>

@required
-(void) drawView: (GLView *)view;

@optional
-(void) setupView: (GLView *)view;

-(void) startAnimation;
-(void) stopAnimation;

@end
