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
	CGPoint previousPoint, fingerPoint;
	int blockSize;
}

@end