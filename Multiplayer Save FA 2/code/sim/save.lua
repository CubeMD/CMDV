ScenarioFramework = import('/lua/ScenarioFramework.lua')
SimQuery = import('/lua/SimPlayerQuery.lua')

-- -- ResolveRestrictions = import('/lua/game.lua').ResolveRestrictions
-- RemoveRestriction = import('/lua/game.lua').RemoveRestriction
-- categories = import('/engine/Core/Categories.lua').categories
-- -- AddRestriction  = import('/lua/game.lua').AddRestriction

-- Multiplayer Save global functions
msscript('code/sim/globals.lua')

-- This is a map of the old unit id to the newly created unit so orders can be restored
units_by_oldid = {}
-- This is a map of the old prop id to the newly created one so reclaim orders can be restored
props = {}
-- This is a map of transported units to their carrier so they can all be regrouped in one go
transports = {}

-- deletes globals to avoid conflicts and return memory
function ClearGlobals()
	units_by_oldid, props, transports = {}, {}, {}
end

-- Retreives newly created units using the id they had when they were saved
function GetUnitFromOldId( old_id )
	return unpack(units_by_oldid[old_id])
end

-- Retrieves the x,y,z coords of a unit using its old id
function GetPosFromOldId( old_id )
	local data = units_by_oldid[old_id][2]
	return Vector(data[2], data[3], data[4])
end

-- Save data for map/scenario
function SaveScenario()
	return {}
end

