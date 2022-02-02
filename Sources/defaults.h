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

int defaultsWrite(NSArray*, NSString*, CFStringRef, CFStringRef);
void usage(void);
CFPropertyListRef parseTypedArg(NSString*, NSString*, bool);
NSObject* parsePropertyList(NSString*);
bool isType(NSString*);
NSArray *flatten(NSObject*);
NSString *prettyName(NSString *);

/*
 * NSDateFormatter doesn't seem to work correctly,
 * so we use these deprecated methods that are used in Apple's defaults.
 */
@interface NSDate (deprecated)
+ (id)dateWithNaturalLanguageString:(NSString *)string;
+ (id)dateWithString:(NSString *)aString;
@end

@interface LSApplicationProxy : NSObject
@property(nonatomic, assign, readonly) NSString *applicationIdentifier;
+ (id)applicationProxyForIdentifier:(id)arg1;
- (NSURL *)containerURL;
- (id)localizedNameForContext:(id)context;
@end

@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allInstalledApplications;
@end

CFArrayRef _CFPreferencesCopyKeyListWithContainer(CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef container);
CFDictionaryRef _CFPreferencesCopyMultipleWithContainer(CFArrayRef keysToFetch, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef container);
CFPropertyListRef _CFPreferencesCopyValueWithContainer(CFStringRef key, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef container);
void _CFPreferencesSetMultipleWithContainer(CFDictionaryRef keysToSet, CFArrayRef keysToRemove, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef container);
void _CFPreferencesSetValueWithContainer(CFStringRef key, CFPropertyListRef value, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef container);
Boolean _CFPreferencesSynchronizeWithContainer(CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef container);
void _CFPrefsSetSynchronizeIsSynchronous(int);
void _CFPrefsSynchronizeForProcessTermination(void);
void _CFPrefSetInvalidPropertyListDeletionEnabled(int);
