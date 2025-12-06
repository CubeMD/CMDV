
-----------------------------------------------------------------------------------------------
-- The above is from dkjson
-- Below is original globals.lua




----------------
-- Most of the table code in this file comes from Supreme Commander, Copyright Gas Powered Games.
-- We use it here under 'fair use' since it is a tiny amount of the total code and most of it can be found elsewhere on the web.


--==============================================================================
-- GENERAL
--==============================================================================


local encode = import('/mods/Multiplayer Save FA 2/code/tyler2.lua').stringify
local decode = import('/mods/Multiplayer Save FA 2/code/tyler2.lua').parse


yes = true
no = false
on = true
off = false




-----------------------------------------------------------------------------------------------
-- safecall(msg, fn, ...) calls the given function with the given
-- args, and catches any error and logs a warning including the given msg.
-- Returns nil if the function failed, otherwise returns the function's result.
-----------------------------------------------------------------------------------------------
function safecall(msg, fn, ...)
    local ok, result = pcall(fn, unpack(arg))
    if ok then
        return result
    else
        WARN("Problem " .. tostring(msg) .. ":\n" .. result)
        return
    end
end

-----------------------------------------------------------------------------------------------
-- evaluate a Lua statement stored as a string and return its value
-----------------------------------------------------------------------------------------------
function dostring( str )
	LOG("MultiplayerSave DEBUG: dostring evaluating: " .. tostring(str))
	return assert(loadstring('return ' .. str))()
end

--==============================================================================
-- MATH
--==============================================================================
-----------------------------------------------------------------------------------------------
-- Round num to specified decimal places. From lua-users wiki. Author unknown.
-----------------------------------------------------------------------------------------------
function math.round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end
    
--==============================================================================
-- MODULES
--==============================================================================
-----------------------------------------------------------------------------------------------
-- load: A wrapper for the standard import routines to aid in troubleshooting
-----------------------------------------------------------------------------------------------
--~ function safe_load( module, env )
--~ 	full_path = '/mods/advanced_' .. path
--~ 	ok, result = pcall(doscript, full_path, _G)
--~ 	if not ok then
--~ 		WARN('Utils:: Failed to load' .. path)
--~ 	end
--~ end

--==============================================================================
-- VECTORS
--==============================================================================

-- returns vector as 2D point string, rounded for display purposes
function vec2str( vector )
	return math.floor(vector[1])..':'..math.floor(vector[3])
end


--==============================================================================
-- TABLE
--==============================================================================


-----------------------------------------------------------------------------------------------
-- table.copy(t) returns a shallow copy of t.
-----------------------------------------------------------------------------------------------
function table.copy(t)
    local r = {}
    for k,v in t do
        r[k] = v
    end
    return r
end


-- This functionality is now provided in the base table class
-----------------------------------------------------------------------------------------------
-- table.find(t,val) returns the key for val if it is in t.
-- Otherwise, return nil
-----------------------------------------------------------------------------------------------
-- function table.find(t,val)
-- 	LOG("attempting to find: " .. val)
--     for k,v in t do
--         if v == val then
--             return k
--         end
--     end
--     -- return nil by falling off the end
-- end

-----------------------------------------------------------------------------------------------
-- table.findnocase(t,val) returns the key for val if it is in t (case insensitive).
-- Otherwise, return nil
-----------------------------------------------------------------------------------------------
function table.findnocase(t,val)
    for k,v in t do
        if string.lower(v) == string.lower(val) then
            return k
        end
    end
    -- return nil by falling off the end
end

-----------------------------------------------------------------------------------------------
-- table.subset(t1,t2) returns true iff every key/value pair in t1 is also in t2
-----------------------------------------------------------------------------------------------
function table.subset(t1,t2)
    for k,v in t1 do
        if t2[k] ~= v then return false end
    end
    return true
end

-----------------------------------------------------------------------------------------------
-- table.equal(t1,t2) returns true iff t1 and t2 contain the same key/value pairs.
-----------------------------------------------------------------------------------------------
function table.equal(t1,t2)
    return table.subset(t1,t2) and table.subset(t2,t1)
end

