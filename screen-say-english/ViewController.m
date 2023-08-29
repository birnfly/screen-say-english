//
//  ViewController.m
//  screen-say-english
//
//  Created by JasonWu on 2023/8/23.
//
#import <Cocoa/Cocoa.h>
#import <AppKit/NSAccessibility.h>
#import <Carbon/Carbon.h>

#import "ViewController.h"

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];

    NSDictionary *options = @{(id)CFBridgingRelease(kAXTrustedCheckOptionPrompt): @NO};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
    if (!accessibilityEnabled) {
        NSString *urlString = @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
    }
//
//    if (!AXAPIEnabled())
//    {
//
//        NSAlert *alert = [[NSAlert alloc] init] ;
//
//        [alert setAlertStyle:NSAlertStyleWarning];
//        [alert setMessageText:@"UI Element Inspector requires that the Accessibility API be enabled."];
//        [alert setInformativeText:@"Would you like to launch System Preferences so that you can turn on \"Enable access for assistive devices\"?"];
//        [alert addButtonWithTitle:@"Open System Preferences"];
//        [alert addButtonWithTitle:@"Continue Anyway"];
//        [alert addButtonWithTitle:@"Quit UI Element Inspector"];
//
//        NSInteger alertResult = [alert runModal];
//
//        switch (alertResult) {
//            case NSAlertFirstButtonReturn: {
//                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPreferencePanesDirectory, NSSystemDomainMask, YES);
//                if ([paths count] == 1) {
//                    NSURL *prefPaneURL = [NSURL fileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"UniversalAccessPref.prefPane"]];
//                    [[NSWorkspace sharedWorkspace] openURL:prefPaneURL];
//                }
//            }
//            break;
//
//            case NSAlertSecondButtonReturn: // just continue
//            default:
//                break;
//
//            case NSAlertThirdButtonReturn:
//                [NSApp terminate:self];
//                return;
//                break;
//        }
//    }
    
    NSError* error=nil;
    self->filterTextRegex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9\\s]"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    if(error!=nil){
        NSLog(@"%@", error);
    }


    _systemWideElement = AXUIElementCreateSystemWide();

    [self performTimerBasedUpdate];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (void)performTimerBasedUpdate
{
    [self updateCurrentUIElement];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(performTimerBasedUpdate) userInfo:nil repeats:NO];
}


- (void)updateCurrentUIElement
{
    
    NSString * ax_selectedText=[UIElementUtilities getSelectedText:_systemWideElement];
    if(ax_selectedText!=nil && ![ax_selectedText isEqual:@""]){
        [self say:ax_selectedText];
        return;
    }

    
    // The current mouse position with origin at top right.
    NSPoint cocoaPoint = [NSEvent mouseLocation];
            
    // Only ask for the UIElement under the mouse if has moved since the last check.
    if (!NSEqualPoints(cocoaPoint, _lastMousePoint)) {

    CGPoint pointAsCGPoint = [UIElementUtilities carbonScreenPointFromCocoaScreenPoint:cocoaPoint];

        AXUIElementRef newElement = NULL;
    
        if (AXUIElementCopyElementAtPosition( _systemWideElement, pointAsCGPoint.x, pointAsCGPoint.y, &newElement ) == kAXErrorSuccess
            && newElement) {
                
            [self sayUIElement:newElement];
        }
        
        _lastMousePoint = cocoaPoint;
    }
}

- (void)sayUIElement:(AXUIElementRef)uiElement {
//    NSString * description = [UIElementUtilities stringDescriptionOfUIElement:uiElement];
//    NSString * ax_selectedText=[UIElementUtilities getSelectedText:_systemWideElement];
//    NSString * ax_value=[UIElementUtilities descriptionForUIElement:uiElement attribute:@"AXValue" beingVerbose:false];
//    NSString * ax_description=[UIElementUtilities descriptionForUIElement:uiElement attribute:@"AXDescription" beingVerbose:false];
//    NSString * ax_title=[UIElementUtilities descriptionForUIElement:uiElement attribute:@"AXTitle" beingVerbose:false];

    NSString* str=[UIElementUtilities descriptionForUIElement:uiElement attribute:@"AXValue" beingVerbose:false];
    if(str == nil || [str isEqual:@""]){
        str=[UIElementUtilities descriptionForUIElement:uiElement attribute:@"AXDescription" beingVerbose:false];
    }
    if(str == nil || [str isEqual:@""]){
        str=[UIElementUtilities descriptionForUIElement:uiElement attribute:@"AXTitle" beingVerbose:false];
    }
    if(str != nil && ![str isEqual:@""]){
        [self say:str];
    }else{
    }
    
}

- (NSString*)filterText:(NSString*) text{
    //过滤英文以外的字符
    
    if(text==nil){
        return nil;
    }

    
    NSString* newText = [self->filterTextRegex stringByReplacingMatchesInString:text
                                                    options:NSMatchingReportProgress
                                                      range:NSMakeRange(0, text.length)
                                               withTemplate:@""];
    
    return newText;
}

- (void)say:(NSString*) text{
    text=[self filterText:text];

    if(text==nil || [text isEqual: self->lastString]){
        return;
    }
    
    self->lastString=text;
    
    //调用系统命令发出声音
    [self stopSay];
    
    [textView setString:text];
    
    //脚本路径
    self->sayTask = [[NSTask alloc] init];
    [self->sayTask setLaunchPath: @"/usr/bin/say"];
    NSArray *arguments =@[[text stringByAppendingString:@".\n."]];
    [self->sayTask setArguments: arguments];
    [self->sayTask launch];
    
}

- (void)stopSay{
    //取消声音
    if(self->sayTask!=nil){
        [self->sayTask terminate];
        self->sayTask=nil;
    }
}

@end
