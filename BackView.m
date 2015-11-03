//
//  BackView.m
//  Calibrator
//
//  Created by David Hayward on Sun Nov 17 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "BackView.h"


@implementation BackView


- (void) drawRect:(NSRect)rect
{
	NSRect		boxRect = [[[self subviews] objectAtIndex:1] frame];
	NSPoint		c = NSMakePoint(75,210);
	
	// Draw white box
	[[NSColor whiteColor] set];
	NSRectFill(boxRect);
	[[NSColor colorWithDeviceWhite:0.6 alpha:1] set];
	NSFrameRect(boxRect);
	
	// Draw black c
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:c radius:150  startAngle:45.0 endAngle:-45.0];
	[[NSColor colorWithDeviceWhite:0 alpha:.10] set];
	[path setLineWidth:64];
	[path stroke];
	
	// Draw pie slices
	int			i;
	float		colors[8][3] = {{.298, .698, .800}, {.569, .000, .400},
								{.831, .000, .329}, {.902, .396, .000},
								{1.00, .757, .000}, {.733, .863, .000},
								{.490, .765, .357}, {.000, .596, .729}};
	for (i=0; i<8; i++)
	{
		[path removeAllPoints];
		[path moveToPoint:c];
		[path appendBezierPathWithArcWithCenter:c radius:118 startAngle:i*45 endAngle:(i+1)*45];
		[path lineToPoint:c];
		[[NSColor colorWithDeviceRed:colors[i][0] green:colors[i][1] blue:colors[i][2] alpha:.10] set];
		[path fill];
	}
}


@end
