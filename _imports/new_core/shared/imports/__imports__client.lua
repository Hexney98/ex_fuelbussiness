table = {
    insert = table.insert,
    remove = table.remove, 
    concat = table.concat, 
    sort = table.sort, 
    setn = table.setn,
    maxn = table.maxn,
    getn = table.getn,
    foreachi = table.foreachi,
    foreach = table.foreach,

    -- Add values from the source table to the target table
    length_keytbl=function(x) if not x then return 0 end assert(type(x) == "table", "length_keytbl expected table at argument 1, got \"" .. type(x) .. "\""); local length = 0; for k,v in pairs(x) do length = length + 1; end return length; end, 
    merge=function(a,b)for c,d in pairs(b)do if type(d)=='table'then a[c]=table.merge(a[c]or{},d)else if not a[c] then a[c]=d end end end;return a end,
    findIndex=function(a,b)for c=1,#a do if b(a[c],c)then return c end end;return false end,
    findIndex_keytbl=function(a,b)for c,d in pairs(a)do if b(d,c)then return c end end;return false end,
    find=function(a,b)for c=1,#a do if b(a[c],c)then return a[c]end end;return false end,
    find_keytbl=function(a,b)for c,d in pairs(a)do if b(d,c)then return d end end;return false end,
    map=function(a,b)local c={}for d=1,#a do c[d]=b(a[d],d,a)end;return c end, 
    map_keytbl=function(a,b)local c={}for k,v in pairs(a) do c[k]=b(v,k,a)end;return c end, 
    filter=function(a,b)local c={}for d=1,#a do if b(a[d],d)then table.insert(c,a[d])end end;return c end, 
    filter_keytbl=function(a,b)local c={}for d,e in pairs(a)do if b(e,d)then c[d]=e end end;return c end, 
    copy=function(a)local b={}for c,d in pairs(a)do b[c]=d end;return b end, 
    compare_keytbl=function(a,b)for c,d in pairs(a)do if not b[c]or type(d)~=type(b[c])or d~=b[c]then return false end end;return true end, 
    reduce=function(a,b,c)local d=c or 0;for e=1,#a do d=b(d,a[e],e)end;return d end, 
    reduce_keytbl=function(a,b,c)local d=c or 0;for e,f in pairs(a)do d=b(d,f,e)end;return d end,
    shuffle=function(a)local b={}for c=1,#a do b[c]=a[c]end;for c=#a,2,-1 do local d=math.random(c)b[c],b[d]=b[d],b[c]end;return b end
};

__ClassHelpers = {
    IgnoredMethods = { ["__Constructor"] = true },
    Initialize = function(self, Props, __Internal)
        -- add middleware functions & init properties
        for k,v in pairs(Props) do
            if (type(v) == "function") then 
                self[k] = function(...) return __Internal.__ClassMethods[k](self, ...); end;
            else
                self[k] = v;
            end 
        end 

        if (type(Props["__Constructor"]) == "function") then
            Props["__Constructor"](self, unpack(__Internal.__ConstructorData));
        end 

        self["__Deconstruct"] = function()
            for k,v in pairs(self) do self[k] = nil; end 
            self = nil;
        end

        return self;
    end, 
};

Class = function(Props)
    local __ClassMethods = {};

    -- copy methods
    for k,v in pairs(Props) do
        if (type(v) == "function" and not __ClassHelpers.IgnoredMethods[k]) then 
            __ClassMethods[k] = v;
        end 
    end 

    return (function(...)
        return __ClassHelpers.Initialize({ }, Props, { __ConstructorData = { ... }, __ClassMethods = __ClassMethods });
    end);
end

local __IsClient = guiGetScreenSize ~= nil;

