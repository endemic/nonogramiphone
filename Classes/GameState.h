//
//  GameState.h
//  Nonograms
//
//  Created by Nathan Demick on 6/21/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//
// Serializes certain game variables on exit then restores them on game load
// Taken from http://stackoverflow.com/questions/2670815/game-state-singleton-cocos2d-initwithencoder-always-returns-null

#import "cocos2d.h"
#import "SynthesizeSingleton.h"

@interface GameState : NSObject <NSCoding> 
{
	NSInteger currentLevel;
	
	// Values that store where the player cursor currently is in the puzzle
	NSInteger currentRow, currentColumn;
	
	// Time remaining
	NSInteger minutesLeft, secondsLeft;
	
	// 2D array of ints to figure out the current status of the puzzle
	//NSInteger blockStatus[10][10];
	
	// To keep track of a win condition
	NSInteger hits, misses;
}

@property (readwrite) NSInteger currentLevel;
@property (readwrite) NSInteger currentRow;
@property (readwrite) NSInteger currentColumn;
@property (readwrite) NSInteger minutesLeft;
@property (readwrite) NSInteger secondsLeft;
//@property (readwrite) NSInteger blockStatus;
@property (readwrite) NSInteger hits;
@property (readwrite) NSInteger misses;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(GameState);

+ (void)loadState;
+ (void)saveState;

@end
