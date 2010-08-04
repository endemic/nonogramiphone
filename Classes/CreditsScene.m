//
//  CreditsScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "CreditsScene.h"
#import "TitleScene.h"

@implementation CreditsScene

-(id) init
{
	if ((self = [super init]))
	{
		[self addChild:[CreditsLayer node] z:0];
	}
	return self;
}

@end

@implementation CreditsLayer

- (id)init
{
	if ((self = [super init]))
	{
		// Show credits background here
		CCSprite *background = [CCSprite spriteWithFile:@"creditsBackground.png"];
		[background setPosition:ccp(160, 240)];
		[self addChild:background z:0];
		
		[self setIsTouchEnabled:YES];
		
		/**
		 Art, code & music by Nathan Demick
		 Special thanks to Andy, Ben, & Andrew.
		 */
	}
	return self;
}

- (void)goToTitle:(id)sender
{
	[[CCDirector sharedDirector] replaceScene:[TitleScene node]];
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end
