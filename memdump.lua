-- dump lua memory

local Memdump = {}

local string = string
local tostring = tostring
local type = type
local getmetatable = getmetatable

-- generate varibale descripton
function Memdump.variable_desc( prefix,desc )
    local _desc = nil

    if "string" ~= type(desc) then
        _desc = string.format( "[%s]",tostring(desc) )
    else
        _desc = desc
    end

    if not prefix then return _desc end

    return string.format( "%s.%s",prefix,_desc )
end

-- make a memory Memdump.snapshot
function Memdump.snapshot( mark,var,desc )
    -- already mark
    if nil == var then return end

    local ty = type(var)
    if "nil" == ty or "number" == ty or "boolean" == ty or "string" == ty then
        return
    end

    mark.ref[var] = 1 + ( mark.ref[var] or 0 )

    if nil ~= mark.obj[var] then return end
    -- mark before iterate,avoid circular reference
    mark.obj[var] = desc

    if "table" == ty then
        Memdump.snapshot( mark,
            getmetatable(var),Memdump.variable_desc( desc,"[metatable]" ) )
        for k,v in pairs( var ) do
            Memdump.snapshot( mark,k,Memdump.variable_desc( desc,"[key]" ) )
            Memdump.snapshot( mark,v,Memdump.variable_desc( desc,k ) )
        end
    elseif "function" == ty then
        local up = 1
        while true do
            local name,upvalue = debug.getupvalue( var, up )
            if not name then return end

            up = up + 1

            -- Memdump.snapshot( mark,name    )
            Memdump.snapshot( mark,upvalue,Memdump.variable_desc( desc,name ) )
        end

        if debug.getfenv then -- lua 5.1
            Memdump.snapshot( mark,debug.getfenv(var),
                Memdump.variable_desc( desc,"[fenv]" ) )
        end
    elseif "thread" == ty then
        Memdump.snapshot( mark,getmetatable(var),
            Memdump.variable_desc( desc,"[metatable]" ) )
        if debug.getfenv then -- lua 5.1
            Memdump.snapshot( mark,debug.getfenv(var),"[fenv]" )
        end

        -- A coroutine in dead status or never resume do not have call info.
        -- We can't not get it's local value info in pure lua.However,it's
        -- first function remain in stack,we can easily get it in c.
        if debug.getinfo( var,1 ) then
            local upindex = 1
            local _desc = Memdump.variable_desc( desc,var )
            while true do
                local name,upvalue = debug.getlocal( var,1,upindex )
                if not name then break end

                Memdump.snapshot( mark,
                    upvalue,Memdump.variable_desc( _desc,name ) )
                upindex = upindex + 1
            end
        end
    elseif "userdata" == ty then
        Memdump.snapshot( mark,getmetatable(var),
            Memdump.variable_desc( desc,"[metatable]" ) )
        if debug.getfenv then -- lua 5.1
            Memdump.snapshot( mark,debug.getfenv(var),
                Memdump.variable_desc( desc,"[fenv]" ) )
        end
    else
        assert( false,"unknow lua type" )
    end
end

-- initlize and make first memory snapshot
function Memdump:initlize()
    self.mem_snapshot =
    {
        ref = {},
        obj = {},
    }

    setmetatable( self.mem_snapshot.obj,{ __mode = "k" } )
    setmetatable( self.mem_snapshot.ref,{ __mode = "k" } )

    self.new_mem_snapshot = 
    {
        ref = {},
        obj = {},
    }

    setmetatable( self.new_mem_snapshot.obj,{ __mode = "k" } )
    setmetatable( self.new_mem_snapshot.ref,{ __mode = "k" } )

    -- don't iterate self
    self.mem_snapshot.obj[self] = true
    self.mem_snapshot.obj[self.new_mem_snapshot] = true

    self.new_mem_snapshot.obj[self] = true
    self.new_mem_snapshot.obj[self.new_mem_snapshot] = true

    collectgarbage( "collect" )
    Memdump.snapshot( self.mem_snapshot,debug.getregistry(),"[registry]" )
end

function Memdump:diff( file )
    assert( self.mem_snapshot ,"please call initlize ..." )

    -- make twice gc,make sure weak reference object being gc
    collectgarbage( "collect" )
    collectgarbage( "collect" )
    Memdump.snapshot( self.new_mem_snapshot,debug.getregistry(),"[registry]" )

    local oldoutput = io.output( file )
    for k,v in pairs( self.new_mem_snapshot.obj ) do
        if not self.mem_snapshot.obj[k] then
            --类型 指针 变量名 所在行  引用数
            io.write( tostring(k),"\t",tostring(v),"\t",
                tostring(self.new_mem_snapshot.ref[k] or 0),"\n" )
        end
    end

    io.write( "memory Memdump.snapshot diff done\n" )

    io.output( oldoutput ) -- restore old output file
end


function Memdump:dump( file )
    assert( self.mem_snapshot ,"please call initlize ..." )

    local oldoutput = io.output( file )
    for k,v in pairs( self.mem_snapshot.obj ) do
        --类型 指针 变量名 所在行  引用数
        io.write( tostring(k),"\t",
            tostring(v),"\t",tostring(self.mem_snapshot.ref[k] or 0),"\n" )
    end

    io.write( "memory Memdump.snapshot dump done\n" )

    io.output( oldoutput ) -- restore old output file
end

return Memdump
