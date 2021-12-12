#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

int defaultsWrite(NSArray*, NSString*);
void usage();
CFPropertyListRef parseTypedArg(NSString*, NSString*, bool);
NSObject* parsePropertyList(NSString*);
bool isType(NSString*);

/*
 * NSDateFormatter doesn't seem to work correctly,
 * so we use these deprecated methods that are used in Apple's defaults.
 */
@interface NSDate (deprecated)
+ (id)dateWithNaturalLanguageString:(NSString *)string;
+ (id)dateWithString:(NSString *)aString;
@end