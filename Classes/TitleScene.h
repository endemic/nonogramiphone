//
//  TitleScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"
#import "CocosDenshion.h"
#import "SimpleAudioEngine.h"

@interface TitleScene : CCScene { }
@end

@interface TitleLayer : CCLayer 
{
	bool iPad;
}

- (void)goToLevelSelect:(id)sender;
- (void)goToTutorial:(id)sender;
- (void)goToOptions:(id)sender;
- (void)goToCredits:(id)sender;
@end

