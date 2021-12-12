#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import "NSData+HexString.h"
#include "defaults.h"

/*
 * write <domain> <domain_rep>   writes domain (overwrites existing)
 * write <domain> <key> <value>  writes key for domain
 *
 * <value> is one of:
 *   <value_rep>
 *   -string <string_value>
 *   -data <hex_digits>
 *   -int[eger] <integer_value>
 *   -float  <floating-point_value>
 *   -bool[ean] (true | false | yes | no)
 *   -date <date_rep>
 *   -array <value1> <value2> ...
 *   -array-add <value1> <value2> ...
 *   -dict <key1> <value1> <key2> <value2> ...
 *   -dict-add <key1> <value1> ...
 */

int defaultsWrite(NSArray<NSString *> *args, NSString *ident, CFStringRef host) {
	if (args.count == 4) {
		NSObject* rep = parsePropertyList(args[3]);

		if (![rep isKindOfClass:[NSDictionary class]]) {
			fprintf(stderr, "Rep argument is not a dictionary\nDefaults have not been changed.\n");
			return 1;
		}

		NSMutableArray *toRemove;

		NSArray *keys = (__bridge_transfer NSArray*)CFPreferencesCopyKeyList((__bridge CFStringRef)ident,
				kCFPreferencesCurrentUser, host);
		if (keys.count == 0) {
			toRemove = NULL;
		} else {
			toRemove = [keys mutableCopy];
			[toRemove removeObjectsInArray:[(NSDictionary *)rep allKeys]];
		}

		CFPreferencesSetMultiple((__bridge CFDictionaryRef)(NSDictionary*)rep, (__bridge CFArrayRef)toRemove,
				(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
		CFPreferencesSynchronize((__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
		return 0;
	}

	NSString *key = args[3];

	if (args.count == 5) {
		NSObject *rep;
		// Should probably clean this up
		if (isType(args[4])) {
			usage();
			return 1;
		} else if ([args[4] isEqualToString:@"-array"]) {
			rep = [[NSArray alloc] init];
		} else if ([args[4] isEqualToString:@"-dict"]) {
			rep = [[NSDictionary alloc] init];
		} else if ([args[4] isEqualToString:@"-array-add"] || [args[4] isEqualToString:@"-dict-add"]) {
			rep = nil;
		} else {
			@try {
				rep = [args[4] propertyList];
			}
			@catch (NSException *e) {
				fprintf(stderr, "Could not parse: %s.  Try single-quoting it.\n", args[4].UTF8String);
				return 1;
			}
		}
		if (rep != nil) {
			CFPreferencesSetValue((__bridge CFStringRef)args[3], (__bridge CFPropertyListRef)rep,
				(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
			CFPreferencesSynchronize((__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
		}
		return 0;
	} else if (args.count >= 6) {
		CFPropertyListRef value = NULL;
		NSMutableArray<NSObject *> *array = [[NSMutableArray alloc] init];
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		if ([args[4] isEqualToString: @"-array"] || [args[4] isEqualToString: @"-array-add"]) { // Array
			if ([args[4] isEqualToString: @"-array-add"]) {
				CFPropertyListRef prepend = CFPreferencesCopyValue((__bridge CFStringRef)args[3],
					(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
				if (prepend != NULL) {
					if (CFGetTypeID(prepend) != CFArrayGetTypeID()) {
						fprintf(stderr, "Value for key %s is not an array; cannot append.  Leaving defaults unchanged.\n",
							args[3].UTF8String);
						return 1;
					}
					[array addObjectsFromArray:(__bridge_transfer NSArray*)prepend];
				}
			}
			NSArray<NSString*> *arrayItems = [args subarrayWithRange:NSMakeRange(5, args.count - 5)];
			for (int i = 0; i < arrayItems.count; i++) {
				if ([arrayItems[i] isEqualToString:@"-array"] || [arrayItems[i] isEqualToString:@"-dict"]) {
					fprintf(stderr, "Cannot nest composite types (arrays and dictionaries); exiting\n");
					return 1;
				}
				if (isType(arrayItems[i])) {
					if (i >= arrayItems.count - 1) {
						usage();
						return 1;
					}
					[array addObject: (__bridge NSObject*)parseTypedArg(arrayItems[i], arrayItems[++i], true)];
				} else {
					[array addObject: (__bridge NSObject*)parseTypedArg(NULL, arrayItems[i], true)];
				}
			}
			value = (__bridge CFPropertyListRef)array;
		} else if ([args[4] isEqualToString: @"-dict"] || [args[4] isEqualToString: @"-dict-add"]) { // Array
			if ([args[4] isEqualToString: @"-dict-add"]) {
				CFPropertyListRef prepend = CFPreferencesCopyValue((__bridge CFStringRef)args[3],
					(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
				if (prepend != NULL) {
					if (CFGetTypeID(prepend) != CFDictionaryGetTypeID()) {
						fprintf(stderr, "Value for key %s is not a dictionary; cannot append.  Leaving defaults unchanged.\n",
							args[3].UTF8String);
						return 1;
					}
					[dict addEntriesFromDictionary:(__bridge_transfer NSDictionary*)prepend];
				}
			}
			NSArray<NSString*> *arrayItems = [args subarrayWithRange:NSMakeRange(5, args.count - 5)];
			for (int i = 0; i < arrayItems.count; i++) {
				if ([arrayItems[i] isEqualToString:@"-array"] || [arrayItems[i] isEqualToString:@"-dict"]) {
					fprintf(stderr, "Cannot nest composite types (arrays and dictionaries); exiting\n");
					return 1;
				}
				if (isType(arrayItems[i])) {
					if ([arrayItems[i] isEqualToString:@"-string"]) {
						i++;
					} else {
						if (arrayItems.count == 1)
							usage();
						else
							fprintf(stderr, "Dictionary keys must be strings\n");
						return 1;
					}
				}
				if (i == arrayItems.count - 1) {
					fprintf(stderr, "Key %s lacks a corresponding value\n", arrayItems[i].UTF8String);
					return 1;
				}
				if (isType(arrayItems[i + 1])) {
					if (i >= arrayItems.count - 2) {
						usage();
						return 1;
					}
					[dict setObject:(__bridge_transfer NSObject*)parseTypedArg(arrayItems[i + 1], arrayItems[i + 2], true)
						forKey:arrayItems[i]];
					i += 2;
				} else {
					[dict setObject:(__bridge_transfer NSObject*)parseTypedArg(NULL, arrayItems[i + 1], true)
						forKey:arrayItems[i]];
					i++;
				}
			}
			value = (__bridge CFPropertyListRef)dict;
		}
		if (value == NULL)
			value = parseTypedArg(args[4], args[5], false);
		else if (args.count > 6 && array.count == 0 && dict.count == 0) {
			fprintf(stderr, "Unexpected argument %s; leaving defaults unchanged.\n", args[5].UTF8String);
			return 1;
		}
		CFPreferencesSetValue((__bridge CFStringRef)args[3], value,
			(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
		CFPreferencesSynchronize((__bridge CFStringRef)ident, kCFPreferencesCurrentUser, host);
		return 0;
	}

	return 1;
}
