lua_memdump
-----------
A tool to dump lua state memory or analyzes difference of two memory snapshot.
Very helpful to analyzes your program's memory layout or dectect memory leak.

usage & example
----------------
* dump memory  

```lua
local md = require "memdump"

-- if no file name is specified,all result write to stdout
md:dump( "dump.log" )
```

* analyzes difference of two memory snapshot  

```lua
local md = require "memdump"

-- if no file name is specified,all result write to stdout
md:diff( "diff.log" )
```

The output looks like:

```shell
```

note
----

* only compliex values (like function,userdata,thread,table) being analyzed
* local variable not being analyzed