--[[
This function returns a lightweight table of the entities' data suitable for recreating its most important properties
]]
function GetEntityData(bpid, army, e)
	LOG("Call to GetEntityData")
	-- Safe 
	local id = safecall('SAVE: Bad entity', e.GetEntityId, e)
	if not id then return end

	-- Positional information
	local x, y, z = unpack( e:GetPosition() )
	local heading = e:GetHeading()* 180/math.pi
	local data = {tonumber(id), x, y, z, heading}
	
	-- Get unit data for fields: layer,health,xp,fire_state,state,focus
	if IsUnit(e) then

		local layer = GetLayerId( e:GetCurrentLayer() )		 -- unit layer (air,land,sea,sub,etc)
		local health = e:GetHealth() 
		local xp = e.VeteranLevel
		local fire_state = e:GetFireState()
		local state = 0  -- state (what the unit is doing)
		local focus = 0  -- focus (entity we are helping, attacking or following or location we move towards)
		local misc = {}  -- data specific to special units and circumstances	
		
		-- We now check for state/focus/misc values for units in special states
		-- check if paused
		if e:IsPaused() then
			misc.paused=1
		end
		-- get factory data
		if EntityCategoryContains(categories.FACTORY, e) then
			misc.rally = e:GetRallyPoint()
		end
		-- get stored missiles
		if EntityCategoryContains(categories.NUKE, e) then
			local nukeammo = e:GetNukeSiloAmmoCount()
			if nukeammo > 0 then
				misc.nukeammo = nukeammo
			end
		end
		if EntityCategoryContains(categories.ANTIMISSILE*categories.SILO, e) then
			local defammo = e:GetTacticalSiloAmmoCount()
			if defammo > 0 then
				misc.tacammo = defammo
			end
		end
		if EntityCategoryContains(categories.TACTICALMISSILEPLATFORM, e) then
			local tacammo = e:GetTacticalSiloAmmoCount()
			if tacammo > 0 then
				misc.tacammo = tacammo
			end
		end
		-- get fuel
		if EntityCategoryContains(categories.AIR*categories.MOBILE, e) then
			misc.fuel = e:GetFuelRatio()
		end

		if EntityCategoryContains(categories.SHIELD, e) then
			misc.shield = e:GetShieldRatio(true)
		end
		
		local enhCount=0
		if e:GetBlueprint().Enhancements then
			misc.enhancements = {}
			for k, v in  e:GetBlueprint().Enhancements do
				if e:HasEnhancement(k) then
					misc.enhancements[enhCount] = k
					enhCount = enhCount +1
				end
			end
		end
		
		-- get information on what the unit is currently doing
		-- order is important because for simplicity we only allow one state per unit
		if e:IsDead() then
			-- Ignore deadites
		elseif e:IsUnitState('Enhancing') then
			state = GetStateId('Enhancing')
			-- CommandData is stored put here by custom ScriptTask.OnCreate inside: hook\lua\sim\tasks\EnhanceTask.lua
			misc.nextenhancement = e.commandData.Enhancement 
			misc.progress = e:GetWorkProgress()

		elseif e:IsUnitState('SiloBuildingAmmo') then
			LOG("Saving state - building missile for " .. id)
			state = GetStateId('SiloBuildingAmmo')
			--focus = e:GetFocusUnit().GetEntityId()
			LOG(e:GetTrueMissileProgress())
			misc.progress = e:GetTrueMissileProgress()
			
		elseif e:IsUnitState('Upgrading') then
			state = GetStateId('Upgrading')
			focus = e.UnitBeingBuilt:GetEntityId()

			misc.upgradeBlueprintID = e.UnitBeingBuilt.Blueprint.BlueprintId
			misc.buildHealth = e.UnitBeingBuilt:GetHealth()

		elseif e:IsUnitState('Guarding') then
			local guarding = e:GetGuardedUnit()
			if guarding then
				--LOG('guarding '..DumpUnit(guarding))
				state = GetStateId('Guarding')
				focus = guarding:GetEntityId()
			end
			
		elseif e:IsUnitState('Building') then
			local building = e.UnitBeingBuilt
			if building then
				--LOG('building '..DumpUnit(building))
				state = GetStateId('Building')
				focus = building:GetEntityId()
				misc.upgradeBlueprintID = e.UnitBeingBuilt.Blueprint.BlueprintId
				misc.buildHealth = building:GetHealth()
			end
			
		elseif e:IsUnitState('BeingBuilt') then
			--local builder = e:GetParent()
			--if builder then
				--LOG('built by '..DumpUnit(builder))
			state = GetStateId('BeingBuilt')
			
				--focus = builder:GetEntityId()
			--end
			
		elseif e:IsUnitState('Attached') then
			local parent = e:GetParent()
			if parent then
				state = GetStateId('Attached')
				focus = parent:GetEntityId()
			end
			
		elseif e:IsUnitState('Patrolling') then
			local nav = e:GetNavigator()
			if nav then
				state = GetStateId('Patrolling')
				focus = nav:GetGoalPos()
			end
			
		elseif e:IsUnitState('Repairing') then
			local repairee = e:GetFocusUnit()
			if repairee then
				--LOG('repairee '..DumpUnit(repairee))
				state = GetStateId('Repairing')
				focus = repairee:GetEntityId()
			end
			
		elseif e:IsUnitState('Attacking') then
			local target = e:GetTargetEntity()
			if target then
				--LOG('target '..DumpUnit(target))
				state = GetStateId('Attacking')
				focus = target:GetEntityId()
			end
			
		elseif e:IsUnitState('Moving') then
			local nav = e:GetNavigator()
			if nav then
				state = GetStateId('Moving')
				focus = nav:GetGoalPos()
			end
		else 
		end
		-- join entity and unit data

		-- Add some fallback values to prevent deserialization issues
		if xp == nil then
			LOG("MultiplayerSave DEBUG: WARNING: GetVeteranLevel returned nil, fallback used: 0")
			xp = 0
		else
			LOG("GREAT NEWS, XP WAS NOT NILL")
		end
		if fire_state == nil then
			LOG("MultiplayerSave DEBUG: WARNING: GetFireState returned nil, fallback used: 0")
			fire_state = 0
		end		
		if state == nil then
			LOG("MultiplayerSave DEBUG: WARNING: STATE returned nil, fallback used: 0")
			state = 0
		end		
		if focus == nil then
			LOG("MultiplayerSave DEBUG: WARNING: focus returned nil, fallback used: 0")
			focus = 0
		end	

		-- add optional data and join
		data = table.join(data,{layer,health,xp,fire_state,state,focus})

		if not table.empty(misc) then
			table.insert(data,misc)
		end
		
		LOG("MultiplayerSave DEBUG: UNITDATA TO BE SAVED: " .. table.serialise( data ) )

		-- log
		if state ~= 0 then
			--LOG("Command Q")
			--LOG(repr(e:PrintCommandQueue(),1,1))
		end
	end
	-- end unit data
	return data
