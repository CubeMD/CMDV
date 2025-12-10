local version = tonumber( (string.gsub(string.gsub(GetVersion(), '1.5.', ''), '1.6.', '')) )

if version < 3652 then -- All versions below 3652 don't have buildin global icon support, so we need to insert the icons by our own function
    LOG('TerraFormerT1_fixedIcons: [uiutil.lua '..debug.getinfo(1).currentline..'] - Gameversion is older then 3652. Hooking "UIFile" to add our own unit icons')

local MyUnitIdTable = {
   tfr0000=true,
   tfr0001=true,
   tfr0002=true,
   tfr0003=true,
   tfr000w=true,
   tfr00sh=true,
   tfr00sv=true,
}

    local IconPath = "/Mods/TerraFormerT1_fixedIcons"
    -- Adds icons to the engeneer/factory buildmenu
    local oldUIFile = UIFile
    function UIFile(filespec)
        local IconName = string.gsub(filespec,'_icon.dds','')
        IconName = string.gsub(IconName,'/icons/units/','')
        if MyUnitIdTable[IconName] then
            local curfile =  IconPath .. filespec
            return curfile
        end
        return oldUIFile(filespec)
    end

else
    LOG('TerraFormerT1_fixedIcons: [uiutil.lua '..debug.getinfo(1).currentline..'] - Gameversion is 3652 or newer. No need to insert the unit icons by our own function.')
end
