/*
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2020-present quiprr
 * Modified work Copyright (c) 2021 ProcursusTeam
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

const unsigned char defaultsVersionString[] = "@(#)PROGRAM:defaults  PROJECT:defaults-1.0  BUILT:" __DATE__ " " __TIME__ "\n";

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include <stdio.h>

#include "defaults.h"

int main(int argc, char *argv[], char *envp[])
{
	@autoreleasepool {
		NSMutableArray <NSString *> *args = [[[NSProcessInfo processInfo] arguments] mutableCopy];

		CFStringRef host = kCFPreferencesAnyHost;
		if (args.count >= 2 && [args[1] isEqualToString:@"-currentHost"]) {
			host = kCFPreferencesCurrentHost;
			[args removeObjectAtIndex:1];
		} else if (args.count >= 3  && [args[1] isEqualToString:@"-host"]) {
			host = (__bridge CFStringRef)args[2];
			[args removeObjectAtIndex:2];
			[args removeObjectAtIndex:1];
		}

		if (args.count == 1) {
			usage();
			return 255;
		}

		_CFPrefsSetSynchronizeIsSynchronous(1);
		_CFPrefSetInvalidPropertyListDeletionEnabled(0);

		CFStringRef container = CFSTR("kCFPreferencesNoContainer");

		if (args.count >= 4 && [args[2] isEqualToString:@"-container"]) {
			if ([args[3] hasPrefix:@"/"]) {
				container = (__bridge CFStringRef)[args[3] stringByResolvingSymlinksInPath];
			} else if ([args[3] hasPrefix:@"group."]) {
				NSURL *url = [[NSFileManager defaultManager]
					containerURLForSecurityApplicationGroupIdentifier:args[3]];
				container = (__bridge CFStringRef)[(NSURL*)[url copy] path];
			} else {
				LSApplicationProxy *app = [LSApplicationProxy applicationProxyForIdentifier:args[3]];
				container = (__bridge CFStringRef)[app.containerURL path];
			}
			[args removeObjectAtIndex:3];
			[args removeObjectAtIndex:2];
		}

		[args replaceObjectAtIndex:1 withObject:[args[1] lowercaseString]];

		if (args.count == 1 || (args.count >= 2 && [args[1] isEqualToString:@"help"])) {
			usage();
			return args.count == 1 ? 255 : 0;
		}

		if ([args[1] isEqualToString:@"domains"]) {
			NSMutableArray *domains = [(__bridge_transfer NSArray*)CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, host) mutableCopy];
			if (domains.count != 0) {
				[domains removeObjectAtIndex:[domains indexOfObject:(id)kCFPreferencesAnyApplication]];
				[domains sortUsingSelector:@selector(compare:)];
			}
			printf("%s\n", [domains componentsJoinedByString:@", "].UTF8String);
			return 0;
		} else if (args.count == 2 && [args[1] isEqualToString:@"read"]) {
			NSArray *prefs = (__bridge_transfer NSArray *)
				CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, host);
			NSMutableDictionary *out = [NSMutableDictionary new];
			for (NSString *domain in prefs) {
				[out setObject:(__bridge_transfer NSDictionary*)CFPreferencesCopyMultiple(NULL, (__bridge CFStringRef)domain, kCFPreferencesCurrentUser, host)
								forKey:prettyName(domain)];
			}
			printf("%s\n", [NSString stringWithFormat:@"%@", out].UTF8String);
			return 0;
		}

		if (args.count >= 3 && [args[1] isEqualToString:@"find"]) {
			NSArray *domains = (__bridge_transfer NSArray*)CFPreferencesCopyApplicationList(
					kCFPreferencesCurrentUser, host);
			long found = 0;
			BOOL success = false;
			for (NSString *domain in domains) {
				found = 0;
				if ([domain rangeOfString:args[2] options:NSCaseInsensitiveSearch].location != NSNotFound)
					found++;
				NSDictionary *dict = (__bridge_transfer NSDictionary*)CFPreferencesCopyMultiple(NULL,
						(__bridge CFStringRef)domain, kCFPreferencesCurrentUser, host);
				NSArray *flattened = flatten(dict);
				NSLog(@"%@", flattened);
				for (NSString *item in flattened) {
					if ([item rangeOfString:args[2] options:NSCaseInsensitiveSearch].location != NSNotFound)
						found++;
				}
				if (found) {
					success = true;
					printf("Found %ld keys in domain '%s': %s\n", found,
							prettyName(domain).UTF8String, dict.description.UTF8String);
				}
			}
			if (!success)
				NSLog(@"No domain, key, nor value containing '%@'", args[2]);
			return 0;
		}

		NSString *appid;

		if (args.count >= 3) {
			if ([args[2] isEqualToString:@"-g"] || [args[2] isEqualToString:@"-globalDomain"] ||
					[args[2] isEqualToString:@"NSGlobalDomain"] || [args[2] isEqualToString:@"Apple Global Domain"])
				appid = (__bridge NSString*)kCFPreferencesAnyApplication;
			else if (args.count >= 4 && [args[2] isEqualToString:@"-app"]) {
				BOOL directory;
				if ([[NSFileManager defaultManager] fileExistsAtPath:args[3] isDirectory:&directory] && directory) {
					NSBundle *appBundle = [NSBundle bundleWithPath:[args[3] stringByResolvingSymlinksInPath]];
					if (appBundle == nil) {
						NSLog(@"Couldn't open application %@; defaults unchanged", args[3]);
						return 1;
					}
					appid = [appBundle bundleIdentifier];
					if (appid == nil) {
						NSLog(@"Can't determine domain name for application %@; defaults unchanged", args[3]);
						return 1;
					}
				} else {
					LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
					NSArray<LSApplicationProxy*> *apps = [workspace allInstalledApplications];
					for (LSApplicationProxy *proxy in apps) {
						if ([args[3] isEqualToString:[proxy localizedNameForContext:nil]]) {
							appid = proxy.applicationIdentifier;
							break;
						}
					}
					if (appid == nil) {
						NSLog(@"Couldn't find an application named \"%@\"; defaults unchanged", args[3]);
						return 1;
					}
				}
				[args removeObjectAtIndex:2];
			} else if ([args[2] hasPrefix:@"/"]) {
				appid = [args[2] stringByResolvingSymlinksInPath];
			} else
				appid = args[2];
		}

		if ([args[1] isEqualToString:@"read"]) {
			NSDictionary *result = (__bridge_transfer NSDictionary *)_CFPreferencesCopyMultipleWithContainer(NULL,
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, host, container);

			if (args.count == 3) {
				if ([result count] == 0) {
					NSLog(@"\nDomain %@ does not exist\n", appid);
					return 1;
				}
				printf("%s\n", result.description.UTF8String);
				return 0;
			} else {
				if ([result objectForKey:args[3]] == nil) {
					NSLog(@"\nThe domain/default pair of (%@, %@) does not exist\n", appid, args[3]);
					return 1;
				}
				printf("%s\n", [[result objectForKey:args[3]] description].UTF8String);
				return 0;
			}
		}

		if (args.count == 5 && [args[1] isEqualToString:@"rename"]) {
			CFPropertyListRef value = _CFPreferencesCopyValueWithContainer((__bridge CFStringRef)args[3],
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, host, container);
			if (value == NULL) {
				NSLog(@"Key %@ does not exist in domain %@; leaving defaults unchanged", args[3], prettyName(appid));
				return 1;
			}
			_CFPreferencesSetValueWithContainer((__bridge CFStringRef)args[4], value, (__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, host, container);
			_CFPreferencesSetValueWithContainer((__bridge CFStringRef)args[3], NULL, (__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, host, container);
			Boolean ret = _CFPreferencesSynchronizeWithContainer((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, host, container);
			_CFPrefsSynchronizeForProcessTermination();
			if (!ret) {
				NSLog(@"Failed to write domain %@", prettyName(appid));
				return 1;
			}
			return 0;
		}

		if (args.count >= 4 && [args[1] isEqualToString:@"read-type"]) {
			CFPropertyListRef result = _CFPreferencesCopyValueWithContainer((__bridge CFStringRef)args[3],
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, host, container);
			if (result == NULL) {
				NSLog(@"\nThe domain/default pair of (%@, %@) does not exist\n", appid, args[3]);
				return 1;
			}
			CFTypeID type = CFGetTypeID(result);
			if (type == CFStringGetTypeID()) {
				printf("Type is string\n");
			} else if (type == CFDataGetTypeID()) {
				printf("Type is data\n");
			} else if (type == CFNumberGetTypeID()) {
				if (CFNumberIsFloatType(result))
					printf("Type is float\n");
				else
					printf("Type is integer\n");
			} else if (type == CFBooleanGetTypeID()) {
				printf("Type is boolean\n");
			} else if (type == CFDateGetTypeID()) {
				printf("Type is date\n");
			} else if (type == CFArrayGetTypeID()) {
				printf("Type is array\n");
			} else if (type == CFDictionaryGetTypeID()) {
				printf("Type is dictionary\n");
			} else {
				printf("Found a value that is not of a known property list type\n");
			}
			CFRelease(result);
			return 0;
		}

		if ([args[1] isEqualToString:@"export"]) {
			if (args.count < 3) {
				usage();
				return 255;
			}
			if (args.count < 4) {
				NSLog(@"\nNeed a path to write to");
				return 1;
			}
			NSArray *keys = (__bridge_transfer NSArray*)_CFPreferencesCopyKeyListWithContainer((__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, host, container);
			NSDictionary *out = (__bridge_transfer NSDictionary *)_CFPreferencesCopyMultipleWithContainer(
					(__bridge CFArrayRef)keys, (__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, host, container);
			if (out == 0) {
				NSLog(@"\nThe domain %@ does not exist\n", appid);
				return 1;
			}
			NSError *error;
			NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
			if ([args[3] isEqualToString:@"-"]) {
				format = NSPropertyListXMLFormat_v1_0;
			}

			NSData *outData = [NSPropertyListSerialization dataWithPropertyList:out
																								 format:format
																								options:0
																									error:&error];

			if (error) {
				NSLog(@"Could not export domain %@ to %@ due to %@", appid, args[3], error);
				return 1;
			}
			if (format == NSPropertyListXMLFormat_v1_0) {
				NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
				[fh writeData:outData];
			} else
				[outData writeToFile:args[3] atomically:true];
			return 0;
		}

		if ([args[1] isEqualToString:@"import"]) {
			if (args.count < 3) {
				usage();
				return 255;
			}
			if (args.count < 4) {
				NSLog(@"\nNeed a path to read from");
				return 1;
			}

			NSData *inputData;
			if ([args[3] isEqualToString:@"-"]) {
				NSFileHandle *fh = [NSFileHandle fileHandleWithStandardInput];
				inputData = [fh readDataToEndOfFile];
			} else {
				inputData = [NSData dataWithContentsOfFile:args[3]];
			}
			if (inputData == nil) {
				NSLog(@"Could not read data from %@", args[3]);
				return 1;
			}

			NSError *error;
			NSObject *inputDict = [NSPropertyListSerialization propertyListWithData:inputData
																																					options:0
																																					 format:0
																																						error:&error];
			if (error) {
				NSLog(@"Could not parse property list from %@ due to %@", args[3], error);
				return 1;
			}

			if (![inputDict isKindOfClass:[NSDictionary class]]) {
				NSLog(@"Property list %@ was not a dictionary\nDefaults have not been changed.\n", inputDict);
				return 1;
			}
			for (NSString *key in [(NSDictionary*)inputDict allKeys]) {
				_CFPreferencesSetValueWithContainer((__bridge CFStringRef)key,
						(__bridge CFPropertyListRef)[(NSDictionary*)inputDict objectForKey:key],
						(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, host, container);
			}
			_CFPreferencesSynchronizeWithContainer((__bridge CFStringRef)appid, kCFPreferencesCurrentUser,
					host, container);
			_CFPrefsSynchronizeForProcessTermination();
			return 0;
		}

		if ((args.count == 4 || args.count == 3) && ([args[1] isEqualToString:@"delete"] ||
				/* remove is an undocumented alias for delete */ [args[1] isEqualToString:@"remove"])) {
			if (args.count == 4) {
				CFPropertyListRef result = _CFPreferencesCopyValueWithContainer((__bridge CFStringRef)args[3],
						(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, host, container);
				if (result == NULL) {
					NSLog(@"\nDomain (%@) not found.\nDefaults have not been changed.\n", appid);
					CFRelease(result);
					return 1;
				}
				_CFPreferencesSetValueWithContainer((__bridge CFStringRef)args[3], NULL, (__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, host, container);
				Boolean ret = _CFPreferencesSynchronizeWithContainer((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, host, container);
				_CFPrefsSynchronizeForProcessTermination();
				return ret ? 0 : 1;
			} else if (args.count == 3) {
				CFArrayRef keys = _CFPreferencesCopyKeyListWithContainer((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, host, container);
				if (keys == NULL) {
					NSLog(@"\nDomain (%@) not found.\nDefaults have not been changed.\n", appid);
					return 1;
				}
				for (NSString *key in (__bridge NSArray*)keys) {
					_CFPreferencesSetValueWithContainer((__bridge CFStringRef)key, NULL,
							(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, host, container);
				}
				Boolean ret = _CFPreferencesSynchronizeWithContainer((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, host, container);
				_CFPrefsSynchronizeForProcessTermination();
				return ret ? 0 : 1;
			}
			return 1;
		}

		if ([args[1] isEqualToString:@"write"]) {
			if (args.count < 4) {
				usage();
				return 255;
			} else {
				return defaultsWrite(args, appid, host, container);
			}
		}

		usage();
		return 255;
	}
}
