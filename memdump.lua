-- dump lua memory

local Memdump = {}

local string = string
local tostring = tostring
local type = type
local getmetatable = getmetatable

-- generate varibale descripton
function variable_desc( prefix,desc )
    local _desc = nil

    if "string" ~= type(desc) then
        _desc = string.format( "[%s]",tostring(desc) )
    else
        _desc = desc
    end

    if not prefix then return _desc end

    return string.format( "%s.%s",prefix,_desc )
end

-- make a memory snapshot
function snapshot( mark,var,desc )
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
        snapshot( mark,getmetatable(var),variable_desc( desc,"[metatable]" ) )
        for k,v in pairs( var ) do
            snapshot( mark,k,variable_desc( desc,"[key]" ) )
            snapshot( mark,v,variable_desc( desc,k ) )
        end
    elseif "function" == ty then
        local up = 1
        while true do
            local name,upvalue = debug.getupvalue( var, up )
            if not name then return end

            up = up + 1

            -- snapshot( mark,name    )
            snapshot( mark,upvalue,variable_desc( desc,name ) )
        end

        if debug.getfenv then -- lua 5.1
            snapshot( mark,debug.getfenv(var),variable_desc( desc,"[fenv]" ) )
        end
    elseif "thread" == ty then
        snapshot( mark,getmetatable(var),variable_desc( desc,"[metatable]" ) )
        if debug.getfenv then -- lua 5.1
            snapshot( mark,debug.getfenv(var),"[fenv]" )
        end
    elseif "userdata" == ty then
        snapshot( mark,getmetatable(var),variable_desc( desc,"[metatable]" ) )
        if debug.getfenv then -- lua 5.1
            snapshot( mark,debug.getfenv(var),variable_desc( desc,"[fenv]" ) )
        end
    else
        assert( false,"unknow lua type" )
    end
end

function Memdump:initlize()
    self.mem_snapshot = 
    {
        ref = {},
        obj = {},
    }

    setmetatable( self.mem_snapshot.obj,{ __mode = "k" } )
    setmetatable( self.mem_snapshot.ref,{ __mode = "k" } )

    -- don't iterate self
    self.mem_snapshot.obj[self] = true

    collectgarbage( "collect" )
    snapshot( self.mem_snapshot,debug.getregistry(),"[registry]" )
end

function Memdump:diff( file )
    assert( self.mem_snapshot ,"please call initlize ..." )

    local mem_snapshot = 
    {
        ref = {},
        obj = {},
    }

    setmetatable( mem_snapshot.obj,{ __mode = "k" } )
    setmetatable( mem_snapshot.ref,{ __mode = "k" } )

    -- don't iterate self
    mem_snapshot.obj[self] = true

    collectgarbage( "collect" )
    snapshot( mem_snapshot,debug.getregistry(),"[registry]" )

    local oldoutput = io.output( file )
    for k,v in pairs( mem_snapshot.obj ) do
        if not self.mem_snapshot.obj[k] then
            --类型 指针 变量名 所在行  引用数
            io.write( tostring(k),"\t",
                tostring(v),"\t",tostring(mem_snapshot.ref[k] or 0),"\n" )
        end
    end

    io.write( "memory snapshot diff done\n" )

    io.output( oldoutput ) -- restore old output file
end


function Memdump:dump( file )
    assert( self.mem_snapshot ,"please call initlize ..." )

    local mem_snapshot = 
    {
        ref = {},
        obj = {},
    }

    setmetatable( mem_snapshot.obj,{ __mode = "k" } )
    setmetatable( mem_snapshot.ref,{ __mode = "k" } )

    -- don't iterate self
    mem_snapshot.obj[self] = true

    collectgarbage( "collect" )
    snapshot( mem_snapshot,debug.getregistry(),"[registry]" )

    local oldoutput = io.output( file )
    for k,v in pairs( mem_snapshot.obj ) do
        --类型 指针 变量名 所在行  引用数
        io.write( tostring(k),"\t",
            tostring(v),"\t",tostring(mem_snapshot.ref[k] or 0),"\n" )
    end

    io.write( "memory snapshot dump done\n" )

    io.output( oldoutput ) -- restore old output file
end

return Memdump