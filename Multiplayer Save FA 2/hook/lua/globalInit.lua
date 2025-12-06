
-- if FA then
ms_name = 'Multiplayer Save FA 2'
-- else
-- 	ms_name = 'Multiplayer Save SC'
-- end

LOG('LOAD: MultiplayerSave DEBUG: - globinit')
-- Store path
ms_path = '/mods/'..ms_name

-- Load mod_info file for other details
ms_info = import(ms_path..'/mod_info.lua')

-- Functions to load mod scripts
function msscript( path )
	return doscript(ms_path..'/'..path)
end


function msimport( path )
	return import(ms_path..'/'..path)
end

msscript('code/globals.lua')