local md = require "memdump"
md:initlize()

-- test global table and metatable
foo_tbl = { 1,2,3 }
setmetatable( foo_tbl,{ 3,4,5 } )
-- test reference count and table as key
bar_tbl = {}
bar_tbl[foo_tbl] = { 1,2,3 }

-- test function and upvalue
local function factory( foo )
    local bar = { 1,2,3 }
    return function()
        for k,v in pairs( foo ) do
            print( k,v )
        end
    end
end

foo_f = factory( { 1,2,3 } )

-- test coroutine
local co_upvalue = { 1,2,3 }
co = coroutine.create( function()
        for k,v in pairs( co_upvalue ) do
            print( k,v )
        end
    end
    )

-- Is there a way to get thread's upvalue ? Nethier debug.getlocal nor
-- debug.getupvalue can do that.so far,can't get infomation about co_upvalue.

md:diff()
-- md:dump()

-- upvalue不被引用时并不会成为upvalue --http://lua-users.org/lists/lua-l/2007-07/msg00451.html
