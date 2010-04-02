//
//  OptionsScene.m
//  Nonograms
//
//  Created by Nathan Demick on 4/2/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "OptionsScene.h"
#import "TitleScene.h"

@implementation OptionsScene

-(id) init
{
	if ((self = [super init]))
	{
		CCSprite *background = [CCSprite spriteWithFile:@"optionsBackground.png"];
		[background setPosition:ccp(160,240)];
		[self addChild:background z:0];
		[self addChild:[OptionsLayer node] z:1];
	}
	return self;
}

@end

@implementation OptionsLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Do stuff here, or whatever
		
		[self setIsTouchEnabled:YES];
	}
	return self;
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end