end

function GetAllEntities()
	-- get data for all entities on the map
	local map_w, map_h = unpack(ScenarioInfo.size)
	return GetEntitiesInRect( 0, 0, map_w, map_h )
end

--[[
This is one of the main multiplayer save functions. Its job is gather as much data as possible on entities in the game so they can be recreated later. Not all data can be stored as it is either locked into the game engine or can't be recreated or isn't worth the effort.
]]
function SaveEntities() 
	-- get data for all entities on the map
	local entities = GetAllEntities()
	LOG('SAVE/LOAD: '..table.getn(entities)..' entities found.')
	local store = {}
	local errors = 0

	local entityIDsGrabbed = {}
	local focusIDsGrabbed = {}
	for _,e in entities do
		
		-- ignore landscaping
		if IsUnit(e) then
			
			local army = e:GetArmy()                   -- army index
			local bpid = e:GetBlueprint().BlueprintId  -- get entity type 

			local data = safecall('SAVE: Saving Entity '..bpid, GetEntityData, bpid, army, e)

			if data then
				-- Add entity data to its place in the data tree
				-- organising the tree this way makes it smaller
				store[bpid] = store[bpid] or {}
				store[bpid][army] = store[bpid][army] or {}
				table.insert(store[bpid][army], data)
				
			else
				errors = errors + 1
			end
		end
	end

	LOG('SAVE: All Entities saved')
	LOG('There were ' .. errors .. ' errors in entity save' )
	return store
end

-- Removes all entities except environment from the game
function ClearAllEntities( )
	-- get data for all entities on the map
	local entities = GetAllEntities()
	for _,e in entities do
		-- type of entity
		if IsUnit(e) or IsProp(e) then
		--local bpid = e:GetBlueprint().BlueprintId		
		-- ignore landscaping
			-- trash the unit
			e:Destroy()
		end
	end
end

-- Create an entity using save data
function CreateProp( bpid, army, ent_data )
	--LOG('LOAD: Creating '..bpid..' for army '..army)
	-- get variables from table
	local id,x,y,z,heading = unpack(ent_data)
	-- Create the entity with the correct position and heading
	local e = CreatePropHPR(bpid, x, y, z, heading, 0, 0)
	-- rotate to correct heading
	--e:SetOrientation(heading, true) -- orientation, immediately
	-- map its old id to its new object for restoring orders
	props[id] = {e, ent_data}
end


