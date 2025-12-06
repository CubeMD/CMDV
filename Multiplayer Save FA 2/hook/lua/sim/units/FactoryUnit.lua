local OldFactoryUnit = FactoryUnit

FactoryUnit = Class(OldFactoryUnit) {

    -- This was originally in the base unit class, but that caused issues. Sets progress on unit being built.
    -- OnStartBuild = function(self, unitBeingBuilt, order)
    --     OldFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        
    --     LOG(repr(self.focusHealth))
    --     if self.focusHealth then         -- Restore progress on unit being built if passed in
    --         LOG('LOAD: Restoring health '..self.focusHealth..' to '..self.focusLabel)
    --         unitBeingBuilt:SetHealth(self, self.focusHealth)
    --         self.focusHealth = nil
    --     end
    -- end,
    

    GetStateString = function(self)
        -- Returns a comma-seperated list of current states or empty string if idle
		local name = nil
		for _,state in all_states do
			if self:IsUnitState(state) then
				if not name then
					name = state
				else
					name = name ..','.. state
				end
			end
		end
        LOG("GET STATE STRING: " .. name)
		return name or ''
	end,
}