-- 
-- Server
--
if (not guiGetScreenSize) then 
    local __FetchList = {};

    local __ValidateArgs = function(Schemas, EventData)
        if (type(Schemas) ~= "table") then return true; end 

        for Index = 1, #Schemas do 
            if (type(Schemas[Index]) ~= "table") then 
                local Success, Error = Schemas[Index].Validate(EventData.Data[Index]);
                if (not Success) then 
                    return false;
                end 
            end 
        end 

        return true;
    end

    local __HandleFetch = function(Fetch, Source, EventData)
        local Handle;
        Handle = function(...)           
            local Payload = { Data = { ... }, __ResponseEventName = ResponseEventName };
            triggerClientEvent(Source, EventData.__ResponseEventName, resourceRoot, Payload);
        end

        local HandleArgs = (type(EventData) == "table" and type(EventData.Data) == "table") and EventData.Data or {};
        Fetch.Func(Handle, Source, unpack(HandleArgs));
    end 

    local __RegisterNewEvent = function(EventName, Callback, Schema)
        local RegisteredEvent = EventName; -- Valami obfuscation lehetne majd ilyenekre.
        local Schema = (type(Schema) == "table") and Schema or {};

        if (__FetchList[EventName]) then 
            outputDebugString(EventName .. " már regisztrálva van.", 1);
            return false;
        end 
    
        __FetchList[EventName] = {
            BaseEvent = EventName, 
            -- UniqueEvent = , 
            Func = Callback,
            Schema = Schema, 
        };
    
        addEvent(RegisteredEvent, true);
        addEventHandler(RegisteredEvent, resourceRoot, function(EventData)
            if (
                (type(Schema.Client) ~= "table" or Schema.Client.Validate(client)) and 
                (type(Schema.Args) ~= "table" or __ValidateArgs(Schema.Args, EventData))
            ) then 
                __HandleFetch(__FetchList[EventName], client, EventData);
            end 
        end);
    
        return true;
    end 

    AddFetch = function(EventName, Callback, Schema)
        return __RegisterNewEvent(EventName, Callback, Schema);
    end
else 
    -- local __EmitFetchRoutine = function(EventName, Data, Source, ResponseEventName)
    --     local RemoteResponse;
    --     local Handle, OnTimeout, TimeoutTimer;
    
    --     Handle = function(...)
    --         iprint("VISSZAKAPTAM SEROTOL: ", ...);
    --         removeEventHandler(ResponseEventName, resourceRoot, Handle);
    --         if (isTimer(TimeoutTimer)) then killTimer(TimeoutTimer); end 
    
    --         RemoteResponse = { ... };
    --         coroutine.yield();
    --     end
    
    --     addEvent(ResponseEventName, true);
    --     addEventHandler(ResponseEventName, resourceRoot, Handle);
    --     -- TimeoutTimer = setTimer(OnTimeout, 10000, 1);
    
    --     coroutine.yield();
    
    --     -- coroutine.resume(RoutineHandle, nil, "Fetch timed out.");
    --     return RemoteResponse;
    -- end
    
    -- local __EmitFetch = function(EventName, Data, Source)
    --     local ResponseEventName = getResourceName(getThisResource()) .. "::" .. EventName .. "::CatchResponse::" .. string.random(6);
    
    --     local RoutineHandle = coroutine.create(__EmitFetchRoutine);
    --     coroutine.resume(RoutineHandle, EventName, Data, Source, ResponseEventName)
    
    --     local Payload = { Data = Data, __ResponseEventName = ResponseEventName };
    --     if (__IsClient) then 
    --         triggerServerEvent(EventName, resourceRoot, Payload);
    --     else 
    --         triggerClientEvent(Source, EventName, resourceRoot, Payload);
    --     end 
    
    --     -- iprint("ROUTINE GECI", RoutineHandle, coroutine.status(RoutineHandle));
    --     -- local Success, Data = coroutine.resume(RoutineHandle);
    --     -- iprint("MUGOGY GEC", Success, Data);
    --     -- if (not Success) then error(Data); end 
    
    --     return Data;
    -- end 
    
    -- UseFetch = function(EventName, ...)
    --     local Args, Source, Data = { ... };
    --     if (not __IsClient) then 
    --         Source = Args[1] or resourceRoot;
    --         table.remove(Args, 1);
    --         Data = Args;
    --     end  
    
    --     local Result = __EmitFetch(EventName, Data, Source);
    --     return Result;
    -- end 
    
    local __PendingRequests = {};
    local __TimeoutRequestAfter = 3000;

    local __EmitFetchAsync = function(EventName, Callback, Data)
        local ResponseEventName = getResourceName(getThisResource()) .. "::" .. EventName .. "::CatchResponse::" .. string.random(6);
    
        local EventHandle;
        EventHandle = function(Payload)
            removeEventHandler(ResponseEventName, resourceRoot, EventHandle);
            Callback(unpack(Payload.Data));

            --__PendingRequests[EventName] = nil;
        end 
    
        addEvent(ResponseEventName, true);
        addEventHandler(ResponseEventName, resourceRoot, EventHandle);

        local Payload = { Data = Data, __ResponseEventName = ResponseEventName };
        triggerServerEvent(EventName, resourceRoot, Payload);

        return true;
    end 
    
    UseFetchAsync = function(EventName, Callback, ...)
        assert(type(EventName) == "string", "UseFetchAsync's #1 arg must be a string (EventName)!");
        assert(type(Callback) == "function", "UseFetchAsync's #2 arg must be a callback function!");

        --if (
        --    __PendingRequests[EventName] and 
        --    __PendingRequests[EventName] + __TimeoutRequestAfter > getTickCount()
        --) then 
            --return false;
        --end 

        --__PendingRequests[EventName] = getTickCount();
        __EmitFetchAsync(EventName, Callback, { ... });
    end 

    _UnsafeUseFetchAsync = function(EventName, Callback, ...)
        assert(type(EventName) == "string", "UseFetchAsync's #1 arg must be a string (EventName)!");
        assert(type(Callback) == "function", "UseFetchAsync's #2 arg must be a callback function!");

        __PendingRequests[EventName] = true;
        return __EmitFetchAsync(EventName, Callback, { ... });
    end 
