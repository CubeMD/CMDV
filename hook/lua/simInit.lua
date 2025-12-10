--- START OF FILE simInit.txt ---

function BeginSession()
    -- imported for side effects
    import("/lua/sim/markerutilities.lua").Setup()

    BeginSessionAI()
    BeginSessionMapSetup()
    BeginSessionEffects()
    BeginSessionTeams()

    import("/lua/sim/scenarioutilities.lua").CreateProps()
    -- import("/lua/sim/scenarioutilities.lua").CreateResources()

    import("/lua/sim/score.lua").init()
    import("/lua/sim/recall.lua").init()

    -- other logic at the start of the game --
    local victoryCondition = import("/lua/sim/victorycondition/VictoryConditionSingleton.lua").GetSingleton()
    victoryCondition:StartMonitoring()

    Sync.EnhanceRestrict = import("/lua/enhancementcommon.lua").GetRestricted()
    Sync.Restrictions = import("/lua/game.lua").GetRestrictions()

    if syncStartPositions then
        Sync.StartPositions = syncStartPositions
    end

    if not Sync.NewPlayableArea then
        Sync.NewPlayableArea = {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
    end

    -- keep track of user name for LOCs
    local focusarmy = GetFocusArmy()
    if focusarmy>=0 and ArmyBrains[focusarmy] then
        LocGlobals.PlayerName = ArmyBrains[focusarmy].Nickname
    end

    -- add on game over callbacks
    ForkThread(GameOverListenerThread)

    -- keep track of units off map
    OnStartOffMapPreventionThread()

    -- trigger event for brains
    for k, brain in ArmyBrains do
        brain:OnBeginSession()
    end
    
    -- VOLCANO / DEADLOCK LOGIC STARTS HERE --

    local unitVulcan = false
    
    local PropAfterProjectile = "/env/Geothermal/Props/Rocks/GeoRockGroup01_prop.bp"
    local EffectTemplate = import('/lua/EffectTemplates.lua')

    local msizeX, msizeY = GetMapSize()
    msizeX = msizeX / 2
    msizeY = msizeY / 2

    local neutralCivilians = 1
    local armies = ListArmies()
    for i, army in armies do
        if army == "NEUTRAL_CIVILIAN" then
            neutralCivilians = i
            break
        end
    end

    if neutralCivilians == -1 then
        for i, army in armies do
            if army == "ARMY_17" then
                neutralCivilians = i
                break
            end
        end
    end

    local function makeInvincible(unit)
        unit:HideBone(0,true)
        unit:SetDoNotTarget(true)
        unit:SetCanBeKilled(false)
        unit:SetCapturable(false)
        unit:SetReclaimable(false)
        unit:SetDoNotTarget(true)
        unit:SetMaxHealth(1)
        unit:SetHealth(nil,1)
        unit:SetRegenRate(1)
    end

    local unit = CreateUnitHPR('URL0101', neutralCivilians , 32,  0, 32, 0, 0, 0)
    makeInvincible(unit)
    Warp( unit, Vector(-1500, 500, -1500))
    unitVulcan = unit

    local data = {}
    data.pos = Vector(msizeX, 300, msizeY)
    data.stage1 = 10
    data.vulcanProjectiles = 5

    local step = 0

    -- RIPPLE FUNCTION: Creates an expanding ring of force to push wreckage
    local function CreateRipple(pos, maxRadius, forceAmount)
        ForkThread(function()
            local steps = 5
            local interval = 0.1
            
            for i = 1, steps do
                local rMin = (maxRadius / steps) * (i - 1)
                local rMax = (maxRadius / steps) * i
                
                -- We use 'TreeForce' (or 'Force') to trigger the physics in Prop.lua
                -- Ensure Prop.lua does NOT return on this damage type!
                DamageRing(unitVulcan, pos, rMin, rMax, forceAmount, 'TreeForce', false, false)
                
                WaitSeconds(interval)
            end
        end)
    end

    function CreateVulcan()
        while true do
            step = step + 1

            WaitSeconds(data.stage1)

            ForkThread(function()
                local position = data.pos
                local posX = position[1]
                local posY = position[2]
                local posZ = position[3]

                local function GetMeteorDamageTable()
                    local damageTable = {}
                    damageTable.DamageRadius = 0
                    damageTable.DamageAmount = 0
                    damageTable.DamageType = 'Normal'
                    damageTable.DamageFriendly = false
                    damageTable.CollideFriendly = false
                    return damageTable
                end
        
                local t = math.sin(step / 900.0)
                for i = 1, data.vulcanProjectiles do
                    local meteorProj = unitVulcan:CreateProjectile('/projectiles/TDFGauss01/TDFGauss01_proj.bp', 0, 255, 0, nil, nil, nil):SetLifetime(30)
                    meteorProj:SetNewTargetGround({posX, 0, posZ})
                
                    meteorProj:SetVelocity(0, -10, 0)

                    meteorProj:PassDamageData(GetMeteorDamageTable())
                    
                    CreateEmitterOnEntity(meteorProj, unitVulcan.Army, '/effects/emitters/fire_cloud_06_emit.bp'):SetEmitterParam('LIFETIME', 10000):ScaleEmitter(4)
                    CreateEmitterOnEntity(meteorProj, unitVulcan.Army, '/effects/emitters/Medium_test_fire.bp'):SetEmitterParam('LIFETIME', 10000):ScaleEmitter(0.5)
                    
                    Warp( meteorProj, Vector(Random(0, msizeX * 2), posY, Random(0, msizeY * 2)))
                
                    local oldCreateImpactEffects = meteorProj.CreateImpactEffects
                    meteorProj.CreateImpactEffects = function(self, army, EffectTable, EffectScale)
                        oldCreateImpactEffects(self, army, EffectTemplate.TAPDSHitUnit01, 3)
                    end

                    local oldOnDestroy = meteorProj.OnDestroy
                    meteorProj.OnDestroy = function(self)
                        local p = meteorProj:GetPosition()
                        
                        -- 1. Create the Wreckage Prop
                        local prop = CreateProp(Vector(p[1], GetTerrainHeight(p[1],p[3]), p[3]), PropAfterProjectile)
                        prop:SetMaxReclaimValues(1, 300 + t * 1000, 0)
                        
                        -- 2. Create the Ripple Effect (The Splash)
                        -- Radius 15, Force 5000 (High force needed for log math in Prop.lua)
                        CreateRipple(p, 15, 5000) 

                        oldOnDestroy(self)
                    end
                end
            end)
        end
    end

    ForkThread(CreateVulcan)
end

function SetupSession()
    import("/lua/ai/gridreclaim.lua").Setup()
    ScenarioInfo.TriggerManager = import("/lua/triggermanager.lua").Manager
    TriggerManager = ScenarioInfo.TriggerManager
    ScenarioInfo.GameHasAIs = false

    if ScenarioInfo.type ~= 'skirmish' then
        ScenarioInfo.GameHasAIs = true
        SPEW("Detected a non-skirmish type map: enabling AI functionality")
    end

    if ScenarioInfo.requiresAiFunctionality then
        ScenarioInfo.GameHasAIs = true
        SPEW("Detected the 'requiresAiFunctionality' field set by the map: enabling AI functionality")
    end

    ArmyBrains = {}
    ScenarioInfo.PlatoonHandles = {}
    ScenarioInfo.UnitGroups = {}
    ScenarioInfo.UnitNames = {}
    ScenarioInfo.VarTable = {}
    ScenarioInfo.OSPlatoonCounter = {}
    ScenarioInfo.BuilderTable = { Air = {}, Land = {}, Sea = {}, Gate = {} }
    ScenarioInfo.BuilderTable.AddedPlans = {}
    ScenarioInfo.MapData = { PathingTable = { Amphibious = {}, Water = {}, Land = {}, }, IslandData = {} }
    ScenarioInfo.Env = import("/lua/scenarioenvironment.lua")

    local shareOption = ScenarioInfo.Options.Share
    local globalOptions = import("/lua/ui/lobby/lobbyoptions.lua").globalOpts
    local shareOptions = {}
    for _,globalOption in globalOptions do
        if globalOption.key == 'Share' then
            for _,value in globalOption.values do
                shareOptions[value.key] = true
            end
            break
        end
    end
    if not shareOptions[shareOption] then
        ScenarioInfo.Options.Share = 'ShareUntilDeath'
    end

    local buildRestrictions, enhRestrictions = nil, {}
    local restrictions = ScenarioInfo.Options.RestrictedCategories

    if restrictions then
        local presets = import("/lua/ui/lobby/unitsrestrictions.lua").GetPresetsData()
        for index, restriction in restrictions do
            local preset = presets[restriction]
            if not preset then 
                enhRestrictions[restriction] = true
                if buildRestrictions then
                    buildRestrictions = buildRestrictions .. " + (" .. restriction .. ")"
                else
                    buildRestrictions = "(" .. restriction .. ")"
                end
            else 
                if preset.categories then
                    if buildRestrictions then
                        buildRestrictions = buildRestrictions .. " + (" .. preset.categories .. ")"
                    else
                        buildRestrictions = "(" .. preset.categories .. ")"
                    end
                end
                if preset.enhancements then
                    for _, enhancement in preset.enhancements do
                        enhRestrictions[enhancement] = true
                    end
                end
            end
        end
    end

    if buildRestrictions then
        buildRestrictions = import("/lua/sim/categoryutils.lua").ParseEntityCategoryProperly(buildRestrictions)
        import("/lua/game.lua").AddRestriction(buildRestrictions)
        ScenarioInfo.BuildRestrictions = buildRestrictions
    end

    if not table.empty(enhRestrictions) then
        import("/lua/enhancementcommon.lua").RestrictList(enhRestrictions)
    end

    doscript('/lua/dataInit.lua')
    doscript(ScenarioInfo.save, ScenarioInfo.Env)

    Scenario = ScenarioInfo.Env.Scenario

    local spawn = ScenarioInfo.Options.TeamSpawn
    if spawn and table.find({'random_reveal', 'balanced_reveal', 'balanced_flex_reveal'}, spawn) then
        syncStartPositions = {}
        ShuffleStartPositions(true)
    elseif spawn and table.find({'random', 'balanced', 'balanced_flex'}, spawn) then
        ShuffleStartPositions(false)
    end

    doscript(ScenarioInfo.script, ScenarioInfo.Env)
    ResetSyncTable()
end