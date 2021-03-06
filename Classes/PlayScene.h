//
//  PlayScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/25/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"
#import "CocosDenshion.h"
#import "SimpleAudioEngine.h"
#import "GameDataManager.h"
#import "CCRadioMenu.h"

#define MARK 0
#define FILL 1

#define BLANK 0
#define MARKED 1
#define FILLED 2

@interface PlayScene : CCScene { }
@end

@interface PlayLayer : CCLayer 
{
	// Convenience var to determine if on tablet
	bool iPad;
	
	// Sprites that show the current cursor location
	CCSprite *horizontalHighlight, *verticalHighlight;
	
	// Points that store player movement
	CGPoint startPoint, previousPoint, cursorPoint;
	
	// Size (in pixels) of each square in the puzzle
	int blockSize;
	
	// Size (in tiles) of the puzzle
	int puzzleSize;
	
	// Values that store where the player cursor currently is in the puzzle
	int currentRow, currentColumn;
	
	// Stores labels that display clues!
	CCLabel *horizontalClues[10];
	CCLabel *verticalClues[10];
	
	// 2D array of sprites that show marking/filling the puzzle
	CCSprite *blockSprites[10][10];
	
	// 2D array of ints to figure out the current status of the puzzle - prevents having to subclass CCSprite, I guess
	int blockStatus[10][10];
	
	// Tile map layer that contains the puzzle
	CCTMXLayer *tileMapLayer;
	
	// 0 for mark, 1 for fill
	int tapAction;
	
	// Boolean val that tries to prevent mistaken block fills
	bool actionOnPreviousBlock;
	
	// To keep track of a win condition
	int totalBlocksInPuzzle, hits, misses;
	
	// Shows % complete of puzzle
	CCLabel *percentComplete;
	
	// For timer calculation/display
	int minutesLeft, secondsLeft;
	CCLabel *minutesLeftLabel, *secondsLeftLabel;
	
	// Used to obscure the puzzle when the game is paused
	CCSprite *pauseOverlay;
	
	// Determines if the game is paused or playing
	bool paused;
	
	// Lots of crap to try to fix cursor sensitivity issue
	int tapCount;
	
	// Whether or not the player's cursor moved
	bool justMovedCursor;
	
	// Variables that help "lock" movement into either vertical or horizontal movement
	int lockedRow, lockedColumn;
	
	// Whether to lock the "mark" action into filling or erasing
	int lockMark;
}

- (void)markBlock;
- (void)fillBlock;
- (void)wonGame;
- (void)lostGame;
- (void)goToLevelSelect:(id)sender;
- (void)retryLevel:(id)sender;
@end