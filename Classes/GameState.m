//
//  GameState.m
//  Nonograms
//
//  Created by Nathan Demick on 6/21/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "SynthesizeSingleton.h"
#import "GameState.h"

@implementation GameState

@synthesize currentLevel, currentRow, currentColumn, minutesLeft, secondsLeft, hits, misses;

SYNTHESIZE_SINGLETON_FOR_CLASS(GameState);

- (id)init 
{
	if ((self = [super init])) 
	{
		// Set some default values here... probably zeros or whatever, since they'll be re-written
		self.currentLevel = 1;
	}
	return self;
}

+ (void)loadState
{
	@synchronized([GameState class]) 
	{
		// just in case loadState is called before GameState inits
		if(!sharedGameState)
			[GameState sharedGameState];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		// NSString *file = [documentsDirectory stringByAppendingPathComponent:kSaveFileName];
		NSString *file = [documentsDirectory stringByAppendingPathComponent:@"GameState.bin"];
		Boolean saveFileExists = [[NSFileManager defaultManager] fileExistsAtPath:file];
		
		if(saveFileExists) 
		{
			// don't need to set the result to anything here since we're just getting initwithCoder to be called.
			// if you try to overwrite sharedGameState here, an assert will be thrown.
			[NSKeyedUnarchiver unarchiveObjectWithFile:file];
		}
	}
}

+ (void)saveState
{
	@synchronized([GameState class]) 
	{  
		GameState *state = [GameState sharedGameState];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		// NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:kSaveFileName];
		NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:@"GameState.bin"];
		
		[NSKeyedArchiver archiveRootObject:state toFile:saveFile];
	}
}

#pragma mark -
#pragma mark NSCoding Protocol Methods

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:self.currentRow forKey:@"currentRow"];
	[coder encodeInt:self.currentColumn forKey:@"currentColumn"];
	[coder encodeBool:self.minutesLeft forKey:@"minutesLeft"];
	[coder encodeBool:self.secondsLeft forKey:@"secondsLeft"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil) 
	{
		self.currentRow = [coder decodeIntForKey:@"currentRow"];
		self.currentColumn = [coder decodeIntForKey:@"currentColumn"];
		self.minutesLeft = [coder decodeBoolForKey:@"minutesLeft"];
		self.secondsLeft = [coder decodeBoolForKey:@"secondsLeft"];
	}
	return self;
}

@end
