//
// SynthesizeSingleton.h
//  DynOnTrack
//
//  Created by Gérald GUIONY on 9/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

// ------------------------------------------------------------------------------------------------------------------------------------
// If you #import this header at the top of a class implementation, then all you need to do is write:
// SYNTHESIZE_SINGLETON_FOR_CLASS(MyClassName);
// inside the @implementation MyClassName declaration and your class will become a singleton. You will also need to add the line:
// +(MyClassName *) sharedInstance;
// to the header file for MyClassName so the singleton accessor method can be found from other source files if they #import the header.
// Once your class is a singleton, you can access the instance of it using the line:
// [MyClassName sharedInstance];
//
// Note: A singleton does not need to be explicitly allocated or initialized (the alloc and init methods will be called automatically
// on first access) but you can still implement the default init method if you want to perform initialization.
//
// In a 'strict' implementation, a singleton is the sole allowable instance of a class in the current process. But you can also have
// a more flexible singleton implementation in which a factory method always returns the same instance, but you can allocate and
// initialize additional instances.
// ------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------------------
// Flexible implementation of a singleton
//
// - Implement the base protocol methods copyWithZone:, release, retain, retainCount, and autorelease to do the appropriate things to
// ensure singleton status. (The last four of these methods apply to memory-managed code, not to garbage-collected code.)
// ------------------------------------------------------------------------------------------------------------------------------------
#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
 \
static classname *shared##classname = nil; \
 \
+(classname *) sharedInstance \
{ \
	@synchronized(self) \
	{ \
		if (shared##classname == nil) \
		{ \
			shared##classname = [[self alloc] init]; /* assignment not done here */ \
		} \
	} \
	 \
	return shared##classname; \
} \
 \
+(id) allocWithZone: (NSZone *)zone \
{ \
	@synchronized(self) \
	{ \
		if (shared##classname == nil) \
		{ \
			shared##classname = [super allocWithZone:zone]; \
			return shared##classname; /* assignment and return on first allocation */ \
		} \
	} \
	 \
	return nil; /* on subsequent allocation attempts return nil */ \
} \
 \
-(id) copyWithZone: (NSZone *)zone \
{ \
	return self; \
} \
 \
-(id) retain \
{ \
	return self; \
} \
 \
-(NSUInteger) retainCount \
{ \
	return NSUIntegerMax; /* denotes an object that cannot be release */ \
} \
 \
-(void) release \
{ \
	/* do nothing */ \
} \
 \
-(id) autorelease \
{ \
	return self; \
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Strict implementation of a singleton
//
// - Override the allocWithZone: method to ensure that another instance is not allocated if someone tries to allocate and initialize an
// instance of your class directly instead of using the class factory method. Instead, just return the shared object.
// Alloc utilise allocWithZone : The new instance is allocated from the default zone
// ------------------------------------------------------------------------------------------------------------------------------------
#define SYNTHESIZE_STRICT_SINGLETON_FOR_CLASS(classname) \
 \
static classname *shared##classname = nil; \
 \
+(classname *) sharedInstance \
{ \
	if (shared##classname == nil) \
	{ \
		shared##classname = [[super allocWithZone:NULL] init]; \
	} \
	return shared##classname; \
} \
 \
/* Returns a new instance of the receiving class where memory for the new instance is allocated from a given zone */ \
/* If zone is nil, the new instance will be allocated from the default zone (as returned by NSDefaultMallocZone) */ \
+(id) allocWithZone: (NSZone *)zone \
{ \
	return [[self sharedInstance] retain]; \
} \
 \
-(id) copyWithZone: (NSZone *)zone \
{ \
	return self; \
} \
 \
-(id) retain \
{ \
	return self; \
} \
 \
-(NSUInteger) retainCount \
{ \
	return NSUIntegerMax; /* denotes an object that cannot be release */ \
} \
 \
-(void) release \
{ \
	/* do nothing */ \
} \
 \
-(id) autorelease \
{ \
	return self; \
}
