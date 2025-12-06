-- SAVE: Watch for save data returned from the Sim side after a SaveGame callback
local baseOnSync = OnSync
OnSync = function()
	baseOnSync()

	-- The sim populates this on a MP save because only the UI can save data.
	if Sync.SaveGameData then
		msimport('code/ui/save.lua').OnSimDataSaved( Sync.SaveGameData )
	end
	
	-- This object tells the UI the results of a load. Used for user feedback.
	if Sync.LoadGameData then
		msimport('code/ui/save.lua').OnSimDataLoaded( Sync.LoadGameData )
	end
end