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
	// The current level is actually saved in the NSUserDefaults
	// NSInteger currentLevel;
	
	// Variable we check to see if player quit in the middle of a puzzle
	bool restoreLevel;
	
	// Values that store where the player cursor currently is in the puzzle
	int currentRow, currentColumn;
	
	// Time remaining
	int minutesLeft, secondsLeft;
	
	// 2D array of ints to figure out the current status of the puzzle
	//int blockStatus[10][10];
	NSArray *blockStatus;
	
	// To keep track of a win condition
	int hits, misses;
}

@property (readwrite) bool restoreLevel;
@property (readwrite) int currentRow;
@property (readwrite) int currentColumn;
@property (readwrite) int minutesLeft;
@property (readwrite) int secondsLeft;
@property (readwrite) int hits;
@property (readwrite) int misses;
@property (readwrite, assign) NSArray *blockStatus;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(GameState);

+ (void)loadState;
+ (void)saveState;

@end
