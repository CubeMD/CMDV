oldAIBrain = AIBrain
AIBrain = Class(oldAIBrain) {
    AddConsumption = function( self, locationType, consumptionType, unit, unitBeingBuilt )

        local consumptionData = self.BuilderManagers[locationType].MassConsumption

        local bp = unitBeingBuilt:GetBlueprint()
        local consumptionDrain = (unit:GetBuildRate() / bp.Economy.BuildTime) * bp.Economy.BuildCostMass

        consumptionData[consumptionType].Drain = consumptionData[consumptionType].Drain + consumptionDrain
        consumptionData.TotalDrain = consumptionData.TotalDrain + consumptionDrain

        unit.ConsumptionData = {
            ConsumptionType = consumptionType,
            ConsumptionDrain = consumptionDrain,
        }

        if self.BrainType == 'Human' then
		LOG('AddConsumption( '..locationType..', '..consumptionType..' )')
		LOG(repr(unit.ConsumptionData))
	end
	
        table.insert( consumptionData[consumptionType].Units, unit )
    end,
}