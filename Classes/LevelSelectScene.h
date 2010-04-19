//
//  LevelSelectScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "cocos2d.h"

@interface LevelSelectScene : CCScene { }
@end

@interface LevelSelectLayer : CCLayer 
{
	//NSMutableArray *levelDisplayList;
	CCSprite *levelDisplayList[15];
}

-(void) showNextLevel: (id)sender;
-(void) showPreviousLevel: (id)sender;
-(void) playLevel: (id)sender;

@end