local partiallyCompleteBuldings = {}
-- Create a unit using save data
function CreateUnit( bpid, army, ent_data )
	LOG('CreateUnit: Creating '..bpid..' for army '..army)

	-- get variables from table
	local old_id,x,y,z,heading,layer,health,xp,fire_state,state,focus,misc = unpack(ent_data)
	-- move units built by factories out of the way so the factory doesn't sit on them
	-- create the entity with the correct position and heading (in degrees around y)
	local e = CreateUnit2(bpid, tonumber(army), GetLayerName(layer), x, z, heading)
	-- rotate to correct roll, pitch and yaw
	--e:SetOrientation(heading, true) -- orientation, immediately
	-- map unit to its old id for restoring orders
	units_by_oldid[old_id] = {e, ent_data}

	if state == GetStateId('BeingBuilt') then
		if EntityCategoryContains(categories.STRUCTURE, e) or EntityCategoryContains(categories.EXPERIMENTAL,e)  then
			
			LOG("Recreating partially built building.")

			-- Work around: Game api doesn't allow us to create a partially created unit, or put a built unit back into an incomplete state.
			-- We create an invisible engineer which create our building, set progress, and then kills itself
			
			local faction = e.Blueprint.General.FactionName		
			e:Destroy() -- Destroy our original partially built building.
			
			local fakeEngineerBpID = ""
			if faction == 'UEF' then
				fakeEngineerBpID = 'UEL0309'
			elseif faction == 'Cybran' then
				fakeEngineerBpID = 'URL0309'
			elseif faction == 'Aeon' then
				fakeEngineerBpID = 'UAL0309'
			elseif faction == 'Seraphim' then
				fakeEngineerBpID = 'XSL0309'
			elseif faction == 'Nomad' then
				LOG("This unit is Nomads")
				WARN("Nomads, ne faction: " .. repr(faction))
			else
				WARN("Unknown faction: " .. repr(faction))
			end
			tempbuilder = CreateUnit2(fakeEngineerBpID, tonumber(army), GetLayerName(layer), x+5, z+5, heading)
			IssueBuildMobile({tempbuilder}, {x,y,z}, bpid, {})
			
			tempbuilder:ForkThread(tempbuilder.ManageTempEngineer, health)
		else
			LOG("Destroying unit being built. The parent factory will recreate this unit and set progress.")
			e:Destroy()
		end
	end
end

-- Creates entities using save data
function CreateEntities( entity_data ) 
	-- loop over blueprints

	LOG('LOAD: Creating all entities')
	for bpid, army_list in entity_data do
		-- loop over armies using this bp
		for army, ent_list in army_list do
			-- loop over instances of this bp in this army 
			for _, ent_data in ent_list do
				-- convert number id back to string
				ent_data[1] = tostring(ent_data[1])
				-- create prop (trees, rocks, etc..) or unit
				if army == -1 or string.sub(bpid,1,7) == '/props/' then
					-- A prop
					safecall( 'Error when creating prop: '..bpid..' data: '..repr(ent_data), CreateProp, bpid, army, ent_data )
				else
					-- A unit
					safecall( 'Error when creating unit: '..bpid..' data: '..repr(ent_data), CreateUnit, bpid, army, ent_data  )
				end
			end
		end
	end
	LOG('LOAD: Entities created')
end

