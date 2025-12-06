path = {}

local function mount_dir(dir, mountpoint)
    table.insert(path, { dir = dir, mountpoint = mountpoint } )
end

local function mount_contents(dir, mountpoint)
    LOG('checking ' .. dir)
    for _,entry in io.dir(dir .. '\\*') do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            mp = string.gsub(mp, '[.]scd$', '')
            mp = string.gsub(mp, '[.]zip$', '')
            mount_dir(dir .. '\\' .. entry, mountpoint .. '/' .. mp)
        end
    end
end

-- Load shadow directories
mods_dirs = {
	SHGetFolderPath('PERSONAL') .. '/My Games/Gas Powered Games/SupremeCommander/mods',
	SHGetFolderPath('LOCAL_APPDATA') .. '/Gas Powered Games/SupremeCommander/mods',
}
for _,mods_dir in mods_dirs do
	for _,mod_name in io.dir(mods_dir .. '/*') do
		if mod_name != '.' and mod_name != '..' then
			for _,f in io.dir(mods_dir.. '/' ..mod_name.. '/*') do
				if string.lower(f) == 'shadow' then
					LOG('Shadowing mod ', entry)
					mount_dir( mods_dir.. '/' ..mod_name.. '/shadow', '/' )
				end
			end
		end
	end
end

mount_contents(SHGetFolderPath('PERSONAL') .. '/My Games/Gas Powered Games/SupremeCommander/mods', '/mods')
mount_contents(SHGetFolderPath('PERSONAL') .. '/My Games/Gas Powered Games/SupremeCommander/maps', '/maps')
mount_contents(SHGetFolderPath('LOCAL_APPDATA') .. '/Gas Powered Games/SupremeCommander/mods', '/mods')
mount_contents(SHGetFolderPath('LOCAL_APPDATA') .. '/Gas Powered Games/SupremeCommander/maps', '/maps')
mount_dir(InitFileDir .. '/../gamedata/*.scd', '/')
mount_dir(InitFileDir .. '/..', '/')



hook = {
    '/schook'
}



protocols = {
    'http',
    'https',
    'mailto',
    'ventrilo',
    'teamspeak',
    'daap',
    'im',
}
