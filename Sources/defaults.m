#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

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
		NSMutableArray <NSString *> *arguments = [[[NSProcessInfo processInfo] arguments] mutableCopy];

		if (arguments.count == 1 || (arguments.count >= 2 && [arguments[1] isEqualToString:@"help"])) {
			usage();
			return arguments.count == 1 ? 1 : 0;
		}

		if (arguments.count >= 2 && [arguments[1] isEqualToString:@"domains"]) {
			NSMutableArray *domains = [(__bridge_transfer NSArray*)CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
			[domains removeObjectAtIndex:[domains indexOfObject:(id)kCFPreferencesAnyApplication]];
			[domains sortUsingSelector:@selector(compare:)];
			printf("%s\n", [domains componentsJoinedByString:@", "].UTF8String);
			return 0;
		}

		if (arguments.count == 2 && [arguments[1] isEqualToString:@"read"]) {
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

		if (arguments.count < 3) {
			//usage();
			return 2;
		}

		if ([arguments[1] isEqualToString:@"read"])
		{
			NSDictionary *result = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(NULL,
					([arguments[2] isEqualToString:@"-g"] || [arguments[2] isEqualToString:@"-globalDomain"]) ?
					 kCFPreferencesAnyApplication : (__bridge CFStringRef)arguments[2],
					 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

			if (arguments.count == 3)
			{
				printf("%s\n", result.description.UTF8String);
				return 0;
			} else {
				printf("%s\n", [[result objectForKey:arguments[3]] description].UTF8String);
				return 0;
			}
		}
		else if ([arguments[1] isEqualToString:@"write"] && (arguments.count == 5 || arguments.count == 6))
		{
			CFStringRef appid = ([arguments[2] isEqualToString:@"-g"] || [arguments[2] isEqualToString:@"-globalDomain"]) ?
					 kCFPreferencesAnyApplication : (__bridge CFStringRef)arguments[2];
			NSString *key = arguments[3];
			NSString *type = arguments.count == 5 ? @"-string" : arguments[4];
			NSString *value = arguments.count == 5 ? arguments[4] : arguments[5];

			if ([type isEqualToString:@"-i"] ||
					[type isEqualToString:@"-int"] ||
					[type isEqualToString:@"-integer"]) {
				CFPreferencesSetValue((__bridge CFStringRef)key,
						(__bridge CFNumberRef)@([value integerValue]),
						appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			}
			else if ([type isEqualToString:@"-f"] || [type isEqualToString:@"-float"])
			{
				CFPreferencesSetValue((__bridge CFStringRef)key,
						(__bridge CFNumberRef)@([value floatValue]),
						appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			}
			else if ([type isEqualToString:@"-b"] || [type isEqualToString:@"-bool"] || [type isEqualToString:@"-boolean"])
			{
				CFPreferencesSetValue((__bridge CFStringRef)key,
						(__bridge CFBooleanRef)@([value boolValue]),
						appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			}
			else if ([type isEqualToString:@"-s"] || [type isEqualToString:@"-string"])
			{
				CFPreferencesSetValue((__bridge CFStringRef)key,
						(__bridge CFStringRef)value,
						appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			}
			else if ([type isEqualToString:@"-date"])
			{
				CFPreferencesSetValue((__bridge CFStringRef)key,
						(__bridge CFDateRef)[[NSDateFormatter alloc] dateFromString:value],
						appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			} else {
				printf("Unrecognized type `%s`. For help, use `defaults help`.\n", [type UTF8String]);
				return 3;
			}

			return CFPreferencesSynchronize(appid, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) ? 0 : 1;
		}
	}
}
