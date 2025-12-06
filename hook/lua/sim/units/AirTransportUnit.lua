AirTransport.Kill = function(self, instigator, damageType, excessDamageRatio)
    if damageType ~= "TransportDamage" then
        if self ~= nil and IsDestroyed(self) == false and IsUnit(self) then
            local cargo = self:GetCargo()
            for _, unit in cargo do
                if unit ~= nil and IsDestroyed(unit) == false and IsUnit(unit) then
                    unit:DetachFrom()
                    unit:OnDetachedFromTransport()
                end
            end
        end
    end

    damageType = damageType or "Normal"
    excessDamageRatio =  excessDamageRatio or 0
    AirUnitKill(self, instigator, damageType, excessDamageRatio)
end

AirTransport.DoTakeDamage = function(self, instigator, amount, vector, damageType)
    -- VeterancyComponent.DoTakeDamage(self, instigator, amount, vector, damageType)

    local preAdjHealth = self:GetHealth()

    if preAdjHealth - amount < 1 then
        local cargo = self:GetCargo()
        for _, unit in cargo do
            if unit ~= nil and IsDestroyed(unit) == false and IsUnit(unit) then
                unit:DetachFrom()
                unit:OnDetachedFromTransport()
            end
        end
    end

    self:AdjustHealth(instigator, -amount)

    local health = self:GetHealth()
    if health < 1 then
        -- this if statement is an issue too
        if damageType == 'Reclaimed' then
            self:Destroy()
        else
            local excessDamageRatio = 0.0
            -- Calculate the excess damage amount
            local excess = preAdjHealth - amount
            local maxHealth = self:GetMaxHealth()
            if excess < 0 and maxHealth > 0 then
                excessDamageRatio = -excess / maxHealth
            end

            if not EntityCategoryContains(categories.VOLATILE, self) then
                self:SetReclaimable(false)
            end

            self:Kill(instigator, damageType, excessDamageRatio)
        end
    end
end