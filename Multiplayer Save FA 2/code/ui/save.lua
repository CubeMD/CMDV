--[[
Save process explained:

Saving is a complex process since it must invoke the Sim to collect its data but uses the UI to initiate and store it. Saving is started by one player (the 'initiator') chosing Save from the menu. The complete process is:

1.) Intercept save function to call MPSaveGame() instead of InternalSaveGame() in initiators UI.
2.) Register a callback in initiator UI to close the menu or report errors when Sim process completes.
3.) Invoke the Sim-side SimCallback 'SaveGame' to collect game data on ALL players machines.
4.) When data is gathered the Sim populates Sync.SaveGameData on ALL machines.
5.) All machines call SaveSimData in UI to put data into players Prefs file.
6.) All machines run any save callbacks. Usually only the initiator will have one (to cleanup save window).

In short the UI starts the process, tells the Sim to save, watches for the result and then crams the result into the users prefs file (the only place mods can store data) and finally cleans up the open save dialog.

]]

local Prefs = import('/lua/user/prefs.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local globalUtils = import('/mods/Multiplayer Save FA 2/code/globals.lua')

-- Version of virtual file spec
local version = 1

-- Callbacks that will run in UI when a save occurs.
save_start_callbacks = {}
save_done_callbacks = {}

-- Callbacks that will run in UI when a load occurs.
load_start_callbacks = {}
load_done_callbacks = {}

-- this function gets called when the Sim returns the game data
function OnSimDataSaved( save_data )

	LOG('SAVE: Sim has returned save data to UI')
	local save_ok = false -- status (true if saved ok)
	local save_msg = '' -- error to report if save failed
	-- add virtual file meta data
	save_data.Profile = Prefs.GetCurrentProfile().Name
	save_data.Version=version -- virtual file version
	
	save_data.Info = {
		IsFolder=false,
		ReadOnly=false,
		SizeBytes=string.len(save_data.Data),
		TimeStamp='',
		WriteTime=GetSystemDate()
	}

	LOG("MultiplayerSave DEBUG: SYSTEM TIME:")
	LOG(safecall( 'GetSystemTime', GetSystemTime))
	LOG(safecall( 'GetSystemTimeSeconds', GetSystemTimeSeconds))
	LOG(safecall( 'GetGameTimeSeconds', GetGameTimeSeconds))
	-- LOG(safecall( 'GetSystemTimeSecondsOnlyForProfileUse', GetSystemTimeSecondsOnlyForProfileUse))

	-- save file data
	SetPreference('files.'..save_data.Type..'.'..save_data.Name, save_data)
	SavePreferences()
	-- we're done
	save_ok = true
	-- Run extra callbacks (for feedback or additional actions)
	LOG('SAVE: Running save done callbacks.')
	for name, callback in save_done_callbacks do
		callback( save_ok, save_msg )
	end
	-- Remove cleanup function
	save_done_callbacks['cleanup_dialog'] = nil
	LOG('SAVE: save done')
	LOG('----------------------------------------------------------------------------------------------')
	-- Show message
--~ 	local parent = UIUtil.CreateScreenGroup(GetFrame(0), "Message")
--~         UIUtil.QuickDialog(
--~ 		parent, 
--~ 		"Game Saved", 
--~                 "<LOC _Ok>", nil,
--~                 nil, nil, 
--~                 true, {worldCover = false, enterButton = 1, escapeButton = 2})
end

-- this function gets called when the Sim returns the game data
function OnSimDataLoaded( save_data )
	LOG('LOAD: Running UI load callback')
end
		
-- this function gets called when somebody saves a MP game. It starts the Sim side process.
function MPSaveGame( filespec, basename, callback )
	LOG('SAVE: Saving virtual save file '..filespec..' as '..basename)
	local filetype = globalUtils.findlast(filespec, '%.([^.]-)$')
	LOG('SAVE step2')
	
	-- this data gets sent to the Sim on every players' machine
	local querydata = {
		Type = filetype,
		Name = basename, -- user specified name
		Spec = filespec, -- system generated path
		Data = {}, -- the game data will go in here
	}
	-- run any start callbacks
	for name, callback in save_start_callbacks do
		callback( querydata )
	end	
	-- send query to sim and run callback when a result is available
	LOG('SAVE: QUERY->SIM: '..repr(querydata))
	SimCallback( {Func='SaveGame', Args=querydata} )
	
	-- Add callback so the save window gets cleaned up when the Sim is done saving
	save_done_callbacks['cleanup_dialog'] = callback
	
	return true
end

-- this function gets called when somebody loads a MP game. 
function MPLoadSavedGame( filespec )
	LOG('LOAD: Loading virtual save file '..filespec)
	-- get virtual file from prefs
	local filename = globalUtils.findlast(filespec, '/([^/.]-)%.')
	local filetype = globalUtils.findlast(filespec, '%.([^.]-)$')
	LOG('Loading: '..'files.'..filetype..'.'..filename)
	local filedata = GetPreference('files.'..filetype..'.'..filename, false)
	-- run any start callbacks
	for name, callback in load_start_callbacks do
		callback( filedata )
	end	
	-- send query to sim and run callback when a result is available
	--LOG('LOAD: QUERY->SIM: '..repr(filedata))
	
	LOG("---- Running Sim callback")


	-- This is a work around to get around the limitation of the arg size which can be transferred to LoadGame()
	
	local chunkSize = 20000 
	for i = 1, string.len(filedata.Data), chunkSize do
		LOG("Sending single chunk of data")
		local chunk = string.sub(filedata.Data, i, i + chunkSize - 1)
		SimCallback( {Func='LoadGame_SendDataChunks', Args = chunk })
	end

	filedata.Data = ""
	LOG("Calling main sim")
	SimCallback( {Func='LoadGame', Args=filedata} )

	LOG("---- Ran Sim callback")

	-- this is tricky. The UI wants to know if the load succeeded but we won't really know
	-- for sure until the sim callback runs. We just do what we can.
	-- errcodes are in GPG /lua/ui/dialogs/saveload.lua
	if filedata then
		worked = true
		errcode = false
		detail = false
	else
		worked = false
		errcode = 'CantOpen'
		detail = "Save data not found in prefs file"
	end
	return worked, error, detail
end

function MPGetSpecialFiles( filetype )
	LOG('SAVELOAD: Loading '..filetype..' virtual files from prefs')
	--filetype = 'SCFAVirtualSave'
	local saves = GetPreference('files.'..filetype) or {}
	local save_files = {}
	-- Create a virtual directory listing from save data in prefs
	for save_name, save_info in saves do
		local profile = save_info.Profile
		if profile then
			save_files[profile] = save_files[profile] or {}
			table.insert( save_files[profile],  save_info.Name )
		else
			LOG('SAVELOAD: No profile key in save '..save_name)
		end
	end
	local virtual_dir = {
		directory = 'prefs/',
		extension = filetype,
		files = save_files,
	}
	--LOG( repr(virtual_dir) )
	return virtual_dir
end

function MPGetSpecialFileInfo( profile, filename, filetype )
	local virtual_file = GetPreference('files.'..filetype..'.'..filename)
	return virtual_file.Info
end

function MPRemoveSpecialFile( profile, filename, filetype )
	LOG('SAVELOAD: Removing virtual save file '..filename..' from profile '..profile..' type: '..filetype)
	local files = GetPreference('files.'..filetype)
	files[filename] = nil
	SetPreference('files.'..filetype, files)
	SavePreferences()
	return true
end

--[[	
	{
INFO:   IsFolder=false,
INFO:   ReadOnly=false,
INFO:   SizeBytes=134580720,
INFO:   TimeStamp="01c8a74d7946cc64",
INFO:   WriteTime={
INFO:     hour=13,
INFO:     mday=26,
INFO:     minute=27,
INFO:     month=4,
INFO:     second=36,
INFO:     wday=6,
INFO:     year=2008
INFO:   }
]]