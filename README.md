# NetAngel DNS Filter Server

DNS-based web filter server with blacklists, whitelists, SafeSearch, and per-client customization.

## Installation

Make sure you have the [Redis](http://redis.io) server installed.

```bash
gem install netangel-dns
```

## Quick start

### Create a new app

```bash
netangel-dns new my_app
cd my_app
# Take a look at configuration.rb
```

### Use the porn blacklist

```
netangel-dns blacklist remote-list
netangel-dns blacklist download porn
netangel-dns blacklist enable porn
netangel-dns blacklist sync
netangel-dns client blacklists default --add porn
```

### Start DNS server

```
netangel-dns server start --verbose
```

### Now test your server using nslookup

```bash
nslookup -port=5300 google.com 127.0.0.1
# Should return successfully

nslookup -port=5300 sex.com 127.0.0.1
# Should fail because it is in the porn blacklist
```

## Usage Examples

When using the `client` command, you can set default settings that apply to **all** clients or you can target a specific client.  To configure settings that apply to all clients, use "default" as the argument.  To configure settings for a specific client, use the IP address as the argument.

```bash
# For example, to enforce YouTube Restricted Mode on everyone
netangel-dns client safesearch default --add youtube

# But you wanted 10.2.7.44 to have YouTube STRICT Restricted Mode on
netangel-dns client add 10.2.7.44  # Only have to do this once per client!
netangel-dns client safesearch 10.2.7.44 --add youtube-strict
```

### Block porn

```
netangel-dns blacklist download porn
netangel-dns blacklist enable porn
netangel-dns blacklist sync
netangel-dns client blacklists default --add porn
```

### Enforce Google SafeSearch

```
netangel-dns blacklist download ss-google
netangel-dns blacklist enable ss-google
netangel-dns blacklist sync
netangel-dns client safesearch default --add google
```

### Block specific sites not in a blacklist

```
netangel-dns client custom-blacklist 192.168.0.5 --add facebook.com instagram.com
```

### Allow a site to be accessed even if in a blacklist

```
netangel-dns client custom-whitelist 192.168.0.5 --add playboy.com
```

## Commands

```
netangel-dns new [APP_NAME]  # Create a new NetAngel DNS application
netangel-dns blacklist       # Download, sync, and manage blacklists
netangel-dns client          # Add, delete, and manage clients
netangel-dns server          # Start or stop the DNS server
netangel-dns version         # Display the program version
netangel-dns help [COMMAND]  # Describe available commands or one specific command
```

### Download, sync, and manage blacklists

```
netangel-dns blacklist delete [NAME]    # Delete blacklist from system
netangel-dns blacklist disable [NAME]   # Disable blacklist
netangel-dns blacklist download [NAME]  # Download blacklist
netangel-dns blacklist enable [NAME]    # Enable blacklist
netangel-dns blacklist help [COMMAND]   # Describe subcommands or one specific subcommand
netangel-dns blacklist list             # List available local blacklists
netangel-dns blacklist remote-list      # List available blacklists from remote server
netangel-dns blacklist sync             # Insert enabled blacklists into datastore
```

### Add, delete, and manage clients

```
netangel-dns client add [IP_ADDRESS]              # Add a new client IP address for customization
netangel-dns client blacklists [IP or ID]         # View and manage blacklists assigned to a client
netangel-dns client custom-blacklist [IP or ID]   # View and manage custom blacklist sites for a client
netangel-dns client custom-whitelist [IP or ID]   # View and manage custom whitelist sites for a client
netangel-dns client delete [IP or ID]             # Delete client
netangel-dns client get-client-id [IP_ADDRESS]    # Return the client ID of an IP address
netangel-dns client get-ip-address [CLIENT_ID]    # Return the IP address of a client
netangel-dns client help [COMMAND]                # Describe subcommands or one specific subcommand
netangel-dns client list                          # List all clients with associated IP addresses
netangel-dns client reassign [CLIENT_ID] --to=IP  # Reassign a client to a different IP address
netangel-dns client safesearch [IP or ID]         # View and manage safesearch settings for a client
netangel-dns client whitelists [IP or ID]         # View and manage whitelists assigned to a client
```

### Start or stop the DNS server

```
netangel-dns server help [COMMAND]  # Describe subcommands or one specific subcommand
netangel-dns server start           # Start DNS server
netangel-dns server status          # Server status
netangel-dns server stop            # Stop DNS server
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/net-angel/netangel-dns.

## License

The gem is available as open source under the terms of the [GPL-3.0 License](https://opensource.org/licenses/GPL-3.0).
