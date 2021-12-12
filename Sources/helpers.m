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
		fprintf(stderr, "Could not parse: %s.  Try single-quoting it.\n", propertyList.UTF8String);
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
