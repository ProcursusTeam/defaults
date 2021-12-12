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

void usage()
{
	printf("Command line interface to a user's defaults.\n");
	printf("Syntax:\n");
	printf("\n");
	printf("'defaults' TODO: [-currentHost | -host <hostname>] followed by one of the following:\n");
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
	// TODO: printf("  find <word>                          lists all entries containing word\n");
	printf("  help                                 print this help\n");
	printf("\n");
	printf("<domain> is ( <domain_name> | TODO: -app <application_name> | -globalDomain )\n");
	printf("         or a path to a file omitting the '.plist' extension\n");
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

int main(int argc, char *argv[], char *envp[])
{
	@autoreleasepool {
		NSMutableArray <NSString *> *args = [[[NSProcessInfo processInfo] arguments] mutableCopy];

		if (args.count == 1 || (args.count >= 2 && [args[1] isEqualToString:@"help"])) {
			usage();
			return args.count == 1 ? 1 : 0;
		}

		if ([args[1] isEqualToString:@"domains"]) {
			NSMutableArray *domains = [(__bridge_transfer NSArray*)CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
			[domains removeObjectAtIndex:[domains indexOfObject:(id)kCFPreferencesAnyApplication]];
			[domains sortUsingSelector:@selector(compare:)];
			printf("%s\n", [domains componentsJoinedByString:@", "].UTF8String);
			return 0;
		} else if (args.count == 2 && [args[1] isEqualToString:@"read"]) {
			NSArray *prefs = (__bridge_transfer NSArray *)
				CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			NSMutableDictionary *out = [NSMutableDictionary new];
			for (NSString *domain in prefs) {
				[out setObject:(__bridge_transfer NSDictionary*)CFPreferencesCopyMultiple(NULL, (__bridge CFStringRef)domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
								forKey:[domain isEqualToString:(__bridge NSString *)kCFPreferencesAnyApplication] ? @"Apple Global Domain" : domain];
			}
			printf("%s\n", [NSString stringWithFormat:@"%@", out].UTF8String);
			return 0;
		}

		NSString *appid;

		if (args.count >= 3 && ![args[1] isEqualToString:@"find"]) {
			if ([args[2] isEqualToString:@"-g"] || [args[2] isEqualToString:@"-globalDomain"])
				appid = (__bridge NSString*)kCFPreferencesAnyApplication;
			else if ([args[2] isEqualToString:@"-app"]) {
				// TODO
				appid = @"com.apple.Preferences";
				[args removeObjectAtIndex:2];
			} else
				appid = args[2];
		}

		/*
		 * TODO: Fix printing of NSData/CFData
		 * Currently they are truncated as {length = 410, bytes = 0x62706c69 ... 0000013a }
		 * instead of only printing the hex.
		 */
		if ([args[1] isEqualToString:@"read"]) {
			NSDictionary *result = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(NULL,
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

			if (args.count == 3) {
				if ([result count] == 0) {
					fprintf(stderr, "Domain %s does not exist\n", appid.UTF8String);
					return 1;
				}
				printf("%s\n", result.description.UTF8String);
				return 0;
			} else {
				if ([result objectForKey:args[3]] == nil) {
					fprintf(stderr, "The domain/default pair of (%s, %s) does not exist\n",
							appid.UTF8String, args[3].UTF8String);
					return 1;
				}
				printf("%s\n", [[result objectForKey:args[3]] description].UTF8String);
				return 0;
			}
		}

		if (args.count == 5 && [args[1] isEqualToString:@"rename"]) {
			CFPropertyListRef value = CFPreferencesCopyValue((__bridge CFStringRef)args[3],
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (value == NULL) {
				fprintf(stderr, "Key %s does not exist in domain %s; leaving defaults unchanged\n",
						args[3].UTF8String,
						[appid isEqualToString:(__bridge NSString*)kCFPreferencesAnyApplication]
							? "Apple Global Domain" : appid.UTF8String);
				return 1;
			}
			CFPreferencesSetValue((__bridge CFStringRef)args[4], value, (__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSetValue((__bridge CFStringRef)args[3], NULL, (__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (!CFPreferencesSynchronize((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) {
				fprintf(stderr, "Failed to write domain %s\n", appid.UTF8String);
				return 1;
			}
			return 0;
		}

		if (args.count >= 4 && [args[1] isEqualToString:@"read-type"]) {
			CFPropertyListRef result = CFPreferencesCopyValue((__bridge CFStringRef)args[3],
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (result == NULL) {
				fprintf(stderr, "The domain/default pair of (%s, %s) does not exist\n",
						appid.UTF8String, args[3].UTF8String);
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
			if (args.count == 3) {
				fprintf(stderr, "Need a path to write to\n");
				return 1;
			}
			NSArray *keys = (__bridge_transfer NSArray*)CFPreferencesCopyKeyList((__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			NSDictionary *out = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(
					(__bridge CFArrayRef)keys, (__bridge CFStringRef)appid,
					kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (out == 0) {
				fprintf(stderr, "The domain %s does not exist\n", appid.UTF8String);
				return 1;
			}
			NSError *error;
			NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
			NSURL *outURL;
			if ([args[3] isEqualToString:@"-"]) {
				format = NSPropertyListXMLFormat_v1_0;
			}

			NSData *outData = [NSPropertyListSerialization dataWithPropertyList:out
																								 format:format
																								options:0
																									error:&error];

			if (error) {
				fprintf(stderr, "Could not export domain %s to %s due to %s\n",
						appid.UTF8String,
						args[3].UTF8String,
						error.localizedDescription.UTF8String);
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
			if (args.count == 3) {
				fprintf(stderr, "Need a path to read from\n");
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
				fprintf(stderr, "Could not read data from %s\n", args[3].UTF8String);
			}

			NSError *error;
			NSObject *inputDict = [NSPropertyListSerialization propertyListWithData:inputData
																																					options:0
																																					 format:0
																																						error:&error];
			if (error) {
				fprintf(stderr, "Could not parse property list from %s due to %s\n",
						args[3].UTF8String, error.localizedDescription.UTF8String);
				return 1;
			}

			if (![inputDict isKindOfClass:[NSDictionary class]]) {
				fprintf(stderr, "Property list %s was not a dictionary\nDefaults have not been changed.\n",
						args[3].UTF8String);
				return 1;
			}
			CFPreferencesSetMultiple((__bridge CFDictionaryRef)(NSDictionary*)inputDict, NULL,
					(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize((__bridge CFStringRef)appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			return 0;
		}

		if ((args.count == 4 || args.count == 3) && ([args[1] isEqualToString:@"delete"] ||
				/* remove is an undocumented alias for delete */ [args[1] isEqualToString:@"remove"])) {
			if (args.count == 4) {
				CFPropertyListRef result = CFPreferencesCopyValue((__bridge CFStringRef)args[3],
						(__bridge CFStringRef)appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				if (result == NULL) {
					fprintf(stderr, "Domain (%s) not found.\nDefaults have not been changed.\n", appid.UTF8String);
					CFRelease(result);
					return 1;
				}
				CFPreferencesSetValue((__bridge CFStringRef)args[3], NULL, (__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				return CFPreferencesSynchronize((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, kCFPreferencesAnyHost) ? 0 : 1;
			} else if (args.count == 3) {
				CFArrayRef keys = CFPreferencesCopyKeyList((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				if (keys == NULL) {
					fprintf(stderr, "Domain (%s) not found.\nDefaults have not been changed.\n", appid.UTF8String);
					return 1;
				}
				CFPreferencesSetMultiple(NULL, keys, (__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				return CFPreferencesSynchronize((__bridge CFStringRef)appid,
						kCFPreferencesCurrentUser, kCFPreferencesAnyHost) ? 0 : 1;
			}
			return 1;
		}

		if ([args[1] isEqualToString:@"write"]) {
			if (args.count < 4) {
				usage();
				return 1;
			} else {
				return defaultsWrite(args, appid);
			}
		}

		usage();
		return 1;
	}
}
