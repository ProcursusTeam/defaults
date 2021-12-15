# defaults
Opensource re-implementation of `defaults(1)`

### Additions:
* `-container` - The official `defaults(1)` does not have appropriate support for containers.

### Help
```
Command line interface to a user's defaults.
Syntax:

'defaults' [-currentHost | -host <hostname>] followed by one of the following:

  read                                 shows all defaults
  read <domain>                        shows defaults for given domain
  read <domain> <key>                  shows defaults for given domain, key

  read-type <domain> <key>             shows the type for the given domain, key

  write <domain> <domain_rep>          writes domain (overwrites existing)
  write <domain> <key> <value>         writes key for domain

  rename <domain> <old_key> <new_key>  renames old_key to new_key

  delete <domain>                      deletes domain
  delete <domain> <key>                deletes key in domain

  import <domain> <path to plist>      writes the plist at path to domain
  import <domain> -                    writes a plist from stdin to domain
  export <domain> <path to plist>      saves domain as a binary plist to path
  export <domain> -                    writes domain as an xml plist to stdout
  domains                              lists all domains
  find <word>                          lists all entries containing word
  help                                 print this help

<domain> is ( <domain_name> | -app <application_name> | -globalDomain )
         or a path to a file omitting the '.plist' extension

         [-container (<bundleid> | <groupid> | <path>)]
         may be specified before the domain name to change the container
         this is a Procursus extension

<value> is one of:
  <value_rep>
  -string <string_value>
  -data <hex_digits>
  -int[eger] <integer_value>
  -float  <floating-point_value>
  -bool[ean] (true | false | yes | no)
  -date <date_rep>
  -array <value1> <value2> ...
  -array-add <value1> <value2> ...
  -dict <key1> <value1> <key2> <value2> ...
  -dict-add <key1> <value1> ...

Contact the Procursus Team for support.
```
