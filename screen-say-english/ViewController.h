//
//  ViewController.h
//  screen-say-english
//
//  Created by JasonWu on 2023/8/23.
//

#import <Cocoa/Cocoa.h>
#import "UIElementUtilities.h"
@interface ViewController : NSViewController{
    AXUIElementRef                  _systemWideElement;
    NSPoint                         _lastMousePoint;
    
    NSRegularExpression*             filterTextRegex;
    NSTask*                          sayTask;
    
    NSString*                        lastString;
    
    __unsafe_unretained IBOutlet NSTextView *textView;
}

- (void)performTimerBasedUpdate;

- (void)sayUIElement:(AXUIElementRef)uiElement;

- (void)say:(NSString*) text;

- (void)stopSay;

- (NSString*)filterText:(NSString*) text;

@end

