#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NSData+HexString.h"

@interface NSDate (deprecated)
+ (id)dateWithNaturalLanguageString:(NSString *)string;
+ (id)dateWithString:(NSString *)aString;
@end

void usage();

/* write <domain> <domain_rep>   writes domain (overwrites existing)
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

int defaultsWrite(NSArray<NSString *> *args, NSString *ident) {
	if (args.count == 4) {
		NSObject *rep;
		@try {
			rep = [args[3] propertyList];
		}
		@catch (NSException *e) {
			fprintf(stderr, "Could not parse: %s.  Try single-quoting it.\n", args[3].UTF8String);
			return 1;
		}

		if (![rep isKindOfClass:[NSDictionary class]]) {
			fprintf(stderr, "Rep argument is not a dictionary\nDefaults have not been changed.\n");
			return 1;
		}

		NSMutableArray *toRemove;

		NSArray *keys = (__bridge_transfer NSArray*)CFPreferencesCopyKeyList((__bridge CFStringRef)ident,
				kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keys.count == 0) {
			toRemove = NULL;
		} else {
			toRemove = [keys mutableCopy];
			[toRemove removeObjectsInArray:[(NSDictionary *)rep allKeys]];
		}

		CFPreferencesSetMultiple((__bridge CFDictionaryRef)(NSDictionary*)rep, (__bridge CFArrayRef)toRemove,
				(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize((__bridge CFStringRef)ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		return 0;
	}

	NSString *key = args[3];

	if (args.count == 5) {
		NSObject *rep;
		@try {
			rep = [args[4] propertyList];
		}
		@catch (NSException *e) {
			fprintf(stderr, "Could not parse: %s.  Try single-quoting it.\n", args[4].UTF8String);
			return 1;
		}
		CFPreferencesSetValue((__bridge CFStringRef)args[3], (__bridge CFPropertyListRef)rep,
			(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize((__bridge CFStringRef)ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		return 0;
	} else if (args.count >= 6) {
		CFPropertyListRef value = NULL;
		for (int i = 4; i < args.count; i++) {
			if (value != NULL) {
				fprintf(stderr, "Unexpected argument %s; leaving defaults unchanged.\n", args[i].UTF8String);
				return 1;
			} else if ([args[i] isEqualToString:@"-string"]) {
				value = (__bridge CFStringRef)args[++i];
			} else if ([args[i] isEqualToString:@"-int"] || [args[i] isEqualToString:@"-integer"]) {
				value = (__bridge CFNumberRef)@([args[++i] longLongValue]);
			} else if ([args[i] isEqualToString:@"-float"]) {
				value = (__bridge CFNumberRef)@([args[++i] floatValue]);
			} else if ([args[i] isEqualToString:@"-bool"] || [args[i] isEqualToString:@"-boolean"]) {
				i++;
				if ([args[i] caseInsensitiveCompare:@"yes"] == NSOrderedSame)
					value = kCFBooleanTrue;
				else if ([args[i] caseInsensitiveCompare:@"true"] == NSOrderedSame)
					value = kCFBooleanTrue;
				else if ([args[i] caseInsensitiveCompare:@"no"] == NSOrderedSame)
					value = kCFBooleanFalse;
				else if ([args[i] caseInsensitiveCompare:@"false"] == NSOrderedSame)
					value = kCFBooleanFalse;
				else {
					usage();
					return 1;
				}
			} else if ([args[i] isEqualToString:@"-date"]) {
				value = (__bridge CFDateRef)[NSDate dateWithString:args[++i]];
				if (value == NULL)
					value = (__bridge CFDateRef)[NSDate dateWithNaturalLanguageString:args[i]];
				if (value == NULL) {
					usage();
					return 1;
				}
			} else if ([args[i] isEqualToString:@"-data"]) {
				value = (__bridge CFDataRef)[NSData dataWithHexString:args[++i]];
			} else {
				@try {
					value = (__bridge CFPropertyListRef)[args[++i] propertyList];
				}
				@catch (NSException *e) {
					fprintf(stderr, "Could not parse: %s.  Try single-quoting it.\n", args[i].UTF8String);
					return 1;
				}
			}
		}
		CFPreferencesSetValue((__bridge CFStringRef)args[3], value,
			(__bridge CFStringRef)ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize((__bridge CFStringRef)ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		return 0;
	}

	return 1;
}
