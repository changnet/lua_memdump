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
See "test.lua" for more.  

The output looks like:

```shell
table: 009bb8c8	[registry].[2].bar_tbl	1
table: 009bb8f0	[registry].[2].bar_tbl.[table: 009bb580]	1
table: 004329b0	[registry].[2].foo_f.foo	1
table: 009bb580	[registry].[2].foo_tbl	2
table: 009bb5d0	[registry].[2].foo_tbl.[metatable]	1
function: 009bf010	[registry].[2].foo_f	1
thread: 009b83a4	[registry].[2].co	1
```
Every line represent a value,column means:
[type:address] [reference point] [reference count]

note
----

* only compliex values (like function,userdata,thread,table) being analyzed
* local variable not being analyzed
