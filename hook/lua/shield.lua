-- Override GetOverlappingShields to prevent sharing of damage between nearby shields.
Shield.GetOverlappingShields = function(self, tick)
    -- Return an empty list of overlapping shields and count 0, effectively disabling shield overlap logic.
    return {}, 0
end

-- Override ApplyDamage to skip the overspill damage application to other shields.
Shield.ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
    -- cache information used throughout the function
    local tick = GetGameTick()

    -- damage correction for overcharge
    if dmgType == 'Overcharge' then
        local wep = instigator:GetWeaponByLabel('OverCharge')
        if self.StaticShield then
            amount = wep:GetBlueprint().Overcharge.structureDamage / 2
        elseif self.CommandShield then
            amount = wep:GetBlueprint().Overcharge.commandDamage / 2
        end
    end

    -- damage correction for overspill, skip overspill logic
    if self.ShieldType ~= "Personal" then
        local instigatorId = (instigator and instigator.EntityId) or false
        if instigatorId then
            if self.DamagedTick[instigatorId] ~= tick then
                self.DamagedTick[instigatorId] = tick
                self.DamagedRegular[instigatorId] = false
                self.DamagedOverspill[instigatorId] = 0
            end
            if dmgType ~= "ShieldSpill" then
                self.DamagedRegular[instigatorId] = tick
                amount = amount - self.DamagedOverspill[instigatorId]
                self.DamagedOverspill[instigatorId] = 0
            else
                if self.DamagedRegular[instigatorId] == tick then
                    return
                end
                self.DamagedOverspill[instigatorId] = self.DamagedOverspill[instigatorId] + amount
            end
        end
    end

    -- do damage logic for shield
    if self.Owner ~= instigator then
        local absorbed = self:OnGetDamageAbsorption(instigator, amount, dmgType)
        EntityAdjustHealth(self, instigator, -absorbed)

        -- check to spawn impact effect
        local r = Random(1, self.Size)
        if dmgType ~= "ShieldSpill"
            and not (self.LiveImpactEntities > 10
                and (r >= 0.2 * self.Size and r < self.LiveImpactEntities))
        then
            ForkThread(self.CreateImpactEffect, self, vector)
        end

        -- if we have no health, collapse
        if EntityGetHealth(self) <= 0 then
            ChangeState(self, self.DamageDrainedState)
        else
            self.RegenThreadStartTick = tick + 10 * self.RegenStartTime
            if self.RegenThreadSuspended then
                ResumeThread(self.RegenThread)
            end
        end
    end

    -- Skip overspill damage application
end

Shield.OnCollisionCheck = function(self, other)

    -- special logic when it is a projectile to simulate air crashes
    if other.CrashingAirplaneShieldCollisionLogic then
        if other.ShieldImpacted then
            return false
        else
            if other and not EntityBeenDestroyed(other) then
                other:OnImpact('Shield', self)
                return false
            end
        end
    end

    -- special behavior for projectiles that always collide with
    -- shields, like the seraphim storm when the Ythotha dies
    if other.CollideFriendlyShield then
        return true
    end

    if -- our projectiles do not collide with our shields
    self.Army == other.Army
        -- neutral projectiles do not collide with any shields
        or other.Army == -1
    then
        return false
    end

    -- special behavior for projectiles that represent strategic missiles
    -- local otherHashedCats = other.Blueprint.CategoriesHash
    -- if otherHashedCats['STRATEGIC'] and otherHashedCats['MISSILE'] then
    --     return false
    -- end

    -- otherwise, only collide if we're hostile to the other army
    return IsEnemy(self.Army, other.Army)
end