//
//  TocView.m
//  Calibrator
//
//  Created by David Hayward on Tue Nov 19 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "TocView.h"
#import "PaneController.h"

#define mLINEHEIGHT		22
#define mINTERSPACE_H	 6
#define mIMAGEWIDTH		10
#define mIMAGEHEIGHT	12
#define mFONTSIZE		13



@implementation TocView


- (void) dealloc
{
	[_panesArray release];
	[_panesStack release];
	[_bulletImage release];
	[_fontAttribs release];
	[super dealloc];
}


- (id) initWithFrame:(NSRect) frame
{
	self = [super initWithFrame:frame];
	_bulletImage = [NSImage imageNamed:@"bullet"];
	_fontAttribs = [[NSDictionary 
				dictionaryWithObject:[NSFont labelFontOfSize:mFONTSIZE] 
							  forKey:NSFontAttributeName] retain];
	return self;
}


- (void) setPanesArray:(NSMutableArray*)array andStack:(NSMutableArray*)stack
{
	_panesArray = [array retain];
	_panesStack = [stack retain];
}


//- (BOOL)isFlipped
//	{ return YES; }


- (void) drawRect:(NSRect) frame
{
	NSString*		itemStrings[20] = {};
	int				itemButtons[20] = {};
	int				itemCount = 0;
	float			y = 0;
	int				i, count = [_panesArray count];
	NSRect			bRectS = {{0,0},{mIMAGEWIDTH,mIMAGEHEIGHT}};
	NSRect			bRectD = {{0,0},{mIMAGEWIDTH,mIMAGEHEIGHT}}; 
	int				bNum;
	NSString*		string = nil;
	int				isFlipped = [self isFlipped] ? 1 : 0;
	int				flipSign = isFlipped*2 - 1;
	
	for (i=0; i<count && itemCount<20; i++)
	{
		PaneController* pane = [_panesArray objectAtIndex:i];
		PaneController* curPane = [_panesStack objectAtIndex:0];
		
		string = [pane bulletString];
		bNum = (pane==curPane) ? 0 : ([_panesStack containsObject:pane] ? 1 : 2);
		
		if (itemCount>0 && [string isEqual:itemStrings[itemCount-1]])
		{
			if (itemButtons[itemCount-1] > bNum)
				itemButtons[itemCount-1] = bNum;
		}
		else
		{
			itemButtons[itemCount] = bNum;
			itemStrings[itemCount] = string;
			itemCount++;
		}
	}
	
	if (!isFlipped)
		y = [self bounds].size.height - mLINEHEIGHT;
	
	for (i=0; i<itemCount; i++)
	{
		bRectD.origin.y = y + (mLINEHEIGHT-mIMAGEHEIGHT)*0.5 + isFlipped*mIMAGEHEIGHT;
		bRectS.origin.x = itemButtons[i] * mIMAGEWIDTH;
		[_bulletImage drawInRect:bRectD fromRect:bRectS operation:NSCompositeSourceOver fraction:1.0];
		
		NSRect			stringRect;
		NSSize			stringSize = {200, 17};
		if (_fontAttribs)
			stringSize = [itemStrings[i] sizeWithAttributes:_fontAttribs];
		
		stringRect.size.height = stringSize.height;
		stringRect.size.width = MIN(stringSize.width, [self bounds].size.width - stringRect.origin.x);
		stringRect.origin.x = mIMAGEWIDTH + mINTERSPACE_H;
		stringRect.origin.y = y + (mLINEHEIGHT-stringSize.height)*0.5 - flipSign;
		
		[itemStrings[i] drawInRect:stringRect withAttributes:_fontAttribs];
		
		y += flipSign*mLINEHEIGHT;
	}
}

@end
