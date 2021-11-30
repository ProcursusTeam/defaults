#import <CoreFoundation/CFPreferences.h>
#import <Foundation/Foundation.h>

@interface NSUserDefaults (defaults)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

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
}

int main(int argc, char *argv[], char *envp[])
{
	@autoreleasepool {
		NSArray <NSString *> *arguments = [[NSProcessInfo processInfo] arguments];

		if (arguments.count >= 2 && [arguments[1] isEqualToString:@"domains"]) {
			NSMutableArray *domains = [(__bridge_transfer NSArray*)CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
			[domains removeObjectAtIndex:[domains indexOfObject:(id)kCFPreferencesAnyApplication]];
			[domains sortUsingSelector:@selector(compare:)];
			printf("%s\n", [domains componentsJoinedByString:@", "].UTF8String);
			return 0;
		}

		if (arguments.count < 3)
		{
			usage();
			return 2;
		}

		NSString *domain = arguments[2];
		if ([domain isEqualToString:@"-globalDomain"] || [domain isEqualToString:@"-g"])
		{
			domain = @".GlobalPreferences";
		}

		NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:domain];
		NSString *action = arguments[1];

		if ([action isEqualToString:@"read"])
		{
			NSString *value = arguments.count < 4 ? defaults.dictionaryRepresentation : [defaults objectForKey:arguments[3]];

			if (value)
			{
				printf("%s\n", value.description.UTF8String);
				return 0;
			} else {
				return 1;
			}
		}
		else if ([action isEqualToString:@"write"] && (arguments.count == 5 || arguments.count == 6))
		{
			NSString *key = arguments[3];
			NSString *type = arguments.count == 5 ? @"-string" : arguments[4];
			NSString *value = arguments.count == 5 ? arguments[4] : arguments[5];

			if ([type isEqualToString:@"-i"] || [type isEqualToString:@"-int"] || [type isEqualToString:@"-integer"])
			{
				[defaults setInteger:value.integerValue forKey:key];
			}
			else if ([type isEqualToString:@"-f"] || [type isEqualToString:@"-float"])
			{
				[defaults setFloat:value.floatValue forKey:key];
			}
			else if ([type isEqualToString:@"-b"] || [type isEqualToString:@"-bool"] || [type isEqualToString:@"-boolean"])
			{
				[defaults setBool:value.boolValue forKey:key];
			}
			else if ([type isEqualToString:@"-s"] || [type isEqualToString:@"-string"])
			{
				[defaults setObject:value forKey:key];
			} else {
				printf("Unrecognized type `%s`. For help, use `%s --help`.\n", [type UTF8String], argv[0]);
				return 3;
			}

			return [defaults synchronize] ? 0 : 1;
		}
	}
}
