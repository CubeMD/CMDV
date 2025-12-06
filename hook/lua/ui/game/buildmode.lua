local function HandleCommand(key, modifiers)
    local selection = GetSelectedUnits()
    if not selection then
        PlayErrorSound()
        return
    end

    -- make sure the units are all of the same type
    local types = {}
    for index, unit in selection do
        local bpid = unit:GetBlueprint().BlueprintId
        if not types[bpid] then
            types[bpid] = true
        end
        if table.getsize(types) > 1 then
            -- different types selected
            PlayErrorSound()
            return
        end
    end

    if Construction.GetCurrentTechTab() == 5 then
        return HandleBuildTemplate(key, modifiers)
    end
    
    local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)
    local buildableUnits = EntityCategoryGetUnitList(buildableCategories)

    local function CanBuild(blueprintID)
        local canBuild = false
        for i, v in buildableUnits do
            if v == blueprintID then
                canBuild = true
                break
            end
        end
        return canBuild
    end

    local bmdata = import("/lua/ui/game/buildmodedata.lua").buildModeKeys
    local bp = selection[1]:GetBlueprint()
    local bpid = bp.BlueprintId
    
    if not bmdata[bpid] then
        PlayErrorSound()
        return
    end
    
    if key == keyCode['U'] then
        if bmdata[bpid]['U'] and CanBuild(bmdata[bpid]['U']) then
            IssueBlueprintCommand("UNITCOMMAND_Upgrade", bmdata[bpid]['U'], 1, false)
        else
            PlayErrorSound()
            return
        end
    else
        local curTechLevel = Construction.GetCurrentTechTab()
        if not curTechLevel then
            WARN("No cur tech level found!")
            return
        end
    
        local tobuild = bmdata[bpid][curTechLevel][string.char(key)]
        if not tobuild or not CanBuild(tobuild) then
            PlayErrorSound()
            return
        end
        
        local tobuildbp = __blueprints[tobuild]

        -- separate factories from engineers
        local factories = {}

        for index, unit in selection do
            if EntityCategoryContains(categories.FACTORY, unit) then
                table.insert(factories, unit)
            end
        end 
        
        if table.getsize(factories) > 0 then
            -- if the item to build can move, it must be built by a factory
            local count = 1
            if modifiers.Shift or modifiers.Ctrl or modifiers.Alt then
                count = 5
            end
            IssueBlueprintCommand("UNITCOMMAND_BuildFactory", tobuild, count)
        else
            -- stationary means it needs to be placed, so go in to build mobile mode
            import("/lua/ui/game/commandmode.lua").StartCommandMode("build", {name=tobuild})
        end        
    end
end