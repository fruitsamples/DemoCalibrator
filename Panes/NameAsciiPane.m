//
//  NameAsciiPane.m
//  Calibrator
//
//  Created by David Hayward on Thu Dec 12 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "NameAsciiPane.h"


@implementation NameAsciiPane

- (BOOL) shouldSkip
	{ return [[_assistant name] canBeConvertedToEncoding:NSASCIIStringEncoding]; }


- (void) paneDidLoad:(BOOL)direction
{
	[_name setStringValue:[_assistant name]];
	[_nameAscii setStringValue:[_assistant nameAscii]];
}

- (void) paneDidUnload:(BOOL)direction
	{ [_assistant setName:[_name stringValue] andAsciiName:[_nameAscii stringValue]]; }


- (BOOL) shouldNextPane
{
	NSTextView*	curEditor = (NSTextView*)[_nameAscii currentEditor];
	return ((curEditor && [curEditor hasMarkedText]==YES) ||
			[[_nameAscii stringValue] length]>0);
}

- (BOOL) shouldPrevPane
	{ return [self shouldNextPane]; }


- (void)controlTextDidChange:(NSNotification *)obj
{
	if ([obj object] == _nameAscii)
	{
		NSString* oldstr = [_nameAscii stringValue];
		
		if ([oldstr length] > 50)
		{
			oldstr = [oldstr substringToIndex:50];
			[_nameAscii setStringValue:oldstr];
		}
		
		if ([oldstr canBeConvertedToEncoding:NSASCIIStringEncoding])
			return;
		
		NSData*   data = [oldstr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString* newstr = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
		[_nameAscii setStringValue:newstr];
	}
}

@end


#pragma mark -


#import <Carbon/Carbon.h>

@implementation RomanTextField

- (void) _addObserver {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [center removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
    if ([self window]) {
        [center addObserver:self selector:@selector(windowDidResignKey:)
						name:NSWindowDidResignKeyNotification  object:[self window]];
        [center addObserver:self selector:@selector(windowDidBecomeKey:)
						name:NSWindowDidBecomeKeyNotification  object:[self window]];
    }
}

- (void) _restoreKeyboardMenu {
    KeyScript(smKeyEnableKybds);
    KeyScript(smKeySwapScript);
}

// set the keyboard to roman input and disallow switching back
- (void) _restrictKeyboardMenu {
    KeyScript(smKeyRoman);
    KeyScript(smKeyDisableKybdSwitch);
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self _addObserver];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (BOOL) becomeFirstResponder {
    BOOL result = [super becomeFirstResponder];
    if (result)
        [self _restrictKeyboardMenu];
    return result;
}

- (void) textDidEndEditing:(NSNotification *)notif {
    [super textDidEndEditing:notif];
    // re-enable keyboard switching if we're no longer being edited
    if ([self currentEditor] == nil && [[self window] isVisible])
        [self _restoreKeyboardMenu];
}

- (void) windowDidResignKey:(NSNotification *)notif {
    if ([self currentEditor] != nil)
        [self _restoreKeyboardMenu];
}

- (void) windowDidBecomeKey:(NSNotification *)notif {
    if ([self currentEditor] != nil)
        [self _restrictKeyboardMenu];
}

- (void) setEnabled:(BOOL)flag {
    if (!flag && [self currentEditor] != nil)
        [self _restoreKeyboardMenu];
    [super setEnabled:flag];
}

@end