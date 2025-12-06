function SetUnitLOD(obj)
    if obj.Wreckage then
        SetUnitLOD(obj.Wreckage)
    end

    if obj.Display and obj.Display.Mesh and obj.Display.Mesh.LODs then
        local n = table.getn(obj.Display.Mesh.LODs)
        for k = 1, n do
            obj.Display.Mesh.LODs[k].LODCutoff = 333 * k
        end
        obj.Display.Mesh.LODs[n].LODCutoff = 10000
    end

    if obj.Mesh and obj.Mesh.LODs then
        local n = table.getn(obj.Mesh.LODs)
        for k = 1, n do
            obj.Mesh.LODs[k].LODCutoff = 333 * k
        end
        obj.Mesh.LODs[n].LODCutoff = 10000
    end

    if obj.LODs then
        local n = table.getn(obj.LODs)
        for k = 1, n do
            obj.LODs[k].LODCutoff = 333 * k
        end
        obj.LODs[n].LODCutoff = 10000
    end

    if obj.IconFadeInZoom then
        obj.IconFadeInZoom = obj.IconFadeInZoom + 66
    end

    obj.LODCutoff = 10000
end

function SplitString(inputString, delimiter)
    local result = {}
    local currentPart = ""

    -- Iterate over each character in the string
    for i = 1, string.len(inputString) do
        local char = inputString[i]
        if char == nil then
            continue
        end

        if char == delimiter then
            table.insert(result, currentPart)
            currentPart = ""
        else
            currentPart = currentPart .. char
        end
    end
    -- Add the last part
    table.insert(result, currentPart)
    return result
end

function TrimSpaces(input)
    local startIdx = 1
    local endIdx = string.len(input)

    -- Find the first non-space character
    while startIdx <= string.len(input) and input[startIdx] == " " do
        startIdx = startIdx + 1
    end

    -- Find the last non-space character
    while endIdx > 0 and input[endIdx] == " " do
        endIdx = endIdx - 1
    end

    -- Build the result manually
    local trimmedResult = ""
    for i = startIdx, endIdx do
        trimmedResult = trimmedResult .. input[i]
    end

    return trimmedResult
end

function CleanCombination(combination)
    local parts = SplitString(combination, ',')
    local validParts = {}

    for i = 1, table.getn(parts) do
        local part = TrimSpaces(parts[i]) -- Manually trim spaces
        -- Exclude specific keywords
        if part ~= "AIR" and part ~= "HIGHALTAIR" and part ~= "LAND" and part ~= "POD" and part ~= "STRUCTURE" and part ~= "NAVAL" then
            table.insert(validParts, part)
        end
    end

    -- Join the valid parts into a new combination string
    if table.getn(validParts) > 0 then
        return table.concat(validParts, ",")
    else
        return "UNTARGETABLE" -- Return an empty string if no valid parts remain
    end
end

function PostModBlueprints(all_bps)
    -- Brute51: Modified code for ship wrecks and added code for SCU presets.
    -- removed the pairs() function call in the for loops for better efficiency and because it is not necessary.
    -- local preset_bps = {}

    SpawnMenuDummyChanges(all_bps.Unit)
    
    -- for _, bp in all_bps.Unit do
    --     -- skip units without categories
    --     if bp.Categories then
    --         -- check if blueprint was changed in ModBlueprints(all_bps)
    --         if bp.Mod or table.getsize(bp.CategoriesHash) ~= table.getsize(bp.Categories) then
    --         bp.CategoriesHash = table.hash(bp.Categories)
    --         end

    --         if bp.CategoriesHash.USEBUILDPRESETS then
    --             -- HUSSAR adding logic for finding issues in enhancements table
    --             local issues = {}
    --             if not bp.Enhancements then table.insert(issues, 'no Enhancements value') end
    --             if type(bp.Enhancements) ~= 'table' then table.insert(issues, 'no Enhancements table') end
    --             if not bp.EnhancementPresets then table.insert(issues, 'no EnhancementPresets value') end
    --             if type(bp.EnhancementPresets) ~= 'table' then table.insert(issues, 'no EnhancementPresets table') end
    --             -- check blueprint, if correct info for presets then put this unit on the list to handle later
    --             if table.empty(issues) then
    --                 table.insert(preset_bps, table.deepcopy(bp))
    --             else
    --                 issues = table.concat(issues, ', ')
    --                 WARN('UnitBlueprint ' .. repr(bp.BlueprintId) .. ' has a category USEBUILDPRESETS but ' .. issues)
    --             end
    --         end
    --     end

    --     BlueprintLoaderUpdateProgress()
    -- end

    -- HandleUnitWithBuildPresets(preset_bps, all_bps)

    FindCustomStrategicIcons(all_bps)
    BlueprintLoaderUpdateProgress()

    SetThreatValuesOfUnits(all_bps.Unit)
    BlueprintLoaderUpdateProgress()

    ProcessWeapons(all_bps, all_bps.Unit)
    BlueprintLoaderUpdateProgress()

    PostProcessProjectiles(all_bps.Projectile)
    PostProcessUnits(all_bps, all_bps.Unit)
    PostProcessProps(all_bps.Prop)
    BlueprintLoaderUpdateProgress()

    for _, prop in all_bps.Prop do
        SetUnitLOD(prop)
    end

    for _, unit in all_bps.Unit do
        SetUnitLOD(unit)
    end

    for _, unit in all_bps.Mesh do
        SetUnitLOD(unit)
    end

    for _, unit in all_bps.Projectile do
        SetUnitLOD(unit)
    end

    for _, unit in all_bps.TrailEmitter do
        SetUnitLOD(unit)
    end

    for _, unit in all_bps.Emitter do
        SetUnitLOD(unit)
    end

    for _, unit in all_bps.Beam do
        SetUnitLOD(unit)
    end
