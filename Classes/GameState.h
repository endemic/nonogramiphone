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

@interface GameState : NSObject <NSCoding> 
{
	int currentLevel;
	
	// Values that store where the player cursor currently is in the puzzle
	int currentRow, currentColumn;
	
	// Time remaining
	int minutesLeft, secondsLeft;
	
	// 2D array of ints to figure out the current status of the puzzle
	int blockStatus[10][10];
	
	// To keep track of a win condition
	int hits, misses;
}

+ (void)loadState;
+ (void)saveState;

@end
