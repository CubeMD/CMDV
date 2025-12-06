all_states = {	'Immobile',
	'Moving',
	'Attacking',
	'Guarding',
	'Building',
	'Upgrading',
	'WaitingForTransport',
	'TransportLoading',
	'TransportUnloading',
	'MovingDown',
	'MovingUp',
	'Patrolling',
	'Busy',
	'Attached',
	'BeingReclaimed',
	'Repairing',
	'Diving',
	'Surfacing',
	'Teleporting',
	'Ferrying',
	'WaitForFerry',
	'AssistMoving',
	'PathFinding',
	'ProblemGettingToGoal',
	'NeedToTerminateTask',
	'Capturing',
	'BeingCaptured',
	'Reclaiming',
	'AssistingCommander',
	'Refueling',
	'GuardBusy',
	'ForceSpeedThrough',
	'UnSelectable',
	'DoNotTarget',
	'LandingOnPlatform',
	'CannotFindPlaceToLand',
	'BeingUpgraded',
	'Enhancing',
	'BeingBuilt',
	'NoReclaim',
	'NoCost',
	'BlockCommandQueue',
	'MakingAttackRun',
	'HoldingPattern',
	'SiloBuildingAmmo',
}

lock_states = {
	'Moving',
	'Attacking',
	'Guarding',
	'Building',
	'WaitingForTransport',
	'TransportLoading',
	'TransportUnloading',
	'MovingDown',
	'MovingUp',
	'Patrolling',
	'BeingReclaimed',
	'Repairing',
	'Diving',
	'Surfacing',
	'Teleporting',
	'Ferrying',
	'WaitForFerry',
	'AssistMoving',
	'PathFinding',
	'Capturing',
	'Reclaiming',
	'AssistingCommander',
	'Refueling',
	'GuardBusy',
	'LandingOnPlatform',
	'CannotFindPlaceToLand',
	'Enhancing',
	'MakingAttackRun',
	'HoldingPattern'
}

debugAI = false

local baseUnit = Unit
Unit = Class(baseUnit) {

	OnCreate = function(self)
        baseUnit.OnCreate(self)
    end,

	SetCustomName = function(self, name)
		-- Set the unit name, not just its label
		self.name = name
		baseUnit.SetCustomName(self, name)
	end,

	SetCustomLabel = function(self, name)
		-- Set the unit label only
		baseUnit.SetCustomName(self, name)
	end,
	

	-- GetStateString = function(self)
	-- 	-- Returns a comma-seperated list of current states or empty string if idle
	-- 	local name = nil
	-- 	for _,state in all_states do
	-- 		if self:IsUnitState(state) then
	-- 			if not name then
	-- 				name = state
	-- 			else
	-- 				name = name ..','.. state
	-- 			end
	-- 		end
	-- 	end
	-- 	return name or ''
	-- end,
	

	-- These functions are work arounds for the fact the game API does not let us set the nuke progress. 
	-- We spawn a
	OnSiloBuildStart = function(self, weapon)
		LOG("OnSiloBuildStart has been called.")
		baseUnit.OnSiloBuildStart(self, weapon)
		-- Restore work progress when building units
		if self.missileProgress then
			LOG('LOAD: Restoring missile progress from ' .. self.missileProgress)
			self:ForkThread(self.RestoreMissileProgress, weapon)
		end
	end,

	GetTrueMissileProgress = function(self)
		if self.missileProgress then
			return self:GetWorkProgress() + self.missileProgress
		else
			return self:GetWorkProgress()
		end
	end,

	RestoreMissileProgress = function(self, weapon)
		-- WORKAROUND,  Background thread to create missle at the right time, then exit.
		-- The game engine does not have an API which allows us to set missile progress. 
		-- We can only GetWorkProgress but this resets to 0.0 after reload. 
		-- So add saved missile progress to GetWorkProgress() and incriment missile count after 100% complete.

		-- Wait for build to complete 
		local progress = self.missileProgress
		while self.missileProgress and self:IsUnitState('SiloBuildingAmmo') and (progress < 1.0) do
			progress = self:GetTrueMissileProgress()
			-- self:SetWorkProgress(progress) -- This doesn't seem to do anything. The progress gets overridden by the game engine every tick.
			self:SetCustomName("Silo actually has this progress: " .. math.round((progress*100),2) .. "%")
			WaitSeconds(0.1)
		end

		-- Missile complete
		if EntityCategoryContains(categories.NUKE, self) then
			LOG('LOAD: Saved partial nuke completed')
			self:GiveNukeSiloAmmo(1)
		else
			LOG('LOAD: Saved partial tactical missile completed')
			self:GiveTacticalSiloAmmo(1)
		end
		
		WaitSeconds(0.1)
		LOG('Silo build cancelled')
		self.missileProgress = nil
		self:SetCustomName("")
	end,


	ManageTempEngineer = function(self, buildHealth)
		-- Work around to create invisible engineer to restore build progress on a partially built building.
		self:SetCustomLabel("I am a fake builder hehe.")

		self:HideBone(0, true) -- Invisible
		self:SetBusy(true)  -- Uncontrolable 
		self:SetBlockCommandQueue(true) -- Uncontrolable

		local tickCount = 0
		while (not self:IsUnitState('Building')) or (not self:GetFocusUnit()) do
			WaitTicks(1)
			
			tickCount = tickCount + 1  -- Eventually give up and kill the engineer
			if (tickCount > 120) then
				self:Destroy()
				WARN("Failed to recreate partially built building")
			end
		end
		
		LOG("Fake engineer is creating partially built building.")
		local unitbeingbuilt = self:GetFocusUnit()
		unitbeingbuilt:SetHealth(nil, buildHealth)  -- Set progress on unit being built

		self:Destroy()  -- Kills the I am a fake builder unit
	end,
}