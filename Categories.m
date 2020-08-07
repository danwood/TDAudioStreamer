//
//  Categories.m
//  TDAudioStreamer
//
//  Created by Dan Wood on 8/6/20.
//  Copyright © 2020 Tony DiPasquale. All rights reserved.
//

#import <Foundation/Foundation.h>


@implementation NSDictionary ( OverrideDebug )

- (NSString *)debugDescription
{
	return [self description];
}

@end

@implementation NSArray ( OverrideDebug )

- (NSString *)debugDescription
{
#define MAXARRAYSHOW 20
	if ([self count] > MAXARRAYSHOW)
	{
		NSArray *subArray = [self subarrayWithRange:
							 NSMakeRange(0,MAXARRAYSHOW)];
		return [NSString stringWithFormat:@"%@ [... %d items]",
				[subArray description], [self count]];
	}
	else
	{
		return [self description];
	}
}
@end

@implementation NSData ( description )

- (NSString *)description
{
#define MAXDATABYTES 1024
	unsigned char *bytes = (unsigned char *)[self bytes];
	unsigned length = [self length];
	NSMutableString *buf = [NSMutableString stringWithFormat:
							@"NSData %d bytes:\n", length];
	int i, j;

	for ( i = 0 ; i < length ; i += 16 )
	{
		if (i > MAXDATABYTES)       // don't print too much!
		{
			[buf appendString:@"\n...\n"];
			break;
		}
		for ( j = 0 ; j < 16 ; j++ )    // Show the row in Hex
		{
			int offset = i+j;
			if (offset < length)
			{
				[buf appendFormat:@"%02X ",bytes[offset]];
			}
			else
			{
				[buf appendFormat:@"   "];
			}
		}
		[buf appendString:@"| "];   // now show in ASCII
		for ( j = 0 ; j < 16 ; j++ )
		{
			int offset = i+j;
			if (offset < length)
			{
				unsigned char theChar = bytes[offset];
				if (theChar < 32 || theChar > 127)
				{
					theChar ='.';
				}
				[buf appendFormat:@"%c", theChar];
			}
		}
		[buf appendString:@"\n"];
	}
	[buf deleteCharactersInRange:NSMakeRange([buf length]-1, 1)];
	return buf;
}
@end


