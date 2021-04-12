//
//  defaults.h
//  defaults
//
//  Created by quiprr on 01/20/21.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (defaults)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end