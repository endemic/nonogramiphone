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
	CCSprite *horizontalHighlight, *verticalHighlight;
	CGPoint startPoint, previousPoint, cursorPoint;
	int blockSize, currentRow, currentColumn;
	
	// Tile map layer that contains the puzzle
	CCTMXLayer *tileMapLayer;
	
	// 0 for mark, 1 for fill
	int tapAction;
	
	// For debuggin' the position of a person's finger!
	CCSprite *pixelTarget;
	
	// For timer calculation/display
	int minutesLeft, secondsLeft;
	CCLabel *minutesLeftLabel, *secondsLeftLabel;
}

@end