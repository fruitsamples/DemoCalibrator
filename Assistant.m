//
//  Assistant.m
//  Calibrator
//
//  Created by David Hayward on Sat Nov 30 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Assistant.h"
#include <unistd.h>
#include <sys/stat.h>





@implementation Assistant

+ (NSString*) nameOfDisplay:(CMDeviceID)devID
	{ return [[[[Assistant alloc] initWithDisplay:devID] autorelease] factoryName]; }


- (id) initWithDisplay:(CMDeviceID)devID
{
	self = [super init];
	
	CMError					err = noErr;
	CMDeviceProfileID		defaultProfID=0;
	CMDeviceProfileArray	profArray = {};
	UInt32					arraySize = sizeof(profArray);
	
	_id = devID;
	
	err = CMGetDeviceFactoryProfiles(cmDisplayDeviceClass, _id, &defaultProfID, &arraySize, &profArray);
	require_noerr(err, bail);
	
	err = CMOpenProfile(&_ref, &(profArray.profiles[0].profileLoc));
	require_noerr(err, bail);
	
bail:
	
	if (err)
	{
		NSLog(@"Error getting profile for display %x", devID);
		self = nil;
	}
	
	return self;
}


- (void) dealloc
{
	if (!_refSet) [self loadOriginalLuts];
	if (_ref) CMCloseProfile(_ref);
	[_name release];
	[_nameAscii release];
	[super dealloc];
}


- (CMDeviceID) display
	{ return _id; }


#pragma mark -


- (NSString*) prefForKey:(NSString*)key
	{ return [NSString stringWithFormat:@"%.8lX-%@", _id, key]; }

- (id) prefObjectForKey:(NSString*)key
{
	key = [self prefForKey:key];
	return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}
- (void) prefSetObject:(id)value forKey:(NSString*)key
{
	key = [self prefForKey:key];
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

- (int) prefIntegerForKey:(NSString*)key
{
	key = [self prefForKey:key];
	return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}
- (void) prefSetInteger:(int)value forKey:(NSString*)key
{
	key = [self prefForKey:key];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
}

- (float) prefFloatForKey:(NSString*)key
{
	key = [self prefForKey:key];
	return [[NSUserDefaults standardUserDefaults] floatForKey:key];
}
- (void) prefSetFloat:(float)value forKey:(NSString*)key
{
	key = [self prefForKey:key];
	[[NSUserDefaults standardUserDefaults] setFloat:value forKey:key];
}
- (void) prefRegFloat:(float)value forKey:(NSString*)key
{
	key = [self prefForKey:key];
	[[NSUserDefaults standardUserDefaults] registerDefaults:
		[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:value] forKey:key]];
}


#pragma mark -


- (NSString*) factoryName
{
	CMError			err = noErr;
	Str255			pName;
	ScriptCode		code;
	NSString*		name = nil;
	UniCharCount	uCount = 0;
	UniChar*		uName = nil;
	
	// For icc4 profiles, look in 'desc' tag for 'mluc' data
	err = CMCopyProfileLocalizedString(_ref, cmProfileDescriptionTag, 0,0, (CFStringRef*)&name);
	if (!err) goto bail;
	
	// For transition profiles, look in 'dscm' tag for 'mluc' data
	err = CMCopyProfileLocalizedString(_ref, cmProfileDescriptionMLTag, 0,0, (CFStringRef*)&name);
	if (!err) goto bail;
	
	// Look for a unicode string in the 'desc' tag 'mluc' data 
	err = CMGetProfileDescriptions(_ref, nil,nil, nil,nil, nil,	&uCount);
	if (!err && uCount>1)
	{
		uName = calloc(uCount,2);
		err = CMGetProfileDescriptions(_ref, nil,nil, nil,nil, uName,&uCount);
		if (!err)
		{
			name = (NSString*)CFStringCreateWithBytes(NULL, (UInt8*)uName, (uCount-1)*2, kCFStringEncodingUnicode, 0);
			goto bail;
		}
	}
	
	// do it the old way 
	err = CMGetScriptProfileDescription(_ref, pName, &code);
	require_noerr(err, bail);
	name = (NSString*)CFStringCreateWithPascalString(0L, pName, code);
	
bail:
	
	[name autorelease];
	return name;
}


- (NSString*) name
{
	// return last name set
	if (_name)
		return _name;
	
	// return name from prefs
	_name = [[self prefObjectForKey:@"name"] retain];
	if (_name)
		return _name;
	
	// return devname+"calibrated"
	_name = [[NSString stringWithFormat:@"%@ Calibrated", [self factoryName] ] retain];
	return _name;
}


