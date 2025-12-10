#****************************************************************************
#**
#**  File     :  /cdimage/units/URB5101/URB5101_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Cybran Wall Piece Script
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CWallStructureUnit = import('/lua/cybranunits.lua').CWallStructureUnit
local TerraFormerT1 = import ('/Mods/TerraFormerT1_fixedIcons/hook/TerraFormer.lua').TerraFormerT1

TFR0003 = Class(CWallStructureUnit) {

  OnStopBeingBuilt = function(self)
    local x,y,z = unpack(self:GetPosition())


    TerraFormerT1.FlattenTerrain(x+2,z+2,6, self);
    TerraFormerT1.FlattenTerrain(x-1,z-1,6, self);
    TerraFormerT1.FlattenTerrain(x-1,z+2,6, self);
    TerraFormerT1.FlattenTerrain(x+2,z-1,6, self);
    self:Destroy()
    self:RequestRefreshUI();
  end
}


TypeClass = TFR0003