//
//  GameDataManager.m
//  Nonograms
//
//  Created by Nathan Demick on 4/5/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "GameDataManager.h"


@implementation GameDataManager

@synthesize currentLevel, playSFX, playMusic;

// Holds singleton class instance
static GameDataManager *sharedManager = nil;

// Class method that provides access to shared instance
+(GameDataManager *)sharedManager
{
	// Lock the object
	@synchronized(self)
	{
		if (sharedManager == nil)
		{
			[[self alloc] init];
		}
	}
	return sharedManager;
}

// This is called when you alloc an object.  To protect against instances of this class being
// allocated outside of the sharedGameStateInstance method, this method checks to make sure
// that the sharedGameStateInstance is nil before allocating and initializing it.  If it is not
// nil then nil is returned and the instance would need to be obtained through the sharedGameStateInstance method
+(id) allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if (sharedManager == nil)
		{
			sharedManager = [super allocWithZone:zone];
			return sharedManager;
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
