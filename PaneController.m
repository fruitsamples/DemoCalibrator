//
//  PaneController.m
//  Calibrator
//
//  Created by David Hayward on Mon Nov 18 2002.
//  Copyright (c) 2002 Apple Computer, Inc.. All rights reserved.
//

#import "PaneController.h"


@implementation PaneController

- (PaneController*) initWithAssistant:(id)asst
{
	self = [super init];
	_assistant = asst;
	return self;
}


- (NSString*) bulletString
{
	NSString* s = NSStringFromClass([self class]);
	s = [NSString stringWithFormat:@"%@Bullet",s];
	return NSLocalizedString(s,nil);
}

- (NSString*) titleString
{
	NSString* s = NSStringFromClass([self class]);
	s = [NSString stringWithFormat:@"%@Title",s];
	return NSLocalizedString(s,nil);
}

- (BOOL) shouldSkip
	{ return NO; }

- (BOOL) quitSafe
	{ return NO; }

- (NSString*) nibName
	{ return NSStringFromClass([self class]); }


- (void) loadPaneNib
{
	if (!_view)
	{
		NSString* nibName = [self nibName];
		if ([NSBundle loadNibNamed:nibName owner:self]==NO)
			NSLog(@"A problem occured while loading the nib %@", nibName);
	}
}


- (id) view
	{ [self loadPaneNib]; return _view; }


- (id) initialFirstResponder
	{ return _initialFirstResponder; }


- (id) responderChainBegin
{
	NSView*			begin = nil;
	NSArray*		subviews = [[self view] subviews];
	NSEnumerator*	e = [subviews objectEnumerator];
	NSView*			v;
	
	// find a view that has an nextKeyView but
	// no other views have it for the nextKeyView
	while (begin==nil && (v=[e nextObject]))
	{
		if ([v nextKeyView])
		{
			NSView*			prev = nil;
			NSEnumerator*	e2 = [subviews objectEnumerator];
			NSView*			v2;
			while (prev==nil && (v2=[e2 nextObject]))
				if ([v2 nextKeyView] == v)
					prev = v2;
			
			if (prev == nil)
				begin = v;
		}
	}
	
	// no nextKeyViews were found so just use the first subview
	// that can accept and has a target or a delegate
	if (begin==nil)
	{
		e = [subviews objectEnumerator];
		while (begin==nil && (v=[e nextObject]))
		{
			if ([v acceptsFirstResponder])
				if ([v target] || ([v respondsToSelector:@selector(delegate)] && [v delegate]))
					begin = v;
		}
	}
	return begin;
}

- (id) responderChainEnd
{
	id end = [self responderChainBegin];
	while ([end nextKeyView] && [[end nextKeyView] isDescendantOf:[self view]])
		end = [end nextKeyView];
	return end;
}


//	Overload these methods to update the pane's UI when it is loaded
//	or to update the assistant's data with the pane is unloaded
//	The direction is YES if the user clicked the "Continue" button
//	or NO if the user clicked the "Back" button
//
- (void) paneDidLoad:(BOOL)direction
	{ }

- (void) paneDidUnload:(BOOL)direction
	{ }


//	Overload this method to stop navigation to the next/prev pane
//
- (BOOL) shouldPrevPane
	{ return YES; }

- (BOOL) shouldNextPane
	{ return YES; }


- (void) performNext
{
	[[NSApp delegate] next:self];
}

@end
