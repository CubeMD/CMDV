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
   
   local function IsMyUnit(bpid)
      for i, v in MyUnitIdTable do
         if v == bpid then
            return true
         end
      end
      return false
   end
   
   local oldUpdateWindow = UpdateWindow
   function UpdateWindow(info)
      oldUpdateWindow(info)
      if IsMyUnit(info.blueprintId) and DiskGetFileInfo(MyIconPath .. '/icons/units/' .. info.blueprintId.. '_icon.dds') then
         controls.icon:SetTexture(MyIconPath .. '/icons/units/' .. info.blueprintId .. '_icon.dds')
      end
   end
end