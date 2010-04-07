//
//  PlayScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/25/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "cocos2d.h"
#import "CocosDenshion.h"
#import "SimpleAudioEngine.h"
#import "LevelManager.h"

#define MARK 0
#define FILL 1

@interface PlayScene : CCScene { }
@end

@interface PlayLayer : CCLayer 
{
	// Sprites that show the current cursor location
	CCSprite *horizontalHighlight, *verticalHighlight;
	
	// Points that store player movement
	CGPoint startPoint, previousPoint, cursorPoint;
	
	// Size (in pixels) of each square in the puzzle
	int blockSize;
	
	// Values that store where the player cursor currently is in the puzzle
	int currentRow, currentColumn;
	
	// Stores labels that display clues!
	CCLabel *horizontalClues[10];
	CCLabel *verticalClues[10];
	
	// Tile map layer that contains the puzzle
	CCTMXLayer *tileMapLayer;
	
	// 0 for mark, 1 for fill
	int tapAction;
	
	// To keep track of a win condition
	int totalBlocksInPuzzle;
	
	// For debuggin' the position of a person's finger!
	CCSprite *pixelTarget;
	
	// For timer calculation/display
	int minutesLeft, secondsLeft;
	CCLabel *minutesLeftLabel, *secondsLeftLabel;
}

@end