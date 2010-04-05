//
//  LevelManager.h
//  Nonograms
//
//  Created by Nathan Demick on 4/5/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "cocos2d.h"

@interface LevelManager : NSObject {

	// Current level
	int currentLevel;
}

@property int currentLevel;

+(LevelManager *)sharedInstance;

@end
