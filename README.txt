Getting lua running on your system:

Prerequsites:

- lua      - the lua language runtime/interpreter, version 5.1+.
- luarocks - the 'gem'-like system for lua.

For example, on Mac OSX:

$ sudo port install lua

Then, get luarocks:

$ sudo port install luarocks

Then:

$ luarocks install luasocket

Then, make sure LUA_PATH is setup right.  For example,
somewhere in my ~/.profile file, I have:

export LUA_PATH=".//?.lua;/usr/local/share/lua/5.1//?.lua;/usr/local/share/lua/5.1//?/init.lua;$LUA_PATH"

To get a lua REPL with luarocks enabled, use:

$ lua -l luarocks.require

Or to launch a script, use:

$ lua -l luarocks.require <some_script.lua> <arg1> ... <argN>

To start a server, use:

$ lua -l luarocks.require main.lua

To run client tests, use:

$ lua -l luarocks.require protocol_memcached/test_client_ascii.lua [host:port]
$ lua -l luarocks.require protocol_memcached/test_client_binary.lua [host:port]
