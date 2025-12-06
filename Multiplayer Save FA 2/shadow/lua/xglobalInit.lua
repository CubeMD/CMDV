-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the top-level lua initialization file. It is run at initialization time
-- to set up all lua state.

-- Uncomment this to turn on allocation tracking, so that memreport() in /lua/system/profile.lua
-- does something useful.
-- debug.trackallocations(true)

-- this function can be called anywhere to return a guess at the current state
-- UI states are splash, frontend and game
-- Sim states are blueprints and sim
function GetState()
	if rawget( _G, 'GetCurrentUIState' ) then
		return GetCurrentUIState()
	elseif rawget( _G, 'original_blueprints' ) then
		return 'blueprints'
	elseif rawget( _G, 'EndGame' ) then
		return 'sim'
	else
		return 'unknown'
	end
end

oldError = error
function error(msg)
	WARN('MODS: Caught error in '..GetState())
	
	-- Try to see if we're in the frontend
	local ok, problem = pcall(function()
		if GetState() == 'splash' or  GetState() ==  'frontend' or GetState() ==  'unknown' then
			-- disable all mods to prevent user being locked out of game
			local hasPrefs = rawget( _G, 'GetPreference' )
			if hasPrefs and not GetPreference("debug.enable_debug_facilities") then
				LOG('MODS: All mods disabled due to error.')
				SetPreference("active_mods", {})
			end
		end
	end)
	if not ok then
		WARN(problem)
	end
	
	-- report the error as normal
	oldError(msg)
end

-- Set up global diskwatch table (you can add callbacks to it to be notified of disk changes)
__diskwatch = {}

-- Set up custom Lua weirdness
doscript '/lua/system/config.lua'

-- Load system modules
doscript '/lua/system/import.lua'
doscript '/lua/system/utils.lua'
doscript '/lua/system/repr.lua'
doscript '/lua/system/class.lua'
doscript '/lua/system/trashbag.lua'
doscript '/lua/system/Localization.lua'
doscript '/lua/system/MultiEvent.lua'
doscript '/lua/system/collapse.lua'

--
-- Classes exported from the engine are in the 'moho' table. But they aren't full
-- classes yet, just lists of exported methods and base classes. Turn them into
-- real classes.
--
for name,cclass in moho do
    --SPEW('C->lua ',name)
    ConvertCClassToLuaClass(cclass)
end
