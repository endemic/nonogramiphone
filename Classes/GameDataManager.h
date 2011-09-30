//
//  GameDataManager.h
//  Nonograms
//
//  Created by Nathan Demick on 4/5/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"

@interface GameDataManager : NSObject 
{
	// Current level
	int currentLevel;
	
	// Options for music/sound
	bool playSFX;
	bool playMusic;
	
	// Array of puzzles
	NSArray *levels;
	
	// Flag to check to see if certain functionality should be limited
	bool isDemo;
}

@property int currentLevel;
@property bool playSFX;
@property bool playMusic;
@property (retain) NSArray *levels;
@property bool isDemo;

+(GameDataManager *)sharedManager;

@end