-----------------------------------------------------------------------------------------------
-- table.removeByValue(t,val) remove a field by value instead of by index
-----------------------------------------------------------------------------------------------
function table.removeByValue(t,val)
    for k,v in t do
        if v == val then
            table.remove(t,k)
            return
        end
    end
end

-----------------------------------------------------------------------------------------------
-- table.deepcopy(t) returns a copy of t with all sub-tables also copied.
-----------------------------------------------------------------------------------------------
function table.deepcopy(t,backrefs)
    if type(t)=='table' then
        if backrefs==nil then backrefs = {} end

        local b = backrefs[t]
        if b then
            return b
        end

        local r = {}
        backrefs[t] = r
        for k,v in t do
            r[k] = table.deepcopy(v,backrefs)
        end
        return r
    else
        return t
    end
end


-----------------------------------------------------------------------------------------------
-- table.merged(t1,t2) returns a table in which fields from t2 overwrite
-- fields from t1. Neither t1 nor t2 is modified. The returned table may
-- share structure with either t1 or t2, so it is not safe to modify.
--
-- For example:
--       t1 = { x=1, y=2, sub1={z=3}, sub2={w=4} }
--       t2 = { y=5, sub1={a=6}, sub2="Fred" }
--
--       merged(t1,t2) ->
--           { x=1, y=5, sub1={a=6,z=3}, sub2="Fred" }
--
--       merged(t2, t1) ->
--           { x=1, y=2, sub1={a=6,z=3}, sub2={w=4} }
-----------------------------------------------------------------------------------------------
function table.merged(t1, t2)

    if t1==t2 then
        return t1
    end

    if type(t1)~='table' or type(t2)~='table' then
        return t2
    end

    local copied = nil
    for k,v in t2 do
        if type(v)=='table' then
            v = table.merged(t1[k], v)
        end
        if t1[k] ~= v then
            copied = copied or table.copy(t1)
            t1 = copied
            t1[k] = v
        end
    end

    return t1
end

-----------------------------------------------------------------------------------------------
-- table.sorted(t, [comp]) is the same as table.sort(t, comp) except it returns
-- a sorted copy of t, leaving the original unchanged.
--
-- [comp] is an optional comparison function, defaulting to less-than.
-----------------------------------------------------------------------------------------------
function table.sorted(t, comp)
    local r = table.copy(t)
    table.sort(r, comp)
    return r
end


-----------------------------------------------------------------------------------------------
-- sort_by(field) provides a handy comparison function for sorting
-- a list of tables by some field.
--
-- For example,
--       my_list={ {name="Fred", ...}, {name="Wilma", ...}, {name="Betty", ...} ... }
--
--       table.sort(my_list, sort_by 'name')
--           to get names in increasing order
--
--       table.sort(my_list, sort_down_by 'name')
--           to get names in decreasing order
-----------------------------------------------------------------------------------------------
function sort_by(field)
    return function(t1,t2)
        return t1[field] < t2[field]
    end
end

function sort_down_by(field)
    return function(t1,t2)
        return t2[field] < t1[field]
    end
end


-----------------------------------------------------------------------------------------------
-- table.sort_values( t, reverse ) -- sort table inplace by value rather than key.
-----------------------------------------------------------------------------------------------

function table.sort_values( t, reverse )

	local function vsort(a, b) return t[a] > t[b] end
	local function rvsort(a, b) return t[a] < t[b] end -- reverse

	if reverse then
		table.sort( t, rvsort )
	else
		table.sort( t, vsort )
	end
end

-----------------------------------------------------------------------------------------------
-- table.keys(t, [comp]) -- Return a list of the keys of t, sorted.
--
-- [comp] is an optional comparison function, defaulting to less-than.
-----------------------------------------------------------------------------------------------
function table.keys(t, comp)
    local r = {}
    for k,v in t do
        table.insert(r,k)
    end
    table.sort(r, comp)
    return r
end


-----------------------------------------------------------------------------------------------
-- table.values(t) -- Return a list of the values of t, in unspecified order.
-----------------------------------------------------------------------------------------------
function table.values(t)
    local r = {}
    for k,v in t do
        table.insert(r,v)
    end
    return r
end