function RestoreUnitState( old_id, unit_and_data ) 
	
	-- details of unit
	local unit, unit_data = unpack(unit_and_data)
	local id,x,y,z,heading,layer,health,xp,fire_state,state_id,focus,misc = unpack(unit_data)
	local new_id = unit:GetEntityId()
	local unit_bpid = unit:GetBlueprint().BlueprintId
	local unit_label = unit_bpid..' '..old_id..' (now '..new_id..')'
	unit.unitLabel = unit_label
	-- LOG("RestoreUnitState: " .. repr(unit_data))
	
	-- restore its health
	unit:SetHealth(unit, math.min(health, unit:GetMaxHealth()))
	unit:SetVeterancy(xp)
	unit:SetFireState(fire_state)

	-- restore fuel
	if misc.fuel then
		unit:SetFuelRatio(misc.fuel)
	end
	-- restore toggles
	if misc.paused then
		unit:SetPaused(true)
	end
	-- restore rally points
	if misc.rally then
		IssueFactoryRallyPoint({unit}, misc.rally)
	end
	-- restore silo ammo
	if misc.nukeammo then
		unit:GiveNukeSiloAmmo(misc.nukeammo)
	end
	if misc.tacammo then
		unit:GiveTacticalSiloAmmo(misc.tacammo)
	end

	if misc.shield then
		unit:SetShieldRatio(misc.shield)
	end
	
	if misc.enhancements then
		for k, v in misc.enhancements do
			unit:CreateEnhancement(v)
		end
	end
	

	--
	-- if EntityCategoryContains(categories.FACTORY, unit) then
	-- 	-- This unit is a factory
	-- 	-- unit:OnRecreateFromRestore(unit, layer)
	-- 	-- safecall("calling OnRecreateFromRestore ", unit:OnRecreateFromRestore(unit, layer))
	-- end

	--LOG('state_id:',repr(state_id),repr(unit_data))
	if state_id ~= 0 then
		local state = GetStateName( state_id )

		-- details of focus unit (the target,guard,builder,etc..)
		--LOG('focus: '..tostring(focus)..' ('..type(focus)..')')
		local focus_unit, focus_data, focus_new_id, focus_unit_bpid, focus_label = nil
		
		if type(focus) == 'table' then
			-- focus is a location {x,y,z}
			--LOG( 'LOAD: '..unit_label..' focused on '..repr(focus) )
		elseif focus ~= 0 then
			-- focus is either the unit we are focusing on (e.g. assisting), or a location (e.g. moving towards)?
			LOG("this is the focus: " .. repr(focus))  -- Focus represents the unit we are helping/building/assisting

			-- TODO: Interestingly, if a unit is upgrading, focus refers to a new EntityID which is not saved by our save script. 
			-- This is the entityID of the new unit which will take its place!
			-- We must make this code robust under those circumstances.
	  		--	focus_unit, focus_data = GetUnitFromOldId( focus )
			if units_by_oldid[old_id] then
				focus_unit, focus_data = unpack(units_by_oldid[old_id])

				focus_new_id = focus_unit:GetEntityId()
				focus_unit_bpid = focus_unit:GetBlueprint().BlueprintId
				focus_label = focus_unit_bpid..' '..focus..' (now '..new_id..')'
			else
				LOG("Warning, did not focus target entity. Probably an upgrade. focus_new_id & focus_unit_bpid & focus_label empty.")

				focus_new_id = ""
				focus_unit_bpid = ""
				focus_label = ""
			end
		end
		
		-- ENHANCING: Restore progress on enhancements
		if state == 'Enhancing' then
			LOG( 'LOAD: '..unit_label..' is enhancing with '..repr(misc.nextenhancement) )
			-- store progress in the unit so the ScriptTask can use it
			IssueScript({unit}, {TaskName="EnhanceTask", Enhancement=misc.nextenhancement, Progress=misc.progress}) -- units, script-- units, script..  misc.nextenhancement

			LOG("back here")
			LOG(misc.progress)


		-- BUILDING MISSILES: Restore progress on nukes and tactical missiles
		elseif state == 'SiloBuildingAmmo' then
			LOG( 'LOAD: '..unit_label..' is building missiles' )
			unit.missileProgress = misc.progress
			if EntityCategoryContains(categories.NUKE, unit) then
				IssueSiloBuildNuke({unit})
			else
				IssueSiloBuildTactical({unit})
			end
			
		-- UPGRADING: Restore upgrade state
		elseif state == 'Upgrading' then
			focus_unit_bpid = misc.upgradeBlueprintID

			LOG("RESTORING UPGRADING STATE")
			if EntityCategoryContains(categories.FACTORY, focus_unit) then
				LOG( 'LOAD KAA: Factory '..unit_label..' is upgrading to '..focus_label )
				-- focusHealth will be used by Unit.OnStartBuild  to restore the original progress 
				unit.focusHealth = misc.buildHealth
				unit.focusLabel = focus_label
				
				-- THIS DOES IN FACT TRIGGER THE UPGRADE, BUT FOR WHATEVER REASON, THE UPGRADE HAS NO "TARGET"
				IssueUpgrade({unit}, focus_unit_bpid)
				
				LOG("END UPGRADE CALL")
				LOG(focus_unit_bpid)

			else
				LOG( 'LOAD KBB: '..unit_label..' is upgrading to '..focus_label )
				unit.focusHealth = misc.buildHealth
				unit.focusLabel = focus_label
				IssueUpgrade({unit}, focus_unit_bpid) -- units, blueprint
				
				LOG("END UPGRADE CALL")
				LOG(focus_unit_bpid)
			end
					
		
		-- BUILDING: Resume build
		elseif state == 'Building' then
			focus_unit_bpid = misc.upgradeBlueprintID
			LOG("Restoring the building state" )
			-- make sure parent is really a builder
			if EntityCategoryContains(categories.FACTORY, unit) then
				LOG( 'LOAD: Factory '..unit_label..' is building '..focus_label )

				unit.focusHealth = misc.buildHealth
				unit.focusLabel = focus_label
				IssueBuildFactory({unit}, focus_unit_bpid, 1) 

			elseif EntityCategoryContains(categories.CONSTRUCTION, unit) then
				local build_pos = GetPosFromOldId(focus)
				LOG('LOAD: IssueBuildMobile({unit}, ' .. repr(build_pos) .. ', ' .. repr(focus_unit_bpid))
				unit.focusHealth = misc.buildHealth
				unit.focusLabel = focus_label
				IssueBuildMobile({unit}, build_pos, focus_unit_bpid, {})
			end
		
		-- ATTACHED: Reattach transported units
		elseif state == 'Attached' then
			local parent = GetUnitFromOldId( focus )
			-- check parent is definitely a transport
			if EntityCategoryContains(categories.TRANSPORTATION, focus_unit) then
				--LOG( 'LOAD: Attaching '..unit_label..' to '..focus_label ) 
				-- Add both units to global transport list
				transports[focus_new_id] = transports[focus_new_id] or {}
				table.insert(transports[focus_new_id], unit)
			end

		-- GUARDING: Continue guard
		elseif state == 'Guarding' then
			--LOG( 'LOAD: '..unit_label..' guarding '..focus_label ) 
			IssueGuard({unit}, focus_unit) -- units, guarded unit
		
		-- REPAIRING: Continue repair
		elseif state == 'Repairing' then
			--LOG( 'LOAD: '..unit_label..' repairing '..focus_label ) 
			IssueRepair({unit}, focus_unit) -- units, unit being repaired
		
		-- ATTACKING: Restart attacks
		elseif state == 'Attacking' then
			--LOG( 'LOAD: '..unit_label..' attacking '..focus_label ) 
			IssueAttack({unit}, focus_unit) -- attackers, target

		-- PATROL: Continue patrol
		-- TODO: Find out how to get all patrol points
		elseif state == 'Patrolling' then
			--LOG( 'LOAD: '..unit_label..' patrolling to '..repr(focus) ) 
			IssuePatrol({unit}, focus) -- units, location
			-- return to current position
			IssuePatrol({unit}, unit:GetPosition()) -- units, location
		
		-- MOVING: Continue move
		elseif state == 'Moving' then
			--LOG( 'LOAD: '..unit_label..' moving to '..repr(focus) ) 
			IssueMove({unit}, focus) -- units, location
		end

	end