end

do
    function Scale(table, keyName, scale, newValueIfWasZero)
        if table == nil then
            LOG("ATTEMPTED TO DO AN INPLACE OPERATION ON NIL TABLE - " .. table .. keyName)
        end

        if table[keyName] == nil then
            return
        end

        if table[keyName] == 0 then
            if newValueIfWasZero == 0 or newValueIfWasZero == nil then
                return
            end

            table[keyName] = newValueIfWasZero
        end

        table[keyName] = table[keyName] * scale
    end

    function Add(table, keyName, value)
        if table == nil then
            LOG("ATTEMPTED TO DO AN INPLACE OPERATION ON NIL TABLE - " .. table .. keyName)
        end

        if table[keyName] == nil then
            return
        end

        table[keyName] = table[keyName] + value
    end

    local originalModBlueprints = ModBlueprints
    function ModBlueprints(all_bps)
        originalModBlueprints(all_bps)

        for id, bp in all_bps.Prop do

            if bp.Defense and bp.Defense.MaxHealth then
                Scale(bp.Defense, "MaxHealth", 300000, 0)
            end

            if bp.Defense and bp.Defense.Health then
                Scale(bp.Defense, "Health", 300000, 0)
            end
            
            if bp.ScriptModule == '/lua/proptree.lua' then
                if bp.Economy then
                    Scale(bp.Economy, "ReclaimMassMax", 0, 0)
                end

                bp.ScriptModule = nil
            end
        end

        for id, bp in all_bps.Projectile do
            if bp.Economy then
                Scale(bp.Economy, "BuildCostMass", 0.375, 0)

                if bp.Economy.BuildTime then
                    bp.Economy.BuildTime = bp.Economy.BuildCostEnergy / 25 + bp.Economy.BuildCostMass / 10
                end
            end
        end

        for id, bp in all_bps.Unit do
            local Categories = {}
            for _, cat in bp.Categories do
                Categories[cat] = true
            end

            if Categories.COMMAND then
                table.insert(bp.Categories, "TECH3")
                table.insert(bp.Categories, 'BUILTBYQUANTUMGATE')
            end

            if (Categories.BUILTBYTIER1ENGINEER or Categories.BUILTBYTIER2ENGINEER or Categories.BUILTBYTIER3ENGINEER or 
            Categories.BUILTBYTIER1FACTORY or Categories.BUILTBYTIER2FACTORY or Categories.BUILTBYTIER3FACTORY or 
            Categories.BUILTBYAIRTIER2FACTORY or Categories.BUILTBYAIRTIER3FACTORY or 
            Categories.BUILTBYLANDTIER2FACTORY or Categories.BUILTBYLANDTIER3FACTORY or 
            Categories.BUILTBYNAVALTIER2FACTORY or Categories.BUILTBYNAVALTIER3FACTORY or 
            Categories.BUILTBYTIER2SUPPORTFACTORY or
            Categories.TRANSPORTBUILTBYTIER1FACTORY or Categories.TRANSPORTBUILTBYTIER2FACTORY or Categories.TRANSPORTBUILTBYTIER3FACTORY or 
            Categories.BUILTBYQUANTUMGATE) and (not Categories.CRABEGG) and (not Categories.EXPERIMENTAL) and (not Categories.EXTERNALFACTORY) then
                if Categories.TECH1 then
                    table.insert(bp.Categories, "BUILTBYCOMMANDER")
                    table.insert(bp.Categories, "BUILTBYTIER1COMMANDER")
                    table.insert(bp.Categories, "BUILTBYTIER1ENGINEER")
                    table.insert(bp.Categories, "BUILTBYTIER2ENGINEER")
                    table.insert(bp.Categories, "BUILTBYTIER3ENGINEER")
                    table.insert(bp.Categories, "BUILTBYTIER2FIELD")

                elseif Categories.TECH2 then
                    if not Categories.ENGINEER then
                        table.insert(bp.Categories, "BUILTBYTIER1FACTORY")
                    end

                    table.insert(bp.Categories, "BUILTBYTIER2COMMANDER")
                    table.insert(bp.Categories, "BUILTBYTIER2ENGINEER")
                    table.insert(bp.Categories, "BUILTBYTIER3ENGINEER")

                elseif Categories.TECH3 then
                    if not Categories.ENGINEER then
                        table.insert(bp.Categories, "BUILTBYTIER1FACTORY")
                        table.insert(bp.Categories, "BUILTBYTIER2FACTORY")
                    end

                    table.insert(bp.Categories, "BUILTBYTIER3COMMANDER")
                    table.insert(bp.Categories, "BUILTBYTIER3ENGINEER")
                end

                -- if (not Categories.DRAGBUILD) and (not Categories.NEEDMOBILEBUILD) and Categories.MOBILE then
                --     table.insert(bp.Categories, "DRAGBUILD")
                --     table.insert(bp.Categories, "NEEDMOBILEBUILD")
                -- end
            end

            Categories = {}
            for _, cat in bp.Categories do
                Categories[cat] = true
            end

            if bp.Enhancements then
                for _, enhancement in bp.Enhancements do
                    Add(enhancement, "NewMaxRadius", 70)
                    Add(enhancement, "Radius", 70)
                    Add(enhancement, "NewDamageRadius", 2, 0)

                    Scale(enhancement, "NewVisionRadius", 3, 0)
                    --Scale(enhancement, "NewRateOfFire", 1.25, 0)
                    Scale(enhancement, "NewHealth", 1.5, 0)
                    Scale(enhancement, "NewRegenRate", 1.5, 0)
                    Scale(enhancement, "ACUAddHealth", 1.5, 0)
                    Scale(enhancement, "MaxHealthFactor", 2, 0)
                    Scale(enhancement, "RegenFloor", 1.5, 0)
                    Scale(enhancement, "RegenCeiling", 1.5, 0)
                    Scale(enhancement, "RegenPerSecond", 1.5, 0)
                    Scale(enhancement, "AdditionalDamage", 2, 0)
                    Scale(enhancement, "ShieldMaxHealth", 3, 0)
                    Scale(enhancement, "ShieldRegenRate", 3, 0)
                    Scale(enhancement, "ShieldShieldSize", 3, 0)
                    Scale(enhancement, "BuildCostMass", 0.222, 0)
                    Scale(enhancement, "ProductionPerSecondMass", 0.222, 0)

                    if enhancement.BuildTime then
                        enhancement.BuildTime = enhancement.BuildCostEnergy / 40
                    end
                end
            end

            if bp.Physics then
                if Categories.MOBILE then
                    if bp.Air then
                        --Scale(bp.Physics, "Elevation", 1.333, 0)
                        -- Scale(bp.Air, "MaxAirspeed", 1.1, 0)
                        -- Scale(bp.Air, "StartTurnDistance", 1.1, 0)
        
                        -- if Categories.BOMBER then
                        --     Scale(bp.Air, "MaxAirspeed", 1.25, 0)
                        --     Scale(bp.Air, "StartTurnDistance", 1.5, 0)
                        -- end
                        Scale(bp.Physics, "TurnRadius", 0.666, 0)
                        Scale(bp.Physics, "TurnRate", 1.5, 0)
                        Scale(bp.Physics, "MaxAcceleration", 1.2, 0)
                    else
                        -- Scale(bp.Physics, "MaxSpeed", 1.1, 0)
                        Scale(bp.Physics, "TurnRadius", 1.1, 0)
                        Scale(bp.Physics, "TurnRate", 1.1, 0)
                        Scale(bp.Physics, "MaxAcceleration", 1.1, 0)
                    end

                    if bp.Physics.SkirtSizeX == nil or bp.Physics.SkirtSizeX < 2 then
                        bp.Physics.SkirtSizeX = 2
                        if not Categories.AIR then
                            bp.Physics.SkirtOffsetX = -0.5
                        end
                    end
                    if bp.Physics.SkirtSizeZ == nil or bp.Physics.SkirtSizeZ < 2 then
                        bp.Physics.SkirtSizeZ = 2
                        if not Categories.AIR then
                            bp.Physics.SkirtOffsetZ = -0.5
                        end
                    end
                end

                bp.Physics.MaxGroundVariation = 20
            end

            if bp.Intel then
                Scale(bp.Intel, "VisionRadius", 3, 0)
                Scale(bp.Intel, "RadarRadius", 3, 0)
                Scale(bp.Intel, "SonarRadius", 3, 0)
                Scale(bp.Intel, "WaterVisionRadarRadius", 3, 0)
            end

            if bp.Defense then
                if bp.Air then
                    bp.Defense.ArmorType = 'Air'
                end

                if bp.Defense.Shield and bp.Defense.Shield.ShieldSize then
                    if bp.Defense.Shield.ShieldSpillOverDamageMod then
                        bp.Defense.Shield.ShieldSpillOverDamageMod = 0
                    end
                    
                    Scale(bp.Defense.Shield, "ShieldSize", 3, 0)
                    Scale(bp.Defense.Shield, "ShieldProjectionSize", 3, 0)
                end
            end

            if bp.Weapon then
                for i, weapon in bp.Weapon do
                    -- weapon.ReTargetOnMiss = true
                    -- weapon.DesiredShooterCap = 5
                    -- weapon.DisableWhileReloading = true
                    -- weapon.AlwaysRecheckTarget = true
                    -- weapon.TargetResetWhenReady = true

                    -- Scale(weapon, "EffectiveRadius", 2.5, 0)
                    -- Scale(weapon, "BombDropThreshold", 2.5, 3)

                    -- Scale(weapon, "NukeInnerRingDamage", 2.5, 0)
                    Scale(weapon, "NukeInnerRingRadius", 1.5, 0)
                    -- Scale(weapon, "NukeInnerRingTicks", 2.5, 0)
                    -- Scale(weapon, "NukeInnerRingTotalTime", 2.5, 0)

                    -- Scale(weapon, "NukeOuterRingDamage", 2.5, 0)
                    Scale(weapon, "NukeOuterRingRadius", 1.5, 0)
                    -- Scale(weapon, "NukeOuterRingTicks", 2.5, 0)
                    -- Scale(weapon, "NukeOuterRingTotalTime", 2.5, 0)

                    if weapon.WeaponCategory == "Anti Air" then
                        weapon.DamageType = 'AntiAir'

                        if weapon.DamageRadius == nil or weapon.DamageRadius < 1.225 then
                            weapon.DamageRadius = 1.225
                        end

                        if weapon.DamageRadius then
                            weapon.DamageRadius = weapon.DamageRadius * 1.5
                        end

                        Scale(weapon, "TurretYawSpeed", 3, 0)
                        Scale(weapon, "TurretPitchSpeed", 3, 0)
                        -- Scale(weapon, "Damage", 0.9, 0)
                        -- Scale(weapon, "RateOfFire", 0.5, 0)
                        -- Add(weapon, "MaximumBeamLength", 30)
                        Add(weapon, "ProjectileLifetime", 5)
                        Add(weapon, "ProjectileLifetimeUsesMultiplier", 2)
                        Add(weapon, "FiringRandomnessWhileMoving", 0.0025)
                        Add(weapon, "FiringRandomness", 0.00025)

                        -- Add(weapon, "EffectiveRadius", 50)
                        Add(weapon, "MaxRadius", 60)
                        Add(weapon, "MuzzleVelocity", math.sqrt(175))
                        -- Add(weapon, "MuzzleVelocityReduceDistance", -30)
                        -- Add(weapon, "MuzzleChargeStart", 30)

                        -- if weapon.ToggleWeapon and string.find(weapon.FireTargetLayerCapsTable['Land'], 'Air')  then
                        --     Add(weapon, "MaxRadius", -40)
                        -- else
                        --     Add(weapon, "MaxRadius", 20)
                        -- end
                        
                        if weapon.TargetRestrictDisallow then
                            weapon.TargetRestrictDisallow = CleanCombination(weapon.TargetRestrictDisallow)
                        end
    
                        if weapon.TargetRestrictOnlyAllow and weapon.TargetRestrictOnlyAllow == "AIR" then
                            weapon.TargetRestrictOnlyAllow = ""
                        end

                        if weapon.FireTargetLayerCapsTable then
                            weapon.FireTargetLayerCapsTable = {
                                Orbit = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Air = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Land = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Water = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Seabed = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Sub = 'Orbit|Air|Land|Water|Seabed|Sub',
                            }
                        end

                    elseif weapon.RangeCategory == "UWRC_Countermeasure" then
                        Scale(weapon, "MaxRadius", 1, 0)
                    elseif weapon.WeaponCategory == "Artillery" or weapon.WeaponCategory == "Missile" then
                        if Categories.MOBILE then
                            if weapon.DamageRadius then
                                weapon.DamageRadius = weapon.DamageRadius * 3
                            end
    
                            if weapon.DamageRadius == nil or weapon.DamageRadius < 1 then
                                weapon.DamageRadius = 2
                            end

                            Add(weapon, "ProjectileLifetime", 60)
                            Add(weapon, "ProjectileLifetimeUsesMultiplier", 3)
                            Add(weapon, "MaxRadius", 60)
                            Add(weapon, "EffectiveRadius", 60)
                            Add(weapon, "MuzzleVelocity", math.sqrt(60))
                        else
                            if weapon.DamageRadius then
                                weapon.DamageRadius = weapon.DamageRadius * 2.5
                            end
    
                            if weapon.DamageRadius == nil or weapon.DamageRadius < 1 then
                                weapon.DamageRadius = 2
                            end

                            Add(weapon, "ProjectileLifetime", 300)
                            Add(weapon, "ProjectileLifetimeUsesMultiplier", 6)
                            Add(weapon, "MaxRadius", 500)
                            Add(weapon, "EffectiveRadius", 500)
                            Add(weapon, "MuzzleVelocity", math.sqrt(600))
                        end
                    elseif weapon.RangeCategory == "UWRC_Countermeasure" then
                        Scale(weapon, "MaxRadius", 1, 0)
                    else
                        if weapon.DamageRadius then
                            weapon.DamageRadius = weapon.DamageRadius * 3
                        end

                        if weapon.DamageRadius == nil or weapon.DamageRadius < 1 then
                            weapon.DamageRadius = 2
                        end

                        Add(weapon, "MaximumBeamLength", 70)
                        Add(weapon, "ProjectileLifetime", 70)
                        Add(weapon, "ProjectileLifetimeUsesMultiplier", 3)
                        Add(weapon, "MaxRadius", 70)
                        Add(weapon, "EffectiveRadius", 70)
                        Add(weapon, "MuzzleVelocity", math.sqrt(70))

                        -- Scale(weapon, "MuzzleVelocityReduceDistance", -30, 0)
                        -- Add(weapon, "FixedSpreadRadius", 0.1)
                        -- Add(weapon, "MuzzleVelocityRandom", 0.025)
                        -- Add(weapon, "FiringRandomness", 0.00025)
                        -- Add(weapon, "FiringRandomnessWhileMoving", 0.0005)
                        -- -- Add(weapon, "MuzzleChargeStart", 30)

                        -- if weapon.ToggleWeapon then --and string.find(weapon.FireTargetLayerCapsTable['Land'], 'Air')
                        --     Add(weapon, "MaxRadius", -40)
                        -- else
                        --     Add(weapon, "MaxRadius", 20)
                        -- end

                        if weapon.TargetRestrictDisallow then
                            weapon.TargetRestrictDisallow = CleanCombination(weapon.TargetRestrictDisallow)
                        end
    
                        if weapon.TargetRestrictOnlyAllow and weapon.TargetRestrictOnlyAllow == "AIR" then
                            weapon.TargetRestrictOnlyAllow = ""
                        end

                        if weapon.FireTargetLayerCapsTable then
                            weapon.FireTargetLayerCapsTable = {
                                Orbit = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Air = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Land = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Water = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Seabed = 'Orbit|Air|Land|Water|Seabed|Sub',
                                Sub = 'Orbit|Air|Land|Water|Seabed|Sub',
                            }
                        end

                    end

                    if not Categories.COMMAND and (
                    weapon.WeaponCategory == "Anti Air" or 
                    weapon.WeaponCategory == "Anti Navy" or 
                    weapon.WeaponCategory == "Artillery" or 
                    weapon.WeaponCategory == "Defense" or
                    weapon.WeaponCategory == "Direct Fire" or
                    weapon.WeaponCategory == "Experimental" or
                    weapon.WeaponCategory == "Indirect Fire" or
                    weapon.WeaponCategory == "Missile") then
                        local rof
                        if weapon.RateOfFire then
                            rof = weapon.RateOfFire
                        else
                            rof = 1
                        end

                        if weapon.Damage and weapon.DamageRadius and weapon.MaxRadius then
                            local numProj = weapon.SalvoSize or 1
                            weapon.EnergyRequired = ((((weapon.Damage + 1) * (weapon.DamageRadius + 1)) + (weapon.MaxRadius + 1)) * numProj) * 0.1
                            weapon.EnergyDrainPerSecond = weapon.EnergyRequired * 8 * rof * numProj
                        end
                    end
                end
            end

            if bp.AI and (not Categories.BOMBER) then
                Add(bp.AI, "GuardScanRadius", 70)
                Add(bp.AI, "GuardReturnRadius", 70)
                Add(bp.AI, "GuardRadius", 70)
                Add(bp.AI, "StagingPlatformScanRadius", 70)
            end

            if bp.Economy then
                if Categories.ENERGYSTORAGE then
                    Scale(bp.Economy, "StorageEnergy", 3, 0)
                end

                if Categories.MASSSTORAGE then
                    Scale(bp.Economy, "StorageMass", 3, 0)
                end

                if bp.Economy.BuildCostMass ~= nil and bp.Economy.BuildCostMass ~= 0  then
                    local massNew
                    local massOld = bp.Economy.BuildCostMass
    
                    if Categories.TECH1 then
                        massNew = massOld * 0.222
                        Scale(bp, "VeteranMassMult", 0.222, 0)
                    elseif Categories.TECH2 then
                        massNew = massOld * 0.555
                        Scale(bp, "VeteranMassMult", 0.444, 0)
                    elseif Categories.TECH3 then
                        massNew = massOld * 0.888
                        Scale(bp, "VeteranMassMult", 0.888, 0)
                    elseif Categories.EXPERIMENTAL then
                        massNew = massOld * 0.888
                        Scale(bp, "VeteranMassMult", 0.888, 0)
                    else
                        massNew = massOld * 0.222
                        Scale(bp, "VeteranMassMult", 0.222, 0)
                    end
                
                    if Categories.COMMAND then
                        bp.Economy.ProductionPerSecondMass = 2
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.0025
                        bp.Economy.ProductionPerSecondEnergy = 80
                        bp.Economy.BuildCostMass = 10000
                    else
                        if bp.Economy.ProductionPerSecondEnergy and (not Categories.COMMAND) and (not Categories.SUBCOMMANDER) then
                            massOld = massOld * 2
                            bp.Economy.ProductionPerSecondEnergy = massOld * 0.375
                            bp.Economy.BuildCostEnergy = massOld * 5
                            bp.Economy.BuildCostMass = massOld * 0.222
                        else
                            bp.Economy.BuildCostMass = massNew
                        end
    
                        Scale(bp.Economy, "ProductionPerSecondMass", 0.222, 0)
                    end
                end

                Scale(bp.Economy, "MaxBuildDistance", 2.75, 40)

                if bp.Economy.BuildTime and bp.Economy.BuildCostMass and bp.Economy.BuildCostEnergy then
                    if Categories.STRUCTURE then
                        bp.Economy.BuildTime = bp.Defense.MaxHealth / 10 + bp.Economy.BuildCostEnergy / 100 + bp.Economy.BuildCostMass / 10
                    else
                        bp.Economy.BuildTime = bp.Defense.MaxHealth / 4 + bp.Economy.BuildCostEnergy / 75 + bp.Economy.BuildCostMass / 10
                    end
                end
            end

            if bp.Wreckage and bp.Wreckage.MassMult then
                bp.Wreckage.MassMult = 1
                bp.Wreckage.ReclaimTimeMultiplier = 1
                bp.Wreckage.HealthMult = 300000
            end
        end
    end
end
