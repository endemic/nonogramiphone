//
//  LevelManager.m
//  Nonograms
//
//  Created by Nathan Demick on 4/5/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "LevelManager.h"


@implementation LevelManager

@synthesize currentLevel;

// Holds singleton class instance
static LevelManager *sharedInstance = nil;

// Class method that provides access to shared instance
+(LevelManager *)sharedInstance
{
	// Lock the object
	@synchronized(self)
	{
		if (sharedInstance == nil)
		{
			[[self alloc] init];
		}
	}
	return sharedInstance;
}

// This is called when you alloc an object.  To protect against instances of this class being
// allocated outside of the sharedGameStateInstance method, this method checks to make sure
// that the sharedGameStateInstance is nil before allocating and initializing it.  If it is not
// nil then nil is returned and the instance would need to be obtained through the sharedGameStateInstance method
+(id) allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if (sharedInstance == nil)
		{
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;
		}
	}
	return nil;
}

-(id) copyWithZone:(NSZone *)zone 
{
	return self;
}
	
-(id) retain 
{
	return self;
}
	
-(unsigned) retainCount 
{
	return UINT_MAX;  //denotes an object that cannot be released
} 
	
-(void) release 
{
	//do nothing
}
	
-(id) autorelease 
{
	return self;
}
			
@end
