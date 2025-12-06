EnergyManagerBrainComponent.OnEnergyTrigger = function(self, triggerName)
    if triggerName == "EnergyDepleted" then
        -- add trigger when we can recover units
        self:SetArmyStatsTrigger('Economy_Ratio_Energy', 'EnergyViable', 'GreaterThanOrEqual', 0.0000001)
        self.EnergyDepleted = true

        -- recurse over the list of units and do callbacks accordingly
        for id, entity in self.EnergyDependingUnits do
            if not IsDestroyed(entity) then
                entity:OnEnergyDepleted()
            end
        end
    else
        -- add trigger when we're depleted
        self:SetArmyStatsTrigger('Economy_Ratio_Energy', 'EnergyDepleted', 'LessThanOrEqual', 0.0)
        self.EnergyDepleted = false

        -- recurse over the list of units and do callbacks accordingly
        for id, entity in self.EnergyDependingUnits do
            if not IsDestroyed(entity) then
                entity:OnEnergyViable()
            end
        end
    end
end