end

-- Reattach units to a transport
function AttachTransportedUnits( transport_id, units_being_transported )
	for transport_id, units_being_transported in transports do
		--LOG( 'LOAD: Loading transport '..transport_id..' with '..table.getn(units)..' units' )
		ScenarioFramework.AttachUnitsToTransports(units_being_transported, {GetUnitById(transport_id)})
	end
end

-- Save army properties
function SaveArmy(army_name)		
	local army_data = {}
	local army = ScenarioInfo.ArmySetup[army_name]
	local brain = GetArmyBrain(army_name)
	army_data.index = brain:GetArmyIndex()
	-- economy
	army_data.mass = brain:GetEconomyStored( 'Mass' )
	army_data.energy = brain:GetEconomyStored( 'Energy' )
	--LOG(repr(army_data))
	return army_data
end

-- Save properties for all armies
function SaveArmies()
	local armies_data = {}
	for army_name in ListArmies() do
		armies_data[army_name] = safecall( 'Saving army '..army_name, SaveArmy, army_name )
	end
	return armies_data
end



-- Restore army properties
function RestoreArmy(army_name, army_data)
	local brain = GetArmyBrain(army_name)
	LOG("Setting mass " .. army_data.mass .. " energy: " .. army_data.energy)
	SetArmyEconomy( army_name, army_data.mass, army_data.energy )
	-- Seems to need to think about it
	-- ForkThread(function()
	-- 				while true do
	-- 					SetArmyEconomy(army_name, 0, 0)
	-- 					WaitTicks(3)
	-- 					LOG("Did it")
	-- 				end
	-- 			end)

	-- SetArmyEconomy( army_name, army_data.mass, army_data.energy )
	
	-- The below line might be needed to restart AI (it gets stuck on load)
	-- IF YOU UNCOMMENT THIS LINE, THE ENGY MOD WILL BREAK UNLESS FactoryManagerBrainComponent.lua is implemented
	-- M28AI seem to work fine without this line.
	-- InitializeArmyAI(army_name)
