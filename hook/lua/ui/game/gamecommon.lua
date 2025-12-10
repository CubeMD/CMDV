do
   local MyUnitIdTable = {
    'tfr0000',
    'tfr0001',
    'tfr0002',
    'tfr0003',
    'tfr000w',
    'tfr00sh',
    'tfr00sv'
   }
   --unit icon must be in /icons/units/. Put the full path to the /icons/ folder in here - note no / on the end!
   local MyIconPath = "/mods/TerraFormerT1_fixedIcons"

   local oldFileNameFn = GetUnitIconFileNames
   
   local function IsMyUnit(bpid)
      for i, v in MyUnitIdTable do
         if v == bpid then
            return true
         end
      end
      return false
   end
   
   function GetUnitIconFileNames(blueprint)
      if IsMyUnit(blueprint.Display.IconName) then
         local iconName = MyIconPath .. "/icons/units/" .. blueprint.Display.IconName .. "_icon.dds"
         local upIconName = MyIconPath .. "/icons/units/" .. blueprint.Display.IconName .. "_icon.dds"
         local downIconName = MyIconPath .. "/icons/units/" .. blueprint.Display.IconName .. "_icon.dds"
         local overIconName = MyIconPath .. "/icons/units/" .. blueprint.Display.IconName .. "_icon.dds"
         
         if DiskGetFileInfo(iconName) == false then
            WARN('Blueprint icon for unit '.. blueprint.Display.IconName ..' could not be found, check your file path and icon names!')
            iconName = '/textures/ui/common/icons/units/default_icon.dds'
            upIconName = '/textures/ui/common/icons/units/default_icon.dds'
            downIconName = '/textures/ui/common/icons/units/default_icon.dds'
            overIconName = '/textures/ui/common/icons/units/default_icon.dds'
         end
         return iconName, upIconName, downIconName, overIconName
      else
         return oldFileNameFn(blueprint)
      end
   end
end