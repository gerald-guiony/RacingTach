//
//  GLTool.m
//  RacingTach
//
//  Created by Gérald GUIONY on 01/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GLTool.h"
#import "Texture2D.h"

@implementation GLTool

// ------------------------------------------------------------------------------------------------------------------------------------
// Applique une couleur en OpenGL à partir d'une couleur Framework Apple
// ------------------------------------------------------------------------------------------------------------------------------------
+(void) setUIColor: (UIColor *)uicolor
{
	CGColorRef color = uicolor.CGColor;
	int numComponents = CGColorGetNumberOfComponents(color);

	if (numComponents == 2)
	{
		const CGFloat * components = CGColorGetComponents (color);
		CGFloat all = components[0];
		CGFloat alpha = components[1];

		glColor4f(all,all, all, alpha);
	}
	else
	{
		const CGFloat * components = CGColorGetComponents (color);
		CGFloat red = components[0];
		CGFloat green = components[1];
		CGFloat blue = components[2];
		CGFloat alpha = components[3];
		glColor4f (red, green, blue, alpha);
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Dessine un texte en OpenGL
// ------------------------------------------------------------------------------------------------------------------------------------
+(void) drawText: (NSString*)theString AtX: (float)x Y: (float)y WithFontSize: (int)fontSize AndTextColor: (UIColor *)foreColor
{
	// Use black
	[GLTool setUIColor: foreColor];

	// Set up texture
	Texture2D * statusTexture = [[Texture2D alloc] initWithString: theString
													   dimensions: CGSizeMake (150, 150)
														alignment: UITextAlignmentLeft
														 fontName: @"Helvetica"
														 fontSize: fontSize];

	// Bind texture
	glBindTexture(GL_TEXTURE_2D, [statusTexture name]);

	// Enable modes needed for drawing
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);

	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	// Draw
	[statusTexture drawInRect: CGRectMake(x, y-1, 1, 1)];

	// Disable modes so they don't interfere with other parts of the program
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);

	[statusTexture release];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// http://trandangkhoa.blogspot.com/2009/07/iphone-os-drawing-image-and-stupid.html ???
// ------------------------------------------------------------------------------------------------------------------------------------
+(void) createGLTexture: (GLuint *)texName fromUIImage: (UIImage *)img
{
	GLuint imgW, imgH, texW, texH;

	imgW = CGImageGetWidth (img.CGImage);
	imgH = CGImageGetHeight (img.CGImage);

	// Find smallest possible powers of 2 for our texture dimensions
	// Attention : les dimensions de votre image doivent être des puissances de 2. 64x64 est un bon candidat, alors que 30x30 non.
	// Rappel : 1, 2, 4, 8, 16, 32, 64, 128, ... (64x128 marche !)
	for (texW = 1; texW < imgW; texW *= 2) ;
	for (texH = 1; texH < imgH; texH *= 2) ;

	// Allocated memory needed for the bitmap context
	GLubyte * spriteData = (GLubyte *) calloc (texH, texW * 4);	// 4 car RVBA

	// Uses the bitmap creation function provided by the Core Graphics framework.
	// When you call this function, Quartz creates a bitmap drawing environment—that is, a bitmap context—to your specifications. When you
	// draw into this context, Quartz renders your drawing as bitmapped data in the specified block of memory.
	// Return Value : A new bitmap context, or NULL if a context could not be created. You are responsible for releasing this object using
	// CGContextRelease.
	CGContextRef spriteContext = CGBitmapContextCreate( spriteData,
													   texW,
													   texH,
													   8, 									// bitsPerComponent : 32-bit pixel format and an RGB color space
													   texW * 4, 							// The number of bytes of memory to use per row of the bitmap
													   CGImageGetColorSpace(img.CGImage),  // The color space to use for the bitmap context
													   kCGImageAlphaPremultipliedLast);

	// Translate and scale the context to draw the image upside-down (conflict in flipped-ness between GL textures and CG contexts)
	// Quartz 2d uses a different co-ordinate system, where the origin is in the lower left corner.
	CGContextTranslateCTM (spriteContext, 0.0f, texH);
	// The x co-ordinate system matches, so you will need to flip the y co-ordinates. passing negative values to flip the image
	//CGContextScaleCTM (spriteContext, 1.0, -1.0);
	CGContextScaleCTM (spriteContext, (1.0f * texW) / imgW, (-1.0f * texH) / imgH); // Mise à l'échelle + retournement

	// After you create the context, you can draw the sprite image to the context.
	CGContextDrawImage(spriteContext, CGRectMake (0.0f, 0.0f, imgW, imgH), img.CGImage);
	//CGContextDrawImage (spriteContext, CGRectMake (0.0f, 0.0f, imgW - 1.0f, imgH - 1.0f), img.CGImage); // ???

	/*
	 // En principe il est possible de faire la même chose en une seule instruction (sauf la mise à l'échelle)
	 [img drawInRect: CGRectMake(0.0f, 0.0f, imgW, imgH)];
	 */

	// You don't need the context at this point, so you need to release it to avoid memory leaks.
	CGContextRelease (spriteContext);

	// Use OpenGL ES to generate a name for the texture.
	// generates the texture handle in the second parameter
	glGenTextures (1, texName);

	// Bind the texture name. Set our Texture handle as current
	// This means that all subsequent texture operations will use the specified texture.
	glBindTexture (GL_TEXTURE_2D, *texName);

	// Specify a 2D texture image, provideing the a pointer to the image data in memory
	// On envoit les données de texture à OpenGL :
	// - target : quasiment toujours  GL_TEXTURE_2D
	// - level : le nombre de détails de la texture. 0 signifie que l'on autorise le maximum de l'image
	// - internalformat : internalformat et format doivent être les mêmes. Utilisez GL_RGBA
	// - width : largeur
	// - height : hauteur
	// - border : OpenGL ES ne supportant pas les "border", doit toujours être à 0
	// - format : doit être le même que internalformat
	// - type : le type de chaque pixel. Ici, Unsigned Byte, car l'on est en RVBA
	// - pixels : pointeur vers les données
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, texW, texH, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

	// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	// The next two lines tell OpenGL what type of filtering to use when the image is larger (GL_TEXTURE_MAG_FILTER) or stretched on
	// the screen than the original texture, or when it's smaller (GL_TEXTURE_MIN_FILTER) on the screen than the actual texture. I
	// usually use GL_LINEAR for both. This makes the texture look smooth way in the distance, and when it's up close to the screen.
	// Using GL_LINEAR requires alot of work from the processor/video card, so if your system is slow, you might want to use GL_NEAREST.
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Linear Filtering
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	// On en a fini avec spriteData, on peut libérer la mémoire allouée
	free (spriteData);
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Convertit un buffer d'éléments kInputDataType en tableau Vertex OpenGL
// ------------------------------------------------------------------------------------------------------------------------------------
+(GLfloat) convertInputBuffer: (kInputDataType *)buffer toVertex: (GLfloat *)vertex fromMinIndex: (UInt16)minIndex withNbPoints: (UInt16)nbPoints
{
	GLfloat maxBufferValue = fabsf (buffer [minIndex]);

	for (UInt16 i = minIndex; i < minIndex + nbPoints; i++)
	{
		*vertex++ = i;
		*vertex++ = buffer [i];

		if (maxBufferValue < fabsf (buffer [i]))
		{
			maxBufferValue = fabsf (buffer [i]);
		}
	}

	return maxBufferValue;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Convertit un buffer d'éléments kOutputDataType en tableau Vertex OpenGL
// ------------------------------------------------------------------------------------------------------------------------------------
+(GLfloat) convertOutputBuffer: (kOutputDataType *)buffer toVertex: (GLfloat *)vertex fromMinIndex: (UInt16)minIndex withNbPoints: (UInt16)nbPoints
{
	GLfloat maxBufferValue = fabsf (buffer [minIndex]);

	for (UInt16 i = minIndex; i < minIndex + nbPoints; i++)
	{
		*vertex++ = i;
		*vertex++ = buffer [i];

		if (maxBufferValue < fabsf (buffer [i]))
		{
			maxBufferValue = fabsf (buffer [i]);
		}
	}

	return maxBufferValue;
}


@end
