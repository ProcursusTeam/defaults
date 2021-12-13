/*
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021 ProcursusTeam
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import "NSData+HexString.h"
#include "defaults.h"

CFPropertyListRef parseTypedArg(NSString *type, NSString *value, bool inArray) {
	if (type == NULL) {
		if (inArray && ([value characterAtIndex:0] == '{' || [value characterAtIndex:0] == '('))
			return (__bridge CFPropertyListRef)parsePropertyList(value);
		return (__bridge CFStringRef)value;
	} else if ([type isEqualToString:@"-string"]) {
		return (__bridge CFStringRef)value;
	} else if ([type isEqualToString:@"-int"] || [type isEqualToString:@"-integer"]) {
		return (__bridge CFNumberRef)@([value longLongValue]);
	} else if ([type isEqualToString:@"-float"]) {
		return (__bridge CFNumberRef)@([value floatValue]);
	} else if ([type isEqualToString:@"-bool"] || [type isEqualToString:@"-boolean"]) {
		if ([value caseInsensitiveCompare:@"yes"] == NSOrderedSame)
			return kCFBooleanTrue;
		else if ([value caseInsensitiveCompare:@"true"] == NSOrderedSame)
			return kCFBooleanTrue;
		else if ([value caseInsensitiveCompare:@"no"] == NSOrderedSame)
			return kCFBooleanFalse;
		else if ([value caseInsensitiveCompare:@"false"] == NSOrderedSame)
			return kCFBooleanFalse;
		else {
			usage();
			exit(1);
		}
	} else if ([type isEqualToString:@"-date"]) {
		CFDateRef date = (__bridge CFDateRef)[NSDate dateWithString:value];
		if (date == NULL)
			date = (__bridge CFDateRef)[NSDate dateWithNaturalLanguageString:value];
		if (date == NULL) {
			usage();
			exit(1);
		}
		return date;
	} else if ([type isEqualToString:@"-data"]) {
		NSCharacterSet *set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"] invertedSet];
		if ([value length] % 2 != 0 || [value rangeOfCharacterFromSet:set].location != NSNotFound) {
			usage();
			exit(255);
		}
		return (__bridge CFDataRef)[NSData dataWithHexString:value];
	}
	return NULL;
}

NSObject* parsePropertyList(NSString* propertyList) {
	NSObject *rep;
	@try {
		rep = [propertyList propertyList];
	}
	@catch (NSException *e) {
		NSLog(@"Could not parse: %@.  Try single-quoting it.\n", propertyList);
		exit(1);
	}
	return rep;
}

bool isType(NSString* type) {
	return [type isEqualToString:@"-string"] || [type isEqualToString:@"-data"] ||
		   [type isEqualToString:@"-int"] || [type isEqualToString:@"-integer"] ||
		   [type isEqualToString:@"-float"] || [type isEqualToString:@"-bool"] ||
		   [type isEqualToString:@"-boolean"] || [type isEqualToString:@"-date"];
}

NSArray *flatten(NSObject *input) {
	NSMutableArray *ret = [[NSMutableArray alloc] init];
	if ([input isKindOfClass:[NSArray class]]) {
		for (NSObject *object in (NSArray*)input) {
			if ([object isKindOfClass:[NSString class]]) {
				[ret addObject:object];
			} else if ([object isKindOfClass:[NSArray class]]) {
				[ret addObjectsFromArray:flatten(object)];
			} else if ([object isKindOfClass:[NSDictionary class]]) {
				[ret addObjectsFromArray:flatten(object)];
			}
		}
	} else {
		for (NSString *key in [(NSDictionary*)input allKeys]) {
			[ret addObject:key];
			if ([[(NSDictionary*)input objectForKey:key] isKindOfClass:[NSString class]]) {
				[ret addObject:[(NSDictionary*)input objectForKey:key]];
			} else if ([[(NSDictionary*)input objectForKey:key] isKindOfClass:[NSArray class]]) {
				[ret addObjectsFromArray:flatten([(NSDictionary*)input objectForKey:key])];
			} else if ([[(NSDictionary*)input objectForKey:key] isKindOfClass:[NSDictionary class]]) {
				[ret addObjectsFromArray:flatten([(NSDictionary*)input objectForKey:key])];
			}
		}
	}
	return ret;
}

void usage()
{
	printf("Command line interface to a user's defaults.\n");
	printf("Syntax:\n");
	printf("\n");
	printf("'defaults' [-currentHost | -host <hostname>] followed by one of the following:\n");
	printf("\n");
	printf("  read                                 shows all defaults\n");
	printf("  read <domain>                        shows defaults for given domain\n");
	printf("  read <domain> <key>                  shows defaults for given domain, key\n");
	printf("\n");
	printf("  read-type <domain> <key>             shows the type for the given domain, key\n");
	printf("\n");
	printf("  write <domain> <domain_rep>          writes domain (overwrites existing)\n");
	printf("  write <domain> <key> <value>         writes key for domain\n");
	printf("\n");
	printf("  rename <domain> <old_key> <new_key>  renames old_key to new_key\n");
	printf("\n");
	printf("  delete <domain>                      deletes domain\n");
	printf("  delete <domain> <key>                deletes key in domain\n");
	printf("\n");
	printf("  import <domain> <path to plist>      writes the plist at path to domain\n");
	printf("  import <domain> -                    writes a plist from stdin to domain\n");
	printf("  export <domain> <path to plist>      saves domain as a binary plist to path\n");
	printf("  export <domain> -                    writes domain as an xml plist to stdout\n");
	printf("  domains                              lists all domains\n");
	printf("  find <word>                          lists all entries containing word\n");
	printf("  help                                 print this help\n");
	printf("\n");
	printf("<domain> is ( <domain_name> | -app <application_name> | -globalDomain )\n");
	printf("         or a path to a file omitting the '.plist' extension\n");
	printf("\n         [-container (<bundleid> | <groupid> | <path>)]\n");
	printf("         may be specified before the domain name to change the container\n");
	printf("         this is a Procursus extension\n");
	printf("\n");
	printf("<value> is one of:\n");
	printf("  <value_rep>\n");
	printf("  -string <string_value>\n");
	printf("  -data <hex_digits>\n");
	printf("  -int[eger] <integer_value>\n");
	printf("  -float  <floating-point_value>\n");
	printf("  -bool[ean] (true | false | yes | no)\n");
	printf("  -date <date_rep>\n");
	printf("  -array <value1> <value2> ...\n");
	printf("  -array-add <value1> <value2> ...\n");
	printf("  -dict <key1> <value1> <key2> <value2> ...\n");
	printf("  -dict-add <key1> <value1> ...\n");
	printf("\nContact the Procursus Team for support.\n");
}
