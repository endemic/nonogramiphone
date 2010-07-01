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

@synthesize restoreLevel, currentRow, currentColumn, minutesLeft, secondsLeft, hits, misses, blockStatus, fillButtonSelected;

SYNTHESIZE_SINGLETON_FOR_CLASS(GameState);

- (id)init 
{
	if ((self = [super init])) 
	{
		// Set some default values here... probably zeros or whatever, since they'll be re-written
		blockStatus = [[NSMutableArray arrayWithCapacity:100] retain];		// Equivalent of a 10x10 2D array
		for (int i = 0; i < 100; i++) 
			[blockStatus addObject:[NSNumber numberWithInt:0]];	// Populate the array! arrayWithCapacity is only a "guideline"
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
	[coder encodeBool:self.restoreLevel forKey:@"restoreLevel"];
	[coder encodeBool:self.fillButtonSelected forKey:@"fillButtonSelected"];
	[coder encodeInt:self.currentRow forKey:@"currentRow"];
	[coder encodeInt:self.currentColumn forKey:@"currentColumn"];
	[coder encodeInt:self.minutesLeft forKey:@"minutesLeft"];
	[coder encodeInt:self.secondsLeft forKey:@"secondsLeft"];
	[coder encodeInt:self.hits forKey:@"hits"];
	[coder encodeInt:self.misses forKey:@"misses"];
	[coder encodeObject:self.blockStatus forKey:@"blockStatus"];
	[coder encodeBool:paused forKey:@"paused"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super init])) 
	{
		self.restoreLevel = [coder decodeBoolForKey:@"restoreLevel"];
		self.fillButtonSelected = [coder decodeBoolForKey:@"fillButtonSelected"];
		self.currentRow = [coder decodeIntForKey:@"currentRow"];
		self.currentColumn = [coder decodeIntForKey:@"currentColumn"];
		self.minutesLeft = [coder decodeIntForKey:@"minutesLeft"];
		self.secondsLeft = [coder decodeIntForKey:@"secondsLeft"];
		self.hits = [coder decodeIntForKey:@"hits"];
		self.misses = [coder decodeIntForKey:@"misses"];
		self.blockStatus = [coder decodeObjectForKey:@"blockStatus"];
		paused = [coder decodeBoolForKey:@"paused"];
	}
	return self;
}

@end
