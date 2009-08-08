Getting lua running on your system:

Prerequsites:

- lua      - the lua language runtime/interpreter
- luarocks - the 'gem'-like system for lua.

For example:

$ sudo port install lua

Then, get luarocks and make/install it.

Then:

$ luarocks install luasocket
$ luarocks install copas

Then, make sure LUA_PATH is setup right.  For example,
somewhere in my ~/.profile file, I have:

export LUA_PATH="/usr/local/share/lua/5.1//?.lua;/usr/local/share/lua/5.1//?/init.lua;$LUA_PATH"

To get a lua REPL, use:

$ lua -l luarocks.require

Or to launch a script, use:

$ lua -l luarocks.require <some_script.lua> <arg1> ... <argN>

In particular, use:

$ lua -l luarocks.require main.lua