-----------------------------------------------------------------------------------------------
-- sortedpairs(t, [comp]) -- Iterate over a table in key-sorted order:
--   for k,v in sortedpairs(t) do
--       print(k,v)
--   end
--
-- [comp] is an optional comparison function, defaulting to less-than.
-----------------------------------------------------------------------------------------------
function sortedpairs(t, comp)
    local keys = table.keys(t, comp)
    local i=1
    return function()
        local k = keys[i]
        if k~=nil then
            i=i+1
            return k,t[k]
        end
    end
end


-----------------------------------------------------------------------------------------------
-- table.getsize(t) returns actual size of a table, including string keys
-----------------------------------------------------------------------------------------------
function table.getsize(t)
    if type(t) ~= 'table' then return end
    local size = 0
    for k, v in t do
        size = size + 1
    end
    return size
end



-----------------------------------------------------------------------------------------------
-- table.inverse(t) returns a table with keys and values from t reversed.
--
-- e.g. table.inverse {'one','two','three'} => {one=1, two=2, three=3}
--      table.inverse {foo=17, bar=100}     => {[17]=foo, [100]=bar}
--
-- If t contains duplicate values, it is unspecified which one will be returned.
--
-- e.g. table.inverse {foo='x', bar='x'} => possibly {x='bar'} or {x='foo'}
-----------------------------------------------------------------------------------------------
function table.inverse(t)
    r = {}
    for k,v in t do
        r[v] = k
    end
    return r
end


-----------------------------------------------------------------------------------------------
-- table.map(fn,t) returns a table with the same keys as t but with
-- fn applied to each value.
-----------------------------------------------------------------------------------------------
function table.map(fn, t)
    r = {}
    for k,v in t do
        r[k] = fn(v)
    end
    return r
end



-----------------------------------------------------------------------------------------------
-- table.empty(t) returns true iff t has no keys/values.
-----------------------------------------------------------------------------------------------
function table.empty(t)
    if type(t) ~= "table" then
        return true
    end
    for k,v in pairs(t) do
        return false
    end
    return true
end

-----------------------------------------------------------------------------------------------
-- table.join(t1,t2) returns a new table with all values in t2 appended to t1. 
-- Only values are copied, so it is only useful for arrays
-- The order of values will be maintained and sparse arrays will collapse.
-- The new table is a shallow copy so should be modified with care if it contains refs
-----------------------------------------------------------------------------------------------
function table.join(t1,t2)
    local t = {}
    for k,v in t1 do table.insert(t,v) end
    for k,v in t2 do table.insert(t,v) end
    return t
end

--==============================================================================
-- STRING
--==============================================================================

-----------------------------------------------------------------------------------------------
-- string.lines(str) Simply splits a DOS/Unix string into lines 
-----------------------------------------------------------------------------------------------
function splitlines(str)
	--local t = {}
	--local function helper(line) table.insert(t, line) return "" end
	--helper((str:gsub("(.-)\r?\n", helper)))
	return string.gfind(str,'[^\n\r]+')
end

-----------------------------------------------------------------------------------------------
-- string.words(str) Extracts 'words' (anything with alphanumics or understores)
-----------------------------------------------------------------------------------------------
function words(str)
	return string.gfind(str,'[%w_]+')
end


