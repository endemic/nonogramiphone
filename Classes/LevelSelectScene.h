//
//  LevelSelectScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"

@interface LevelSelectScene : CCScene { }
@end

@interface LevelSelectLayer : CCLayer 
{
	NSMutableArray *levelDisplayList;
	//CCSprite *levelDisplayList[15];
	
	// Labels for level data
	CCLabel *headerLabel;
	CCLabel *difficultyLabel;
	CCLabel *attemptsLabel;
	CCLabel *firstTimeLabel;
	CCLabel *bestTimeLabel;
	
	// Prev/next buttons
	CCMenuItem *previousButton;
	CCMenuItem *nextButton;
}

- (void)showNextLevel:(id)sender;
- (void)showPreviousLevel:(id)sender;
- (void)playLevel:(id)sender;
- (void)hideLevelData:(id)sender;
- (void)showLevelData:(id)sender;

@end

