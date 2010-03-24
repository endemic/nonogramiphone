//
//  Button.h
//  StickWars - Siege
//
//  Created by EricH on 8/3/09.
//  From http://johnehartzog.com/2009/10/easy-to-create-buttons-with-cocos2d/

#import "cocos2d.h"

@interface Button : CCMenu {
}
+ (id)buttonWithText:(NSString*)text atPosition:(CGPoint)position target:(id)target selector:(SEL)selector;
+ (id)buttonWithImage:(NSString*)file atPosition:(CGPoint)position target:(id)target selector:(SEL)selector;
@end

@interface ButtonItem : CCMenuItem {
	CCSprite *back;
	CCSprite *backPressed;
}
+ (id)buttonWithText:(NSString*)text target:(id)target selector:(SEL)selector;
+ (id)buttonWithImage:(NSString*)file target:(id)target selector:(SEL)selector;
- (id)initWithText:(NSString*)text target:(id)target selector:(SEL)selector;
- (id)initWithImage:(NSString*)file target:(id)target selector:(SEL)selector;
@end