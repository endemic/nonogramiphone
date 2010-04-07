//
//  CCRadioMenu.m
//  MathNinja
//
//  Created by Ray Wenderlich on 2/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CCRadioMenu.h"

@implementation CCRadioMenu

- (void)setSelectedItem:(CCMenuItem *)item {
    [selectedItem unselected];
    selectedItem = item;    
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
 
    if ( state != kMenuStateWaiting ) return NO;
    
    CCMenuItem *curSelection = [self itemForTouch:touch];
    [curSelection selected];
    _curHighlighted = curSelection;
    
    if (_curHighlighted) {
        if (selectedItem != curSelection) {
            [selectedItem unselected];
        }
        state = kMenuStateTrackingTouch;
        return YES;
    }
    return NO;
    
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {

    NSAssert(state == kMenuStateTrackingTouch, @"[Menu ccTouchEnded] -- invalid state");
	
    CCMenuItem *curSelection = [self itemForTouch:touch];
    if (curSelection != _curHighlighted && curSelection != nil) {
        [selectedItem selected];
        [_curHighlighted unselected];
        _curHighlighted = nil;
        state = kMenuStateWaiting;
        return;
    } 
    
    selectedItem = _curHighlighted;
    [_curHighlighted activate];
    _curHighlighted = nil;
    
	state = kMenuStateWaiting;
    
}

- (void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
 
    NSAssert(state == kMenuStateTrackingTouch, @"[Menu ccTouchCancelled] -- invalid state");
	
	[selectedItem selected];
    [_curHighlighted unselected];
    _curHighlighted = nil;
	
	state = kMenuStateWaiting;
    
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(state == kMenuStateTrackingTouch, @"[Menu ccTouchMoved] -- invalid state");
	
	CCMenuItem *curSelection = [self itemForTouch:touch];
    if (curSelection != _curHighlighted && curSelection != nil) {       
        [_curHighlighted unselected];
        [curSelection selected];
        _curHighlighted = curSelection;        
        return;
    }
    
}

@end
