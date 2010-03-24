//
//  Button.m
//  StickWars - Siege
//
//  Created by EricH on 8/3/09.
//

#import "Button.h"


@implementation Button
+ (id)buttonWithText:(NSString*)text atPosition:(CGPoint)position target:(id)target selector:(SEL)selector {
	CCMenu *CCMenu = [CCMenu CCMenuWithItems:[ButtonItem buttonWithText:text target:target selector:selector], nil];
	CCMenu.position = position;
	return CCMenu;
}

+ (id)buttonWithImage:(NSString*)file atPosition:(CGPoint)position target:(id)target selector:(SEL)selector {
	CCMenu *CCMenu = [CCMenu CCMenuWithItems:[ButtonItem buttonWithImage:file target:target selector:selector], nil];
	CCMenu.position = position;
	return CCMenu;
}
@end

@implementation ButtonItem
+ (id)buttonWithText:(NSString*)text target:(id)target selector:(SEL)selector {
	return [[[self alloc] initWithText:text target:target selector:selector] autorelease];
}

+ (id)buttonWithImage:(NSString*)file target:(id)target selector:(SEL)selector {
	return [[[self alloc] initWithImage:file target:target selector:selector] autorelease];
}

- (id)initWithText:(NSString*)text target:(id)target selector:(SEL)selector {
	if((self = [super initWithTarget:target selector:selector])) {
		back = [[CCSprite spriteWithFile:@"button.png"] retain];
		back.anchorPoint = ccp(0,0);
		backPressed = [[CCSprite spriteWithFile:@"button_p.png"] retain];
		backPressed.anchorPoint = ccp(0,0);
		[self addChild:back];
		
		self.contentSize = back.contentSize;
		
		CCLabel *textLabel = [CCLabel labelWithString:text fontName:@"take_out_the_garbage" fontSize:22];
		textLabel.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
		textLabel.anchorPoint = ccp(0.5, 0.3);
		[self addChild:textLabel z:1];
	}
	return self;
}

- (id)initWithImage:(NSString*)file target:(id)target selector:(SEL)selector {
	if((self = [super initWithTarget:target selector:selector])) {
		
		back = [[CCSprite spriteWithFile:@"button.png"] retain];
		back.anchorPoint = ccp(0,0);
		backPressed = [[CCSprite spriteWithFile:@"button_p.png"] retain];
		backPressed.anchorPoint = ccp(0,0);
		[self addChild:back];
		
		self.contentSize = back.contentSize;
		
		CCSprite* image = [CCSprite spriteWithFile:file];
		[self addChild:image z:1];
		image.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
	}
	return self;
}

-(void) selected {
	[self removeChild:back cleanup:NO];
	[self addChild:backPressed];
	[super selected];
}

-(void) unselected {
	[self removeChild:backPressed cleanup:NO];
	[self addChild:back];
	[super unselected];
}

// this prevents double taps
- (void)activate {
	[super activate];
	[self setIsEnabled:NO];
	[self schedule:@selector(resetButton:) interval:0.5];
}

- (void)resetButton:(ccTime)dt {
	[self unschedule:@selector(resetButton:)];
	[self setIsEnabled:YES];
}

- (void)dealloc {
	[back release];
	[backPressed release];
	[super dealloc];
}

@end