-----------------------------------------------------------------------------------------------
-- string.words(str) Trim whitespace off left and right
-----------------------------------------------------------------------------------------------
function trim(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

-----------------------------------------------------------------------------------------------
-- string.findall(str,pattern) Return table with all matches of pattern in string
-----------------------------------------------------------------------------------------------
function findall(str,pattern)
	local t = {}
	for match in string.gfind(str,pattern) do
		table.insert(t,match)
	end
	return t
end

-----------------------------------------------------------------------------------------------
-- string.findone(str,pattern) Return first match of pattern in string
-----------------------------------------------------------------------------------------------
function findone(str,pattern)
	local s = ''
	for match in string.gfind(str,pattern) do
		return match
	end
	return s
end

-----------------------------------------------------------------------------------------------
-- string.findlast(str,pattern) Return last match of pattern in string
-----------------------------------------------------------------------------------------------
function findlast(str,pattern)
	local s = ''
	for match in string.gfind(str,pattern) do
		s = match
	end
	return s
end

--==============================================================================
-- GENERAL
--==============================================================================

-----------------------------------------------------------------------------------------------
-- doifexists(path) wrapper for dofile that skips missing files or errors
-- status, result = doifexists(path)
-- returns two values:
-- status: true if the file executed without errors, false otherwise
-- result: result of the module load (ie, the module) or an error
-----------------------------------------------------------------------------------------------
function doifexists(path)
	local ok, result = pcall(function() result = dofile(path) end)
	return ok, result
end


-----------------------------------------------------------------------------------------------
-- dump(value,name,indent,max_indent) Returns a nested printout of a table or value
-----------------------------------------------------------------------------------------------
function dump(value,name,indent,max_indent)
	
	local out_str = ''
	-- indent
	local indent_str = ''
	if indent == nil then 
		indent = 0
	else
		indent_str = string.rep('  ',indent)
		out_str = indent_str
	end
	
	-- Don't print numeric keys
	hasKey = type(name) ~= 'number'
	
	if type(value)=='table' then
	
		if name ~= nil and hasKey then
			out_str = out_str .. tostring(name) .. ' = {'
		else
			out_str = out_str .. '{'
		end
		-- Limit recursion
		if max_indent == nil then max_indent = 6 end		
		if max_indent and indent >= max_indent then
			-- Recursion limit reached
			out_str = out_str .. '[RECURSION LIMIT]'
		else
			-- Recursion is allowed
			for k,v in pairs(value) do
				out_str = out_str .. '\n' .. dump(v,k,indent+1,max_indent) .. ','
			end
		end
		out_str = out_str .. '\n' .. indent_str .. '}'
        elseif type(value)=='string' then
		if name ~= nil and hasKey then out_str = out_str .. tostring(name).. ' = ' end
		out_str = out_str .. '"' .. value .. '"'
	elseif type(value)=='number' then
		if name ~= nil and hasKey then out_str = out_str .. tostring(name) .. ' = ' end
		out_str = out_str .. tostring(value)
	else
		if name ~= nil and hasKey then out_str = out_str .. tostring(name) .. ' = ' end
		out_str = out_str .. tostring(value)
        end
	return out_str
end

-- bigdump works like dump but splits the job up into smaller writes to save memory
-- bigdump never returns a value, it goes stright to LOG
function bigdump(value,name,indent,max_indent)
	
	local out_str = ''
	-- indent
	local indent_str = ''
	if indent == nil then 
		indent = 0
	else
		indent_str = string.rep('  ',indent)
		out_str = indent_str
	end
	
	-- Don't print numeric keys
	hasKey = type(name) ~= 'number'
	
	if type(value)=='table' then
	
		if name ~= nil and hasKey then
			out_str = out_str .. tostring(name) .. ' = {'
		else
			out_str = out_str .. '{'
		end
		LOG(out_str)
		-- Limit recursion
		if max_indent == nil then max_indent = 6 end		
		if max_indent and indent >= max_indent then
			-- Recursion limit reached
			LOG('[RECURSION LIMIT]')
		else
			-- Recursion is allowed
			for k,v in pairs(value) do
				bigdump(v,k,indent+1,max_indent)
			end
		end
		LOG('\n' .. indent_str .. '}')
		
        elseif type(value)=='string' then
		if name ~= nil and hasKey then out_str = out_str .. tostring(name).. ' = ' end
		LOG(out_str .. '"' .. value .. '"')
	elseif type(value)=='number' then
		if name ~= nil and hasKey then out_str = out_str .. tostring(name) .. ' = ' end
		LOG(out_str .. tostring(value))
	else
		if name ~= nil and hasKey then out_str = out_str .. tostring(name) .. ' = ' end
		LOG(out_str .. tostring(value))
        end
end

function bigdumptest(value,name,indent,max_indent)
	bigdump(value,name,indent,max_indent)
	LOG('MultiplayerSave DEBUG: DONE bigdump')
end

-- Get the keys in any obj
function getkeys( obj )
	return table.keys(getmetatable(obj))
end

-- Log the keys of any object
function dumpkeys( obj )
	LOG(repr(table.keys(getmetatable(obj))))
end

-- Trace function calls (limited to src file)
-- based on code by 'eriatarka' from TA Spring forums
function CreateStackTraceHook(src_limit)
	return function(event)
		local info = debug.getinfo(2, "S")
		--if (info.what == "C") then return end            -- do not log C functions
	     
		if (event == "call") then
			local info2 = debug.getinfo(2, "n")
			local src = info.short_src
			local name = info2.name or ""
			local line = info.linedefined
			if type(src_limit) == 'table' then
				for _src in src_limit do
					if src_limit == nil or string.find(src, _src) then
						LOG(src .. "(" .. line .. "): " .. name)
					end
				end
			elseif src_limit == nil or string.find(src, src_limit) then
				LOG(src .. "(" .. line .. "): " .. name)
			end
		end
	end
end
-- USAGE
--debug.sethook(CreateStackTraceHook(), "cr")            -- hook call and return events

--==============================================================================
-- SERIALISE
-- A set of functions for converting data into compact strings
--==============================================================================

-- Round numbers to n decimal places.
function Round(num,places)
	local num_str = string.format('%.'..places..'f', num)
	return string.gsub(num_str,'%.*0+$','') -- remove trailing 0's
end

-- Round each number in a table to n places.
function RoundTable(t,places)
	local function localRound(num)
		Round(num,places)
	end
	return table.map(localRound,t)
end

-- Converts value to a compact string.
function SerialiseValue(value,name)
	
	-- Add key name
	local out_str = ''
	if name ~= nil then
		if type(name) == 'number' then
			out_str = out_str .. "[" .. tostring(name) .. "]="
		else
			out_str = out_str .. "['" .. tostring(name) .. "']=" 
		end
	end
	-- Add value
	if type(value)=='table' then
		out_str = out_str .. '{'
		local i = 1
		for k,v in pairs(value) do
			--LOG(i..'<-->'..k)
 			if k == i then
 				-- don't label as items appear to be sequential
				name = nil
			else
				name = k
			end
			out_str = out_str .. SerialiseValue(v,name) .. ','
			i = i + 1
		end
		out_str = out_str .. '}'
	elseif type(value)=='number' then
		-- round numbers to six decimal places
		out_str = out_str .. Round(value,6)
	else
		out_str = out_str .. "'"..tostring(value).."'"
        end
	return out_str
end

-- Serialises table to a compact string so it requires less characters to store/transmit.
function table.serialise(t)
	local compressed_str = encode(t)
	return compressed_str
end

-- Converts a serialised table back into a real Lua table
function table.deserialise( str )
	LOG('MultiplayerSave DEBUG: calling lume to deserialize')
	return decode(str)
	-- ORIGINAL CODE DOESNT WORK IN SANDBOX MODE: 
  -- return dostring( str )
end


--==============================================================================
-- DATE / TIME
-- A set of functions dealing with dates and times
--==============================================================================

-- System date/time function
-- GPG left out a decent date function. There isn't even a usable timestamp. This hack is the best I can do.
-- It works by writing to the prefs file and reading back its modification date.
function GetSystemDate()
	prefs_file = GetPreference('Paths.Prefs', false)
	if not prefs_file then
		-- try to find prefs file and read its timestamp.
		-- look under here for prefs. this can't go higher than the root directory 
		-- of the drive where FA is installed. If the prefs is on another drive or
		-- another path (ie, non-english system) then we're screwed.
		local search_path = '/../../../../../../../../../../documents and settings'
		if DiskGetFileInfo(search_path).IsFolder then
			-- search 'Documents and Settings' for game.prefs
			for _,file in DiskFindFiles(search_path,'game.prefs') do
				if string.find(file, 'forged alliance') then
					LOG('found FA prefs file at '..file)
					prefs_file = file
					break
				end
			end
		end
	end
	if prefs_file then
		-- we know where the prefs file is so we can update it and read back the time 
		SetPreference('Paths.Prefs',prefs_file)
		SavePreferences()
		return DiskGetFileInfo(prefs_file).WriteTime
	else
		-- no luck, return a fake date
		return {
			hour = 0,
			mday = 1,
			minute = 0,
			month = 1,
			second = 0,
			wday = 1,
			year = 2000,
		}
	end
end
