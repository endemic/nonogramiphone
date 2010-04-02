//
//  PlayScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/25/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "cocos2d.h"

@interface PlayScene : CCScene { }
@end

@interface PlayLayer : CCLayer 
{
	CCSprite *horizontalHighlight, *verticalHighlight;
	CGPoint startPoint, previousPoint, fingerPoint;
	int blockSize;
	bool cursorMoved;
	
	// For timer calculation/display
	int minutesLeft, secondsLeft;
	CCLabel *minutesLeftLabel, *secondsLeftLabel;
}

@end