end

-- query data is passed from the User scope
function SaveGame( query_data )
	LOG('SAVE: Sim side of save running with options: '..repr(query_data))
	local save_data = query_data.Data or {}
	-- reset globals to prevent conflicts with previous saves
	ClearGlobals()
	-- save map/scenario details
	save_data.scenario_data = SaveScenario()
	-- save entities
	LOG('saving entities')
	save_data.entity_data = safecall( 'Saving entities '..repr(query_data), SaveEntities )
	LOG('entities saved')
	-- save army data
	save_data.armies_data = SaveArmies()
	-- Return compressed game data to UI side
	query_data.Data = table.serialise( save_data )
	Sync.SaveGameData = query_data
end


chunks = {}
		
function LoadGame_SendDataChunks(chunk)
	LOG('Chunkin')
	-- LOG(chunk)
	table.insert(chunks, chunk)
end


-- Complete loading process
-- save data is passed from the User scope
function LoadGame( query_data )
	--LOG('LOAD: Sim side of load running with options: '..repr(query_data)) -- warning large repr logging can crash FA entirely
	LOG('----------------------------------------------------------------------------------------------')
	LOG('LOAD: Sim side of load running.')
	-- LOG(query_data)

	local save_data = table.deserialise(table.concat(chunks))
	chunks = {}

	if save_data.entity_data then
		-- Now we need to replace all entities (except environment) with saved ones
		LOG('LOAD: Clearing entities')
		ClearAllEntities()
		LOG('LOAD: Entities cleared')
		safecall( 'Restoring entities ', CreateEntities, save_data.entity_data )
		
		-- Reassign unit states / orders / focus
		for old_id, unit_and_data in units_by_oldid do
			LOG("Debug: " .. "resoring statee for " .. old_id )
			safecall( 'Restoring state for unit '..old_id..' data: ', RestoreUnitState, old_id, unit_and_data )
		end
		LOG('LOAD: Units reassigned')
		-- Reattach transported units
		for transport_id, units_being_transported in transports do
			safecall( 'Attaching units to transport '..transport_id, 
				AttachTransportedUnits, transport_id, units_being_transported )
		end
	else
		error('LOAD: No entities in save data')
	end
	-- Restore army data
	if save_data.armies_data then
		for army_name, army_data in save_data.armies_data do
			LOG('LOAD: Restoring army '..army_name)
			safecall( 'Restoring army '..army_name, 
				RestoreArmy, army_name, army_data )
		end
	else
		error('LOAD: No armies in save data')	
	end
	-- give back memory
	ClearGlobals()
	LOG("----------------------  COMPLETED ENTIRE LOAD ------------------------")
	return true
end

-- test load and save
function Test( )
	local function SaveReloadThread()
		-- store the data
		SaveGame( )
		-- wait
		WaitSeconds(20)
		-- restore the save game
		LoadGame( )
	end
	ForkThread(SaveReloadThread)
end

-- Add query listeners. These return values to the User scope when a query is sent.
-- Using sim callbacks currently
--SimQuery.AddQueryListener( 'SaveGame', SaveGame )
--SimQuery.AddQueryListener( 'LoadGame', LoadGame )