end 

if (getResourceName(getThisResource()) ~= "ex_new_core") then
    local function loadClass()
        ---------
        -- Start of slither.lua dependency
        ---------
    
        local _LICENSE = -- zlib / libpng
        [[
        Copyright (c) 2011-2014 Bart van Strien
    
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for any damages
        arising from the use of this software.
    
        Permission is granted to anyone to use this software for any purpose,
        including commercial applications, and to alter it and redistribute it
        freely, subject to the following restrictions:
    
          1. The origin of this software must not be misrepresented; you must not
          claim that you wrote the original software. If you use this software
          in a product, an acknowledgment in the product documentation would be
          appreciated but is not required.
    
          2. Altered source versions must be plainly marked as such, and must not be
          misrepresented as being the original software.
    
          3. This notice may not be removed or altered from any source
          distribution.
        ]]
    
        local class =
        {
            _VERSION = "Slither 20140904",
            -- I have no better versioning scheme, deal with it
            _DESCRIPTION = "Slither is a pythonic class library for lua",
            _URL = "http://bitbucket.org/bartbes/slither",
            _LICENSE = _LICENSE,
        }
    
        local function stringtotable(path)
            local t = _G
            local name
    
            for part in path:gmatch("[^%.]+") do
                t = name and t[name] or t
                name = part
            end
    
            return t, name
        end
    
        local function class_generator(name, b, t)
            local parents = {}
            for _, v in ipairs(b) do
                parents[v] = true
                for _, v in ipairs(v.__parents__) do
                    parents[v] = true
                end
            end
    
            local temp = { __parents__ = {} }
            for i, v in pairs(parents) do
                table.insert(temp.__parents__, i)
            end
    
            local class = setmetatable(temp, {
                __index = function(self, key)
                    if key == "__class__" then return temp end
                    if key == "__name__" then return name end
                    if t[key] ~= nil then return t[key] end
                    for i, v in ipairs(b) do
                        if v[key] ~= nil then return v[key] end
                    end
                    if tostring(key):match("^__.+__$") then return end
                    if self.__getattr__ then
                        return self:__getattr__(key)
                    end
                end,
    
                __newindex = function(self, key, value)
                    t[key] = value
                end,
    
                allocate = function(instance)
                    local smt = getmetatable(temp)
                    local mt = {__index = smt.__index}
    
                    function mt:__newindex(key, value)
                        if self.__setattr__ then
                            return self:__setattr__(key, value)
                        else
                            return rawset(self, key, value)
                        end
                    end
    
                    if temp.__cmp__ then
                        if not smt.eq or not smt.lt then
                            function smt.eq(a, b)
                                return a.__cmp__(a, b) == 0
                            end
                            function smt.lt(a, b)
                                return a.__cmp__(a, b) < 0
                            end
                        end
                        mt.__eq = smt.eq
                        mt.__lt = smt.lt
                    end
    
                    for i, v in pairs{
                        __call__ = "__call", __len__ = "__len",
                        __add__ = "__add", __sub__ = "__sub",
                        __mul__ = "__mul", __div__ = "__div",
                        __mod__ = "__mod", __pow__ = "__pow",
                        __neg__ = "__unm", __concat__ = "__concat",
                        __str__ = "__tostring",
                        } do
                        if temp[i] then mt[v] = temp[i] end
                    end
    
                    return setmetatable(instance or {}, mt)
                end,
    
                __call = function(self, ...)
                    local instance = getmetatable(self).allocate()
                    if instance.__init__ then instance:__init__(...) end
                    return instance
                end
                })
    
            for i, v in ipairs(t.__attributes__ or {}) do
                class = v(class) or class
            end
    
            return class
        end
    
        local function inheritance_handler(set, name, ...)
            local args = {...}
    
            for i = 1, select("#", ...) do
                if args[i] == nil then
                    error("nil passed to class, check the parents")
                end
            end
    
            local t = nil
            if #args == 1 and type(args[1]) == "table" and not args[1].__class__ then
                t = args[1]
                args = {}
            end
    
            for i, v in ipairs(args) do
                if type(v) == "string" then
                    local t, name = stringtotable(v)
                    args[i] = t[name]
                end
            end
    
            local func = function(t)
                local class = class_generator(name, args, t)
                if set then
                    local root_table, name = stringtotable(name)
                    root_table[name] = class
                end
                return class
            end
    
            if t then
                return func(t)
            else
                return func
            end
        end
    
        function class.private(name)
            return function(...)
                return inheritance_handler(false, name, ...)
            end
        end
    
        class = setmetatable(class, {
            __call = function(self, name)
                return function(...)
                    return inheritance_handler(true, name, ...)
                end
            end,
        })
    
    
        function class.issubclass(class, parents)
            if parents.__class__ then parents = {parents} end
            for i, v in ipairs(parents) do
                local found = true
                if v ~= class then
                    found = false
                    for _, p in ipairs(class.__parents__) do
                        if v == p then
                            found = true
                            break
                        end
                    end
                end
                if not found then return false end
            end
            return true
        end
    
        function class.isinstance(obj, parents)
            return type(obj) == "table" and obj.__class__ and class.issubclass(obj.__class__, parents)
        end
    
        -- Export a Class Commons interface
        -- to allow interoperability between
        -- class libraries.
        -- See https://github.com/bartbes/Class-Commons
        --
        -- NOTE: Implicitly global, as per specification, unfortunately there's no nice
        -- way to both provide this extra interface, and use locals.
        if common_class ~= false then
            common = {}
            function common.class(name, prototype, superclass)
                prototype.__init__ = prototype.init
                return class_generator(name, {superclass}, prototype)
            end
    
            function common.instance(class, ...)
                return class(...)
            end
        end
    
        ---------
        -- End of slither.lua dependency
        ---------
    
        return class;
    end
    
    local class = loadClass();
    
    --- GTA:MTA Lua async thread scheduler.
    -- @author Inlife
    -- @license MIT
    -- @url https://github.com/Inlife/mta-lua-async
    -- @dependency slither.lua https://bitbucket.org/bartbes/slither
    
    class "_Async" {
        
        -- Constructor mehtod
        -- Starts timer to manage scheduler
        -- @access public
        -- @usage local asyncmanager = async();
        __init__ = function(self)
    
            self.threads = {};
            self.resting = 50; -- in ms (resting time)
            self.maxtime = 200; -- in ms (max thread iteration time)
            self.current = 0;  -- starting frame (resting)
            self.state = "suspended"; -- current scheduler executor state
            self.debug = false;
            self.priority = {
                low = {500, 50},     -- better fps
                normal = {200, 200}, -- medium
                high = {50, 500}     -- better perfomance
            };
    
            self:setPriority("normal");
        end,
    
    
        -- Switch scheduler state
        -- @access private
        -- @param boolean [istimer] Identifies whether or not 
            -- switcher was called from main loop
        switch = function(self, istimer)
            self.state = "running";
    
            if (self.current + 1  <= #self.threads) then
                self.current = self.current + 1;
                self:execute(self.current);
            else
                self.current = 0;
    
                if (#self.threads <= 0) then
                    self.state = "suspended";
                    return;
                end
    
                -- setTimer(function theFunction, int timeInterval, int timesToExecute) 
                -- (GTA:MTA server scripting function)
                -- For other environments use alternatives.
                setTimer(function() 
                    self:switch();
                end, self.resting, 1);
            end
        end,
    
    
        -- Managing thread (resuming, removing)
        -- In case of "dead" thread, removing, and skipping to the next (recursive)
        -- @access private
        -- @param int id Thread id (in table async.threads)
        execute = function(self, id)
            local thread = self.threads[id];
    
            if (thread == nil or coroutine.status(thread) == "dead") then
                table.remove(self.threads, id);
                self:switch();
            else
                coroutine.resume(thread);
                self:switch();
            end
        end,
    
    
        -- Adding thread
        -- @access private
        -- @param function func Function to operate with
        add = function(self, func)
            local thread = coroutine.create(func);
            table.insert(self.threads, thread);
        end,
    
    
        -- Set priority for executor
        -- Use before you call 'iterate' or 'foreach' 
        -- @access public
        -- @param string|int param1 "low"|"normal"|"high" or number to set 'resting' time
        -- @param int|void param2 number to set 'maxtime' of thread
        -- @usage async:setPriority("normal");
        -- @usage async:setPriority(50, 200);
        setPriority = function(self, param1, param2)
            if (type(param1) == "string") then
                if (self.priority[param1] ~= nil) then
                    self.resting = self.priority[param1][1];
                    self.maxtime = self.priority[param1][2];
                end
            else
                self.resting = param1;
                self.maxtime = param2;
            end
        end,
    
        -- Set debug mode enabled/disabled
        -- @access public
        -- @param boolean value true - enabled, false - disabled
        -- @usage async:setDebug(true);
        setDebug = function(self, value)
            self.debug = value;
        end,
    
    
        -- Iterate on interval (for cycle)
        -- @access public
        -- @param int from Iterate from
        -- @param int to Iterate to
        -- @param function func Iterate using func
            -- Function func params:
            -- @param int [i] Iteration index
        -- @param function [callback] Callback function, called when execution finished
        -- Usage:
            -- @usage async:iterate(1, 10000, function(i)
            --     print(i);
            -- end);
        iterate = function(self, from, to, func, callback)
            self:add(function()
                local a = getTickCount();
                local lastresume = getTickCount();
                for i = from, to do
                    func(i); 
    
                    -- int getTickCount() 
                    -- (GTA:MTA server scripting function)
                    -- For other environments use alternatives.
                    if getTickCount() > lastresume + self.maxtime then
                        coroutine.yield()
                        lastresume = getTickCount()
                    end
                end
                if (self.debug) then
                    print("[DEBUG]Async iterate: " .. (getTickCount() - a) .. "ms");
                end
                if (callback) then
                    callback();
                end
            end);
    
            self:switch();
        end,
    
        -- Iterate over array (foreach cycle)
        -- @access public
        -- @param table array Input array
        -- @param function func Iterate using func
            -- Function func params:
            -- @param int [v] Iteration value
            -- @param int [k] Iteration key
        -- @param function [callback] Callback function, called when execution finished
        -- Usage:
            -- @usage async:foreach(vehicles, function(vehicle, id)
            --     print(vehicle.title);
            -- end);
        foreach = function(self, array, func, callback)
            self:add(function()
                local a = getTickCount();
                local lastresume = getTickCount();
                for k,v in ipairs(array) do
                    func(v,k);
    
                    -- int getTickCount() 
                    -- (GTA:MTA server scripting function)
                    -- For other environments use alternatives.
                    if getTickCount() > lastresume + self.maxtime then
                        coroutine.yield()
                        lastresume = getTickCount()
                    end
                end
                if (self.debug) then
                    print("[DEBUG]Async foreach: " .. (getTickCount() - a) .. "ms");
                end
                if (callback) then
                    callback();
                end
            end);
    
            self:switch();
        end,
    }
    
    -- Async Singleton wrapper
    Async = {
        instance = nil,
    };
    
    -- After first call, creates an instance and stores it
    local function getInstance()
        if Async.instance == nil then
            Async.instance = _Async();
        end
    
        return Async.instance; 
    end
    
    -- proxy methods for public members
    function Async:setDebug(...)
        getInstance():setDebug(...);
    end
    
    function Async:setPriority(...)
        getInstance():setPriority(...);
    end
    
    function Async:iterate(...)
        getInstance():iterate(...);
    end
    
    function Async:foreach(...)
        getInstance():foreach(...);
    end

    function GetColor()
    end 

    
-- IPlayerKeys = IPlayerKeys or exports[!(MOD_PREFIX .. "new_core")]:GetPlayerKeys() or {
IPlayerKeys = {
    CHARACTER_ID = "dbid", 
	
    SPAWNED = "spawned",
    HIDDEN = "user:hiddenadmin", 

    PLAYER_ID = "playerid",
    CHAR_NAME = "char:Name",

    MONEY = "char:Money",

    ADMIN_LEVEL = "user:adminlevel", 
    ADMIN_NAME = "user:adminnick", 
    ADMIN_DUTY = "user:adminduty", 
	
	HELPER_LEVEL = "user:helperlevel", 
};

 
    ScreenWidth, ScreenHeight = guiGetScreenSize();

    local __ReMap = function(value, low1, high1, low2, high2)
        return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
    end; reMap = __ReMap;

    local ResponsiveMultiplier = __ReMap(ScreenWidth, 1024, 3840, 0.75, 1.75); local responsiveMultiplier = ResponsiveMultiplier;

    GetResp = function()
        return ResponsiveMultiplier;
    end; getResp = GetResp;

    Resp = function(value)
        return value * ResponsiveMultiplier;
    end; resp = Resp;
    
    Respc = function(value)
        return math.ceil(value * ResponsiveMultiplier);
    end; respc = Respc;
    
    __VisibilityDiff = 100;

    local __getCursorPosition = getCursorPosition;
    getCursorPosition = function(Default)
        if (not isCursorShowing()) then return -1, -1; end 
        local cursorX, cursorY, WorldX, WorldY, WorldZ = __getCursorPosition();
        if (Default) then return cursorX, cursorY, WorldX, WorldY, WorldZ end
        
        return cursorX * ScreenWidth, cursorY * ScreenHeight;
    end; GetCursorPosition = getCursorPosition;

    isCursorInArea = function(position_or_x, size_or_y, width, height)
        if (not position_or_x or not size_or_y) then 
            return false;
        end 
        local x, y = position_or_x, size_or_y;
        if (width == nil and height == nil) then
            width, height = size_or_y.x, size_or_y.y;
            x, y = position_or_x.x, position_or_x.y;
        end 
        local cursorX, cursorY = getCursorPosition();
        return (
            cursorX > x and cursorX < x + width and 
            cursorY > y and cursorY < y + height
        );
    end; IsCursorInArea = isCursorInArea;
    
    function SplitLongWord(Word, Font, FontSize, RectangleWidth)
        if (dxGetTextWidth(Word, FontSize, Font) <= RectangleWidth) then 
            return Word;
        end 

        local Splitted = "";

        for Index = string.len(Word), 1, -5 do 
            local PartialSplit = string.sub(Word, 1, Index);
            if (dxGetTextWidth(PartialSplit, FontSize, Font) <= RectangleWidth * 0.95) then 
                Splitted = PartialSplit .. " " .. SplitLongWord(string.sub(Word, Index + 1), Font, FontSize, RectangleWidth);
                break;
            end 
        end 

        return Splitted;
    end 

    local __TextHeightCache = {}; 
    setTimer(function() local Tick = getTickCount(); for k,v in pairs(__TextHeightCache) do if (v.Tick + 1000 < Tick) then __TextHeightCache[k] = nil; end end end, 2000, 0);
    dxGetTextHeight = function(Text, Font, FontSize, RectangleWidth)
        local CacheKey = Text .. ";" .. tostring(Font) .. ";" .. tostring(FontSize) .. ";" .. tostring(RectangleWidth);
        if (CacheKey and __TextHeightCache[CacheKey]) then 
            __TextHeightCache[CacheKey].Tick = getTickCount();
            return __TextHeightCache[CacheKey].Lines;
        end 

        Text = Text:gsub("%S+", function(Word) return SplitLongWord(Word, Font, FontSize, RectangleWidth); end);
        local LineText = "";
        local LinesCount = 1;

        for Word in Text:gmatch("%S+") do
            local TempLineText = LineText .. " " .. Word;
            if (dxGetTextWidth(TempLineText, FontSize, Font) > RectangleWidth) then
                LineText = Word;
                LinesCount = LinesCount + 1;
            else
                LineText = TempLineText;
            end
        end
        
        __TextHeightCache[CacheKey] = { Tick = getTickCount(), Lines = LinesCount };
        return LinesCount;
    end; DxGetTextHeight = dxGetTextHeight;

    function dxDrawStrokedText(text, x, y, width, height, stroke, sides, color, ...)
        local width = (width or 0);
        local height = (height or 0);
        
        local escaped = text:gsub("#%x%x%x%x%x%x", "");
        
        for i = 1, sides do 
            local angle = i * math.pi / 180 * (360 / sides);
            local textX, textY = x + stroke * math.cos(angle), y + stroke * math.sin(angle);
            dxDrawText(escaped, textX, textY, _, _, tocolor(0, 0, 0), ...);
        end 
        
        dxDrawText(text, x, y, width, height, color, ...);
    end 


function OutputToEveryone(Message, Color, Suffix)
    assert(guiGetScreenSize == nil, "OutputToEveryone is server-side only!");

    OutputToPlayers(Message, root, Color, Suffix);
end 

table = {
    insert = table.insert,
    remove = table.remove, 
    concat = table.concat, 
    sort = table.sort, 
    setn = table.setn,
    maxn = table.maxn,
    getn = table.getn,
    foreachi = table.foreachi,
    foreach = table.foreach,

    -- Add values from the source table to the target table
    length_keytbl=function(x) assert(type(x) == "table", "length_keytbl expected table at argument 1, got \"" .. type(x) .. "\""); local length = 0; for k,v in pairs(x) do length = length + 1; end return length; end, 
    merge=function(a,b)for c,d in pairs(b)do if type(d)=='table'then a[c]=table.merge(a[c]or{},d)else if not a[c] then a[c]=d end end end;return a end,
    findIndex=function(a,b)for c=1,#a do if b(a[c],c)then return c end end;return false end,
    findIndex_keytbl=function(a,b)for c,d in pairs(a)do if b(d,c)then return c end end;return false end,
    find=function(a,b)for c=1,#a do if b(a[c],c)then return a[c]end end;return false end,
    find_keytbl=function(a,b)for c,d in pairs(a)do if b(d,c)then return d end end;return false end,
    map=function(a,b)local c={}for d=1,#a do c[d]=b(a[d],d,a)end;return c end, 
    map_keytbl=function(a,b)local c={}for k,v in pairs(a) do c[k]=b(v,k,a)end;return c end, 
    filter=function(a,b)local c={}for d=1,#a do if b(a[d],d)then table.insert(c,a[d])end end;return c end, 
    filter_keytbl=function(a,b)local c={}for d,e in pairs(a)do if b(e,d)then c[d]=e end end;return c end, 
    copy=function(a)local b={}for c,d in pairs(a)do b[c]=d end;return b end, 
    compare_keytbl=function(a,b)for c,d in pairs(a)do if not b[c]or type(d)~=type(b[c])or d~=b[c]then return false end end;return true end, 
    reduce=function(a,b,c)local d=c or 0;for e=1,#a do d=b(d,a[e],e)end;return d end, 
    reduce_keytbl=function(a,b,c)local d=c or 0;for e,f in pairs(a)do d=b(d,f,e)end;return d end
};

local __STR_RAND_CHARSET = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890";
string.random = function(length)
    math.randomseed(os.clock());
    local result = {};
    
    for i = 1, length do
        local rand = math.random(1, #__STR_RAND_CHARSET);
        table.insert(result, __STR_RAND_CHARSET:sub(rand, rand));
    end

    return table.concat(result);
end 

math.clamp = function(Value, Min, Max)
    return math.max(Min, math.min(Max, Value));
end 

-- felulirom a kurva ascii karakteres faszt utf8al, mert 
-- a tetves szar ekezetes karaktereket csak felig torol vissza...
-- ( Text:sub(1, -2) ) pl
for MethodName in pairs(getmetatable("").__index) do 
    if (type(utf8[MethodName]) == "function") then 
        getmetatable("").__index[MethodName] = function(str, ...) 
            return utf8[MethodName](str, ...); 
        end;
    end 
end 

local __ReferencePool = {};
-- local __ResourcePrefix = exports[!(MOD_PREFIX .. "new_core")]:GetConfigProperty("ResourcePrefix");
local __ResourcePrefix = "ex_";

local __IgnoredResourceNames = { 
    ['object_preview'] = true, 
    ['pattach'] = true,
    ['browsers'] = true,
    ['hmr'] = true,
    ['ajax'] = true,
    ['performancebrowser'] = true,
    ['resourcebrowser'] = true,
    ['resurcemanager'] = true,
    ['webadmin'] = true,
    ['webmap'] = true,
    ['devtools'] = true,
    ['runcode'] = true,
    ['hedit'] = true,
    ['bone_attach'] = true,
    ['custom_coronas'] = true
};

local rescallMT = {}
function rescallMT:__index(k)
    if type(k) ~= 'string' then k = tostring(k) end
        self[k] = function(resExportTable, ...)
        if type(self.res) == 'userdata' and getResourceRootElement(self.res) then
                return call(self.res, k, ...)
        else
                return nil
        end
    end
    return self[k]
end

local exportsMT = {}
function exportsMT:__index(k)
    if type(k) == 'userdata' and getResourceRootElement(k) then
        return setmetatable({ res = k }, rescallMT)
    elseif type(k) ~= 'string' then
        k = tostring(k)
    end

    local res = getResourceFromName(k)
    if res and getResourceRootElement(res) then
        return setmetatable({ res = res }, rescallMT)
    else
        -- outputDebugString('exports: Call to non-running server resource (' .. k .. ')', 1)
        return setmetatable({}, rescallMT)
    end
end
texports = setmetatable({}, exportsMT)

function AddExportReference(Props)
    assert(type(Props) == "table", "AddReference expected type 'table' at arg #1, got '" .. type(Props) .. "'");

    for Key, ResourceName in pairs(Props) do 
        local ResourceKey = __ResourcePrefix .. ResourceName:gsub(__ResourcePrefix, "");
        if (__IgnoredResourceNames[ResourceName]) then 
            ResourceKey = ResourceName;
        end 

        if (not __ReferencePool[ResourceKey]) then
            __ReferencePool[ResourceKey] = Key;
            _G[Key] = texports[ResourceKey];
        end 
    end 
end

addEventHandler(
    guiGetScreenSize and "onClientResourceStart" or "onResourceStart", 
    root, 
    function(Resource)
        local ResourceName = getResourceName(Resource);
        local ReferenceVar = __ReferencePool[ResourceName];
        if (not ReferenceVar) then return; end 

        _G[ReferenceVar] = exports[ResourceName];
    end
);

addEventHandler(
	guiGetScreenSize and "onClientResourceStop" or "onResourceStop", 
	root, 
	function(Resource)
		local ResourceName = getResourceName(Resource);
		local ReferenceVar = __ReferencePool[ResourceName];
		if (not ReferenceVar) then return; end 

		_G[ReferenceVar] = nil;
	end
);
end
