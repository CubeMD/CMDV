local ForkThread = ForkThread
local CoroutineYield = coroutine.yield

local OrigMassFabricationUnit = MassFabricationUnit
MassFabricationUnit = ClassUnit(OrigMassFabricationUnit) {
    Attraction = false,

    OnConsumptionActive = function(self)
        StructureUnitOnConsumptionActive(self)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
        self:ApplyAdjacencyBuffs()
        self.ConsumptionActive = true

        if self.Attraction == false then
            self.Attraction = true
            ForkThread(self.Attract, self)
        end
    end,

    ---@param self MassFabricationUnit
    OnConsumptionInActive = function(self)
        StructureUnitOnConsumptionInActive(self)
        self:SetMaintenanceConsumptionInactive()
        self:SetProductionActive(false)
        self:RemoveAdjacencyBuffs()
        self.ConsumptionActive = false

        self.Attraction = false
    end,

    Attract = function(self)
        local CoroutineYield = CoroutineYield

        local prodMassSec = math.sqrt(self:GetBlueprint().Economy.ProductionPerSecondMass * 5)
        local radMax = prodMassSec * 200
        local dmg = prodMassSec * 2
        local pos = self:GetPosition()

        while not IsDestroyed(self) and self.Attraction and self.ConsumptionActive do
            for k = 1, 20 do
                CoroutineYield(5)

                if not IsDestroyed(self) and self.Attraction and self.ConsumptionActive then
                    local rad = math.max(radMax / 20 * k, 0.002)
                    local radM = math.max(radMax / 20 * (k - 1), 0.0001)
                    DamageRing(self, pos, 10 + radM, 10 + rad, dmg, 'TreeForce', false, false)
                else
                    return
                end
            end
        end
    end
}