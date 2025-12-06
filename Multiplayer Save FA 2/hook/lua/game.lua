--****************************************************************************
--**
--**  File     :  /lua/game.lua
--**  Author(s): John Comes
--**
--**  Summary  : Script full of overall game functions
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

VeteranDefault = {
    Level1 = 25,
    Level2 = 100,
    Level3 = 250,
    Level4 = 500,
    Level5 = 1000,
}

-- Return the total time (in seconds), energy, and mass it will take for the given
-- builder to create a unit of type target_bp.
--
-- targetData may also be an "Enhancement" section of a unit's blueprint rather than
-- a full blueprint.
function GetConstructEconomyModel(builder, targetData)

	if EntityCategoryContains(categories.NUKE, builder) then
	   LOG('GetConstructEconomyModel')
	end
    local builder_bp = builder:GetBlueprint()
    
    -- 'rate' here is how fast we build relative to a unit with build rate of 1
    local rate = builder:GetBuildRate()

    local time = targetData.BuildTime
    local mass = targetData.BuildCostMass
    local energy = targetData.BuildCostEnergy

    -- apply penalties/bonuses to effective time
    local time_mod = builder.BuildTimeModifier or 0
    time = time * (100 + time_mod)*.01
    if time<.1 then time = .1 end

    -- apply penalties/bonuses to effective energy cost
    local energy_mod = builder.EnergyModifier or 0
    energy = energy * (100 + energy_mod)*.01
    if energy<0 then energy = 0 end

    -- apply penalties/bonuses to effective mass cost
    local mass_mod = builder.MassModifier or 0
    mass = mass * (100 + mass_mod)*.01
    if mass<0 then mass = 0 end

    if builder.saveProgress then
	LOG(time, rate, time/rate, energy, mass)
	return 100, 0, 0
    else
        return time/rate, energy, mass
    end
end
