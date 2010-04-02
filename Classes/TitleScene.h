//
//  TitleScene.h
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "cocos2d.h"

@interface TitleScene : CCScene { }
@end

@interface TitleLayer : CCLayer { }

-(void) goToLevelSelect: (id)sender;
-(void) goToTutorial: (id)sender;
-(void) goToOptions: (id)sender;

@end