- (NSString*) nameAscii
{
	// return last name set
	if (_nameAscii)
		return _nameAscii;
	
	NSData* data = [[self name] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	_nameAscii = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	return _nameAscii;
}


- (void) setName:(NSString*)name andAsciiName:(NSString*)nameAscii
{
	[_name autorelease];
	_name = [name retain];
	[self prefSetObject:_name forKey:@"name"];
	
	[_nameAscii autorelease];
	_nameAscii = [nameAscii retain];
}


#pragma mark -


- (void) getPath:(char*)path forName:(NSString*)name
{
	int		i;
	char	cname[101] = "";
	
	path[0] = 0;
	
	// remove .icc of present
	if ([name hasSuffix:@".icc"])
		name = [name substringToIndex:[name length]-4];
	
	// get the name as a UTF8 c-string
	(void) CFStringGetCString((CFStringRef)name, cname, 100, kCFStringEncodingUTF8);
	for (i=0; cname[i]; i++)
		if (cname[i] == '/')
			cname[i] = ':';
		else if (cname[i] == ':')
			cname[i] = '-';
	
	{
		CMError				err = noErr;
		FSRef				fsref;
		
		// Find the top level directory (where we're going to create the new profile).
		err = FSFindFolder(kUserDomain, kColorSyncProfilesFolderType, true, &fsref);
		if (err) return;
		
		// Convert the CS profs folder to a path
		err = FSRefMakePath(&fsref, path, 255);
		if (err) return;
		
		strncat(path, "/", 255);
		strncat(path, cname, 255);
		strncat(path, ".icc", 255);
	}
}


- (CMProfileLocation) profileLocation
{
	CMProfileLocation		loc = {cmPathBasedProfile};
	[self getPath:loc.u.pathLoc.path forName:[self name]];
	return loc;
}


- (BOOL) fileExistsForName:(NSString*)name
{
	char			path[256];
	struct stat 	sb = {};
	[self getPath:path forName:name];
	return (stat(path,&sb)==0);
}


- (CMProfileRef) createProfileWithLocation:(CMProfileLocation*)loc
{
	CMError				err = noErr;
	CMProfileRef		ref;
	NSString*			name;
	const char*			aName = nil;
	UInt32				aCount = 0;
	Str255				mName = "";
	ScriptCode			mCode = 0;
	UniChar*			uName = nil;
	UniCharCount		uCount = 0;
	
	name = [self name];
	
	uCount = [name length]+1;
	uName = calloc(uCount, 2);
	[name getCharacters:uName];
	
	aName = [[self nameAscii] cString];
	aCount = aName ? (strlen(aName)+1) : 0;
	
	if ([name canBeConvertedToEncoding:NSMacOSRomanStringEncoding])
	{
		CFStringGetPascalString((CFStringRef)name, mName, 256, kCFStringEncodingMacRoman);
		mCode = smRoman;
	}
	
	err = CMCopyProfile(&ref, loc, _ref);
	require_noerr(err, bail);
	
	(void) CMSetProfileDescriptions(ref, aName,aCount, mName,mCode, uName,uCount);
	
bail:
	
	if (uName) free(uName);
	
	return ref;
}


- (void) createProfile 
{
	CMError				err = noErr;
	CMProfileLocation	loc;
	CMProfileRef		ref = nil;
	
	loc = [self profileLocation];
	
	// Delete file if it exists
	unlink(loc.u.pathLoc.path);
	
	ref = [self createProfileWithLocation:&loc];
	require(ref, bail);
	
	err = CMUpdateProfile(ref);
	require_noerr(err, bail);
	
	err = CMCloseProfile(ref);
	require_noerr(err, bail);
	
	CMDeviceProfileScope scope = {kCFPreferencesCurrentUser,  kCFPreferencesCurrentHost};
	err = CMSetDeviceProfile(cmDisplayDeviceClass, _id, &scope, 0, &loc);
	require_noerr(err, bail);
	
	// Force the cache to be rebuilt.
	(void) CMIterateColorSyncFolder(0L, 0L, 0L, 0L);
	
	// Remember that the new profile was successfully made and set
	_refSet = YES;
	
bail:
	
	if (!_refSet)
		[self loadOriginalLuts];
	
	return;
}


- (BOOL) createdProfile
	{ return _refSet; }


#pragma mark -


- (void) loadLuts
{
	OSErr					err = noErr;
	CMProfileRef			ref = nil;
	UInt32					tagSize;
	CMVideoCardGammaType*	vcgtTag = nil;
	
	ref = [self createProfileWithLocation:nil];
	require(ref, bail);
	
	tagSize = sizeof(CMVideoCardGammaType);
	err = CMGetProfileElement(ref, cmVideoCardGammaTag, &tagSize, nil);
	require_noerr(err, bail);
	
	vcgtTag = (CMVideoCardGammaType*) malloc(tagSize);
	
	err = CMGetProfileElement(ref, cmVideoCardGammaTag, &tagSize, vcgtTag);
	require_noerr(err, bail);
	require_action(vcgtTag->typeDescriptor == cmSigVideoCardGammaType, bail, err=paramErr; );
	
	err = CMSetGammaByAVID(_id, &vcgtTag->gamma);
	require_noerr(err, bail);
	
bail:
	
	if (ref) CMCloseProfile(ref);
	if (vcgtTag) free(vcgtTag);
}


- (void) loadOriginalLuts
{
	OSErr					err = noErr;
	UInt32					tagSize;
	CMVideoCardGammaType*	vcgtTag = nil;
	
	tagSize = sizeof(CMVideoCardGammaType);
	err = CMGetProfileElement(_ref, cmVideoCardGammaTag, &tagSize, nil);
	require_noerr(err, bail);
	
	vcgtTag = (CMVideoCardGammaType*) malloc(tagSize);
	
	err = CMGetProfileElement(_ref, cmVideoCardGammaTag, &tagSize, vcgtTag);
	require_noerr(err, bail);
	require_action(vcgtTag->typeDescriptor == cmSigVideoCardGammaType, bail, err=paramErr; );
	
	err = CMSetGammaByAVID(_id, &vcgtTag->gamma);
	require_noerr(err, bail);
	
bail:
	
	if (vcgtTag) free(vcgtTag);
}


@end
 
