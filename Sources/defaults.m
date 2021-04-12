//
//  defaults.m
//  defaults
//
//  Created by quiprr on 01/20/21.
//

#import "defaults.h"

void usage()
{
    printf(
        "Usage: defaults [OPTION]...\n"
        "defaults is MIT licensed at github.com/quiprr/defaults.\n"
        "Manipulate a user's defaults from the command line.\n"
        "\n"
        "   -h, --help        Show this help message and exit.\n"
        "   -v, --version     Show version information and exit.\n"
    );
}

void version()
{
    printf(
        "defaults version 1.0.0 Copyright (c) 2021-present quiprr\n"
        "Built with Apple clang %s\n", __clang_version__
    );
}

int main(int argc, char *argv[], char *envp[])
{
    @autoreleasepool {
        NSArray <NSString *> *arguments = [[NSProcessInfo processInfo] arguments];

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