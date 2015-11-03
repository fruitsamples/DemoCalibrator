//
//  AppDelegate.m
//  Calibrator
//
//  Created by David Hayward on Sun Nov 17 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate


- (void) dealloc
{
	[_panesArray release];
	[_panesStack release];
	[_assistant release];
	[_clickMeWindows release];
	[super dealloc];
}


#pragma mark -


- (void) quitWithError:(int)reason
{
	if (reason == 1)
	{
		// put up error dialog
		NSRunAlertPanel(NSLocalizedString(@"CanNotCalibrateDisplay",nil), 
						NSLocalizedString(@"FactoryProfileNotFound",nil), 
						NSLocalizedString(@"Quit",nil), 
						nil, nil);
	}
	exit(1);
}

- (void)quitSheetDidDiss:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)ctx 
{
	if (returnCode==NSAlertDefaultReturn)
		[_window close];
}


- (BOOL) windowShouldClose:(id)sender
{
	if ([[self currPane] quitSafe])
		return YES;
	
	NSBeginAlertSheet(
				NSLocalizedString(@"DoYouWantToQuit", "COMMENT"), 
				NSLocalizedString(@"Quit", "COMMENT"), 
				NSLocalizedString(@"Continue", "COMMENT"), 
				nil,  // other button
				_window, 
				self, // modal delegate
				nil,// didEnd selector, 
				@selector(quitSheetDidDiss:returnCode:context:), 
				nil,  // context info
				@""); // message string
	return NO;
}


- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication*)sender
{
	if ([NSApp mainWindow]==_window)
	{
		[[NSApp mainWindow] performClose:self];
		return NSTerminateCancel;
	}
	return NSTerminateNow;
}


- (void)applicationWillTerminate:(NSNotification*)aNotification
{
	[NSApp setDelegate:nil];
	[self release];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
	{ return YES; }


- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
	NSAppleEventManager* evtMgr = [NSAppleEventManager sharedAppleEventManager];
	if ([evtMgr respondsToSelector:@selector(currentAppleEvent)])
		_id = [[[evtMgr currentAppleEvent] descriptorForKeyword:keyAEPropData] int32Value];
	
	if (_id)
		[self beginCalibration];
	else
	{
		SInt32				i = 0;
		SInt32				numDisplays = 0;
		float				lastWx=-1, lastWy=-1;
		CMDeviceID			displayIDs[25] = {};
		const int			win_width=300, win_height=100;
		size_t				main_height = 0;
		
		// Count windows
		(void) CGGetOnlineDisplayList(25, (CGDirectDisplayID*)displayIDs, (CGDisplayCount*)&numDisplays);
		
		if (numDisplays == 0)
		{
			NSLog(@"No displays were found");
			[self quitWithError:0];
		}
		
		// If only one display, just do it
		if (numDisplays == 1)
		{
			_id = displayIDs[0];
			[self beginCalibration];
			return;
		}
		
		_clickMeWindows = [[NSMutableArray arrayWithCapacity:numDisplays] retain];
		
		main_height = CGDisplayPixelsHigh(CGMainDisplayID());
		
		// Create windows.
		for (i=0; i<numDisplays; i++)
		{
			CMDeviceID	aDisplay = displayIDs[i];
			NSString*	displayName = [Assistant nameOfDisplay:aDisplay];
			
			if (displayName == nil)
				continue;
			
			CGRect cgBounds;
			NSRect wFrame;
			cgBounds = CGDisplayBounds((CGDirectDisplayID)aDisplay);
			wFrame.origin.x = cgBounds.origin.x + (cgBounds.size.width - win_width) / 2;
			wFrame.origin.y = main_height - (cgBounds.origin.y + cgBounds.size.height*3/7 + win_height/2);
			wFrame.size.width = win_width;
			wFrame.size.height = win_height;
			
			if (lastWx==wFrame.origin.x && lastWy==wFrame.origin.y)
				wFrame.origin.y -= win_height+30;
			lastWx = wFrame.origin.x, lastWy = wFrame.origin.y;
			
			NSButton* b =[[[NSButton alloc] init] autorelease];
			NSString* bStr = [NSString stringWithFormat:NSLocalizedString(@"ClickThisWindow", nil), displayName];
			[b setTitle:bStr];
			[b setButtonType:NSMomentaryLightButton];
			[b setBezelStyle:NSShadowlessSquareBezelStyle];
			[b setImagePosition:NSNoImage];
			[b setBordered:YES];
			[b setTarget:self];
			[b setAction:@selector(clickMe:)];
			[b setTag:aDisplay];
			
			NSWindow* w = [[NSWindow alloc] 
					initWithContentRect:wFrame 
					styleMask:NSBorderlessWindowMask//NSTitledWindowMask 
					backing:NSBackingStoreBuffered defer:YES];
			[w setContentView:b];
			[w setHasShadow:YES];
			[w makeKeyAndOrderFront:self];
			
			[_clickMeWindows addObject:w];
		}
		
		if ([_clickMeWindows count] == 0)
			[self quitWithError:1];
		
		// make windows visible
		[_clickMeWindows makeObjectsPerformSelector:@selector(orderFront:) withObject:self];
	}
}


- (IBAction) clickMe:(id)sender
{
	_id = [sender tag];
	[self beginCalibration];
	[_clickMeWindows makeObjectsPerformSelector:@selector(close)];
	[_clickMeWindows release];
	_clickMeWindows = nil;
}


#pragma mark -


