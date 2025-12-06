function BeginSession()
    -- imported for side effects
    import("/lua/sim/matchstate.lua").Setup()
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
	
	-- this is the end of original BeginSession. Only 'import("/lua/sim/scenarioutilities.lua").CreateResources()' resources part was changed from base class implementation

-- function FlattenMapRect(x, z, sizeX, sizeZ, elevation)
-- end
	-- FlattenMapRect(10, 10, 10000, 10000, 10)

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
		
				-- local function RandomModify(minR, maxR)
				-- 	local r = math.pow((-1),Random(0,1))
				-- 	return r * Random(minR, maxR)
				-- end

				local t = math.sin(step / 900.0)
				for i = 1, data.vulcanProjectiles do
					local meteorProj = unitVulcan:CreateProjectile('/projectiles/TDFGauss01/TDFGauss01_proj.bp', 0, 255, 0, nil, nil, nil):SetLifetime(30)
					meteorProj:SetNewTargetGround({posX, 0, posZ})
				
					-- local max = (1 - t) * 15
					-- local min = math.max(max - 3, 0)
					
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
						local prop = CreateProp(Vector(p[1], GetTerrainHeight(p[1],p[3]), p[3]), PropAfterProjectile)
						prop:SetMaxReclaimValues(1, 300 + t * 1000, 0)
						--prop:AddWorldImpulse(1000,1000,1000,1000,1000,1000)
						-- local motor = prop:FallDown()
        				-- motor:Whack(100, 100, 100, 0, false)
						
						--Warp( prop, Vector(p[1] + Random(0,300), GetTerrainHeight(p[1],p[3]), p[3] + Random(0,300)))
						oldOnDestroy(self)
					end
				end
			end)
		end
	end

	ForkThread(CreateVulcan)

	-- local InitialListTrees = {}
	-- local TreeRegrowSpeed = 5
	
	-- function Tree_StartGrowingTrees()
	-- 	local SQRTnumberofareas = 1
	-- 	if(ScenarioInfo.size[1]>300) then
	-- 		SQRTnumberofareas = 4
	-- 	elseif(ScenarioInfo.size[1]>600) then
	-- 		SQRTnumberofareas = 8
	-- 	elseif(ScenarioInfo.size[1]>1200) then
	-- 		SQRTnumberofareas = 16
	-- 	end
	-- 	local m = 0
	-- 	local firstIndex = 1
	-- 	for i = 0, SQRTnumberofareas - 1 do
	-- 		for j = 0, SQRTnumberofareas - 1 do
	-- 			m = m + 1
	-- 			local Tree_Area = {
	-- 				["x0"] = ScenarioInfo.size[1]/SQRTnumberofareas*i,
	-- 				["y0"] = ScenarioInfo.size[2]/SQRTnumberofareas*j,
	-- 				["x1"] = ScenarioInfo.size[1]/SQRTnumberofareas*(i+1),
	-- 				["y1"] = ScenarioInfo.size[2]/SQRTnumberofareas*(j+1),
	-- 			}
	-- 			local numberTreeInArea = Tree_InitializeTrees(Tree_Area, InitialListTrees, firstIndex)
	-- 			if(numberTreeInArea > 0) then
	-- 				ForkThread(Tree_RegrowTrees, InitialListTrees, m, firstIndex, firstIndex + numberTreeInArea - 1)
	-- 				firstIndex = firstIndex + numberTreeInArea
	-- 			end
	-- 		end
	-- 	end
	-- 	LOG("ADAPTIVE: Tree script finished initialization, total number of trees = ", firstIndex)
	-- end
	
	-- function Tree_InitializeTrees(area, list, firstIndex)
	-- 	local i = firstIndex
	-- 	for _, r in GetReclaimablesInRect(area) or {} do
	-- 		if (IsProp(r)) then
	-- 			local storethetree = {  r:GetBlueprint().BlueprintId,
	-- 									r:GetPosition()['x'],
	-- 									r:GetPosition()['y'],
	-- 									r:GetPosition()['z']
	-- 								 }
	-- 			list[i] = storethetree
	-- 			i = i + 1
	-- 		end
	-- 	end
	-- 	LOG("ADAPTIVE: Trees initialized, number in this area = ", i - firstIndex)
	-- 	return i - firstIndex
	-- end
	
	-- function Tree_RegrowTrees(listoftrees, m, firstIndex, lastIndex)
	-- 	WaitSeconds(m)
	-- 	while( true ) do
	-- 		Tree_NextCycle(listoftrees, firstIndex, lastIndex)
	-- 	end
	-- end
	
	-- function Tree_NextCycle(listoftrees, firstIndex, lastIndex)
	-- 	local numberToRespawn = 0
	-- 	local RespawnOnNextCycle = {}
	-- 	local MissingTrees = false
	-- 	for i = firstIndex, lastIndex do
	-- 		local respawnprop = Tree_CheckIfReclaimed(listoftrees[i])
	-- 		if(respawnprop > 0) then
	-- 			LOG("Missing trees!")
	-- 			MissingTrees = true

	-- 			numberToRespawn = numberToRespawn + 1
	-- 			RespawnOnNextCycle[numberToRespawn] = i
	-- 			-- if(math.random() < respawnprop/30/TreeRegrowSpeed) then
					
	-- 			-- end
	-- 		end
	-- 	end
	-- 	WaitSeconds(5)
	-- 	-- if(not MissingTrees) then
	-- 	-- 	WaitSeconds(110/TreeRegrowSpeed)
	-- 	-- end
	-- 	for i, _ in RespawnOnNextCycle or {} do
	-- 		LOG("Respawned")
	-- 		CreateProp( Vector( listoftrees[RespawnOnNextCycle[i]][2], GetTerrainHeight(listoftrees[RespawnOnNextCycle[i]][2],listoftrees[RespawnOnNextCycle[i]][4]),listoftrees[RespawnOnNextCycle[i]][4] ),
	-- 		listoftrees[RespawnOnNextCycle[i]][1])
	-- 	end
	-- end
	
	-- function Tree_CheckIfReclaimed(tree)
	-- 	local NumberOfCloseTrees = 0
		
	-- 	local area1 = {
	-- 		["x0"] = tree[2] - 0.05,
	-- 		["y0"] = tree[4] - 0.05,
	-- 		["x1"] = tree[2] + 0.05,
	-- 		["y1"] = tree[4] + 0.05,
	-- 	}
	-- 	for _, t in GetReclaimablesInRect(area1) or {} do
	-- 		if(IsProp(t)) then
	-- 			if(tree[2] == t:GetPosition()['x']) then
	-- 				if(tree[4] == t:GetPosition()['z']) then
	-- 					if(tree[1] == t:GetBlueprint().BlueprintId) then
	-- 						return  - 1
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end

	-- 	return 1
		
	-- 	-- local area2 = {
	-- 	-- 	["x0"] = tree[2] - 1.5,
	-- 	-- 	["y0"] = tree[4] - 1.5,
	-- 	-- 	["x1"] = tree[2] + 1.5,
	-- 	-- 	["y1"] = tree[4] + 1.5,
	-- 	-- }

	-- 	-- for _, t in GetReclaimablesInRect(area2) or {} do
	-- 	-- 	if(string.find(t:GetBlueprint().BlueprintId, "tree" )) then
	-- 	-- 		NumberOfCloseTrees = NumberOfCloseTrees + 1
	-- 	-- 	end
	-- 	-- 	if(NumberOfCloseTrees > 20) then
	-- 	-- 		return - 1
	-- 	-- 	end
	-- 	-- end

	-- 	-- if NumberOfCloseTrees > 10 then
	-- 	-- 	return 20- NumberOfCloseTrees
	-- 	-- else
	-- 	-- 	return NumberOfCloseTrees
	-- 	-- end
	-- end

	-- ForkThread(Tree_StartGrowingTrees)
