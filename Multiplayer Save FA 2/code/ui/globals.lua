-- Multiplayer Save: Override filepicker and behaviours when we save/load multiplayer games
-- We need to do this because GPG won't let mods save data anywhere but the prefs file.

local Prefs = import('/lua/user/prefs.lua')
--local UserQuery = import('/lua/UserPlayerQuery.lua')

-- SAVE: saves a virtual save file
local SPInternalSaveGame = InternalSaveGame
function InternalSaveGame( filespec, basename, callback )
	if SessionIsActive() and SessionIsMultiplayer() then
		return msimport('code/ui/save.lua').MPSaveGame( filespec, basename, callback )
	else
		return SPInternalSaveGame( filespec, basename, callback )
	end
end

-- loads a virtual save file
local SPLoadSavedGame = LoadSavedGame
function LoadSavedGame( filespec )
	if SessionIsActive() and SessionIsMultiplayer() then
		return msimport('code/ui/save.lua').MPLoadSavedGame( filespec )
	else
		return SPLoadSavedGame( filespec )
	end
end

-- removes a virtual save file
local SPRemoveSpecialFile = RemoveSpecialFile
function RemoveSpecialFile( profile, basename, filetype )
	if SessionIsActive() and SessionIsMultiplayer() then
		return msimport('code/ui/save.lua').MPRemoveSpecialFile( profile, basename, filetype )
	else
		return SPRemoveSpecialFile( profile, basename, filetype )
	end
end

-- lists virtual save files
local SPGetSpecialFiles = GetSpecialFiles
function GetSpecialFiles( filetype )
	if SessionIsActive() and SessionIsMultiplayer() then
		return msimport('code/ui/save.lua').MPGetSpecialFiles( filetype )
	else
		return SPGetSpecialFiles( filetype )
	end
end

-- get info about a virtual save file
local SPGetSpecialFileInfo = GetSpecialFileInfo
function GetSpecialFileInfo( profile, filename, filetype )
	if SessionIsActive() and SessionIsMultiplayer() then
		return msimport('code/ui/save.lua').MPGetSpecialFileInfo( profile, filename, filetype )
	else
		return SPGetSpecialFileInfo( profile, filename, filetype )
	end
end
