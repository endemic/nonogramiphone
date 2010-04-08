//
//  GameDataManager.h
//  Nonograms
//
//  Created by Nathan Demick on 4/5/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "cocos2d.h"

@interface GameDataManager : NSObject 
{
	// Current level
	int currentLevel;
	
	// Options for music/sound
	bool playSFX;
	bool playMusic;
}

@property int currentLevel;
@property bool playSFX;
@property bool playMusic;

+(GameDataManager *)sharedManager;

@end