end

--SetupSession will be called by the engine after ScenarioInfo is set
--but before any armies are created.
function SetupSession()

    import("/lua/ai/gridreclaim.lua").Setup()

    ScenarioInfo.TriggerManager = import("/lua/triggermanager.lua").Manager
    TriggerManager = ScenarioInfo.TriggerManager

    -- assume there are no AIs
    ScenarioInfo.GameHasAIs = false

    -- if we're doing a campaign / special map then there may be AIs
    if ScenarioInfo.type ~= 'skirmish' then
        ScenarioInfo.GameHasAIs = true
        SPEW("Detected a non-skirmish type map: enabling AI functionality")
    end

    -- if the map maker explicitly tells us
    if ScenarioInfo.requiresAiFunctionality then
        ScenarioInfo.GameHasAIs = true
        SPEW("Detected the 'requiresAiFunctionality' field set by the map: enabling AI functionality")
    end

    -- LOG('SetupSession: ', repr(ScenarioInfo))
    ---@type AIBrain[]
    ArmyBrains = {}



    -- ScenarioInfo is a table filled in by the engine with fields from the _scenario.lua
    -- file we're using for this game. We use it to store additional global information
    -- needed by our scenario.
    ScenarioInfo.PlatoonHandles = {}
    ScenarioInfo.UnitGroups = {}
    ScenarioInfo.UnitNames = {}

    ScenarioInfo.VarTable = {}
    ScenarioInfo.OSPlatoonCounter = {}
    ScenarioInfo.BuilderTable = { Air = {}, Land = {}, Sea = {}, Gate = {} }
    ScenarioInfo.BuilderTable.AddedPlans = {}
    ScenarioInfo.MapData = { PathingTable = { Amphibious = {}, Water = {}, Land = {}, }, IslandData = {} }

    -- ScenarioInfo.Env is the environment that the save file and scenario script file
    -- are loaded into. We set it up here with some default functions that can be accessed
    -- from the scenario script.
    ScenarioInfo.Env = import("/lua/scenarioenvironment.lua")

    --Check if ShareOption is valid, and if not then set it to ShareUntilDeath
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

    -- if build/enhancement restrictions chosen, set them up
    local buildRestrictions, enhRestrictions = nil, {}

    local restrictions = ScenarioInfo.Options.RestrictedCategories

    if restrictions then
        table.print(restrictions, 'RestrictedCategories')
        local presets = import("/lua/ui/lobby/unitsrestrictions.lua").GetPresetsData()
        for index, restriction in restrictions do

            local preset = presets[restriction]
            if not preset then -- custom restriction
                LOG('restriction.custom: "'.. restriction ..'"')

                -- using hash table because it is faster to check for restrictions later in game
                enhRestrictions[restriction] = true

                if buildRestrictions then
                    buildRestrictions = buildRestrictions .. " + (" .. restriction .. ")"
                else
                    buildRestrictions = "(" .. restriction .. ")"
                end
            else -- preset restriction
                if preset.categories then
                    LOG('restriction.preset "'.. preset.categories .. '"')
                    if buildRestrictions then
                        buildRestrictions = buildRestrictions .. " + (" .. preset.categories .. ")"
                    else
                        buildRestrictions = "(" .. preset.categories .. ")"
                    end
                end
                if preset.enhancements then
                    LOG('restriction.enhancement "'.. restriction .. '"')
                    table.print(preset.enhancements, 'restriction.enhancements ')
                    for _, enhancement in preset.enhancements do
                        enhRestrictions[enhancement] = true
                    end
                end
            end
        end
    end

    if buildRestrictions then
        LOG('restriction.build '.. buildRestrictions)
        buildRestrictions = import("/lua/sim/categoryutils.lua").ParseEntityCategoryProperly(buildRestrictions)
        -- add global build restrictions for all armies
        import("/lua/game.lua").AddRestriction(buildRestrictions)
        ScenarioInfo.BuildRestrictions = buildRestrictions
    end

    if not table.empty(enhRestrictions) then
        --table.print(enhRestrictions, 'enhRestrictions ')
        import("/lua/enhancementcommon.lua").RestrictList(enhRestrictions)
    end

    -- Loads the scenario saves and script files
    -- The save file creates a table named "Scenario" in ScenarioInfo.Env,
    -- containing most of the save data. We'll copy it up to a top-level global.
    LOG('Loading save file: ',ScenarioInfo.save)
    doscript('/lua/dataInit.lua')
    doscript(ScenarioInfo.save, ScenarioInfo.Env)

    Scenario = ScenarioInfo.Env.Scenario

    local spawn = ScenarioInfo.Options.TeamSpawn
    if spawn and table.find({'random_reveal', 'balanced_reveal', 'balanced_flex_reveal'}, spawn) then
        -- Shuffles positions like normal but syncs the new positions to the UI
        syncStartPositions = {}
        ShuffleStartPositions(true)
    elseif spawn and table.find({'random', 'balanced', 'balanced_flex'}, spawn) then
        -- Prevents players from knowing start positions at start
        ShuffleStartPositions(false)
    end

    LOG('Loading script file: ', ScenarioInfo.script)
    doscript(ScenarioInfo.script, ScenarioInfo.Env)

    ResetSyncTable()
end