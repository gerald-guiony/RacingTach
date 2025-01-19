//
//  GLTool.h
//  RacingTach
//
//  Created by Gérald GUIONY on 01/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

// ------------------------------------------------------------------------------------------------------------------------------------
//
// ------------------------------------------------------------------------------------------------------------------------------------
@interface GLTool : NSObject 
{
@private
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

+(void) setUIColor: (UIColor *)uicolor;
+(void) drawText: (NSString *)theString AtX: (float)x Y: (float)y WithFontSize: (int)fontSize AndTextColor: (UIColor *)foreColor;
+(void) createGLTexture: (GLuint *)texName fromUIImage: (UIImage *)img;

+(GLfloat) convertInputBuffer: (kInputDataType *)buffer toVertex: (GLfloat *)vertex fromMinIndex: (UInt16)minIndex withNbPoints: (UInt16)nbPoints;
+(GLfloat) convertOutputBuffer: (kOutputDataType *)buffer toVertex: (GLfloat *)vertex fromMinIndex: (UInt16)minIndex withNbPoints: (UInt16)nbPoints;

@end