- (void) beginCalibration
{
	if (_id)
	{
		NSArray*	info = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PaneList"];
		int			i, count = [info count];
		
		_panesArray = [[NSMutableArray arrayWithCapacity:count] retain];
		_panesStack = [[NSMutableArray arrayWithCapacity:count] retain];
		
		_assistant = [[Assistant alloc] initWithDisplay:_id];
		if (_assistant == nil)
			[self quitWithError:1];
		
		[_toc setPanesArray:_panesArray andStack:_panesStack];
		
		unichar uc=NSRightArrowFunctionKey;
		[_next setKeyEquivalent:[NSString stringWithCharacters:&uc length:1]];
		[_next setKeyEquivalentModifierMask:NSCommandKeyMask];
		
		uc=NSLeftArrowFunctionKey;
		[_back setKeyEquivalent:[NSString stringWithCharacters:&uc length:1]];
		[_back setKeyEquivalentModifierMask:NSCommandKeyMask];
		
		for (i=0; i<count; i++)
		{
			id obj = [info objectAtIndex:i];
			PaneController* pane = [(PaneController*)[NSClassFromString(obj) alloc] initWithAssistant:_assistant];
			if (pane)
				[_panesArray addObject:pane];
			else
			{
				NSLog(@"The class %@ was not found", obj);
				[self quitWithError:0];
			}
		}
		
		[self next:nil];
		
		CGRect cgBounds = CGDisplayBounds((CGDirectDisplayID)_id);
		NSRect wFrame = [_window frame];
		size_t main_height = CGDisplayPixelsHigh(CGMainDisplayID());
		wFrame.origin.x = cgBounds.origin.x + cgBounds.size.width/2 - wFrame.size.width/2;
		wFrame.origin.y = main_height - (cgBounds.origin.y + cgBounds.size.height/2 + wFrame.size.height/2);
		[_window setFrame:wFrame display:NO];
		[_window makeKeyAndOrderFront:self];
	}
}


#pragma mark -


- (PaneController*) currPane
{
	if ([_panesStack count] == 0)
		return nil;
	return [_panesStack objectAtIndex:0];
}


- (PaneController*) nextPane
{
	PaneController* p = nil;
	int				index;
	
	index = [_panesArray indexOfObject:[self currPane]];
	if (index == NSNotFound)
		index = -1;
	
	do {
		index++;
		if (index >= [_panesArray count])
			return nil;
		p = [_panesArray objectAtIndex:index];
	
	} while ([p shouldSkip] == YES);
	
	return p;
}


- (IBAction) next:(id)sender
{
	PaneController* oldPane = nil;
	PaneController* newPane = nil;
	
	// see if it is ok to procede
	oldPane = [self currPane];
	if (oldPane && [oldPane shouldNextPane]==NO)
		return;
	
	// Out with the old pane
	[_box setContentView:nil];
	[oldPane paneDidUnload:YES];
	
	newPane = [self nextPane];
	if (newPane==nil)
	{
		[[NSApp mainWindow] performClose:self];
		return;
	}
	
	// push pane
	[_panesStack insertObject:newPane atIndex:0];
	
	[self newPaneWithDirection:YES oldPane:oldPane];
}


- (IBAction) back:(id)sender
{
	PaneController* oldPane = nil;
	
	// see if it is ok to regress
	oldPane = [self currPane];
	if (oldPane && [oldPane shouldPrevPane]==NO)
		return;
	
	// Out with the old pane
	[_box setContentView:nil];
	[oldPane paneDidUnload:NO];
	
	// pop pane
	[_panesStack removeObjectAtIndex:0];
	
	[self newPaneWithDirection:NO oldPane:oldPane];
}


- (void) newPaneWithDirection:(BOOL)direction oldPane:(PaneController*)oldPane
{
	PaneController* pane = [self currPane];
	NSView*			panesFirstResp = nil;
	NSView*			panesChainBegin = nil;
	NSView*			panesChainEnd = nil;
	NSView*			windFirstResp = nil;
	
	// In with the new pane
	[_box setContentView:[pane view]];
	[pane paneDidLoad:direction];
	
	panesChainBegin = [pane responderChainBegin];
	panesChainEnd = [pane responderChainEnd];
	
	panesFirstResp = [pane initialFirstResponder];
	if (![panesFirstResp isDescendantOf:_box])
		panesFirstResp = nil;
	
	windFirstResp = panesFirstResp;
	if (windFirstResp == nil)
		windFirstResp = panesChainBegin;
	if (windFirstResp == nil)
		windFirstResp = _next;
	
	[_window makeFirstResponder:windFirstResp];
	[panesChainEnd setNextKeyView:_next];
	[_next setNextKeyView:_back];
	[_back setNextKeyView:windFirstResp];

	[self updateButtons];
	
	// set pane title
	[_title setStringValue:[pane titleString]];
	
	// update toc
	[_toc setNeedsDisplay:YES];
}


- (void) updateButtons
{
	BOOL lastPane = ([self nextPane] == nil);
	BOOL firstPane = ([_panesStack count] == 1);
	BOOL shouldNext = [[self currPane] shouldNextPane];
	BOOL shouldPrev = [[self currPane] shouldPrevPane];
	
	[_back setEnabled:!firstPane && !lastPane && shouldPrev];
	if (lastPane)
		[_next setTitle:[_next alternateTitle]];
	[_next setEnabled:shouldNext || lastPane];
}


- (void)windowDidUpdate:(NSNotification *)notification
	{ [self updateButtons]; }

@end
