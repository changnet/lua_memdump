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
md:initlize() -- initlize and make first memory snapshot

-- do something ...

-- make second memory and analyzes the difference
-- if no file name is specified,all result write to stdout
md:diff( "diff.log" )
```
See "test.lua" for more.  

The output looks like:

```shell
table: 0x17569a0	[registry].[2].bar_tbl	1
table: 0x1756a90	[registry].[2].foo_f.foo	1
function: 0x1756b90	[registry].[2].foo_f	1
table: 0x17569e0	[registry].[2].bar_tbl.[table: 0x1751720]	1
table: 0x17517a0	[registry].[2].bar_tbl.[key].[metatable]	1
thread: 0x1756cf8	[registry].[2].co	1
table: 0x1751720	[registry].[2].bar_tbl.[key]	2
```
Every line represent a value,column means:  
[type:address]    [reference point]    [reference count]

note
----

* only compliex values (like function,userdata,thread,table) being analyzed
* local variable not being analyzed
