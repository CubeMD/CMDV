--- Called when the unit is killed, but before it falls out of the sky and blows up.
---@param self AirUnit
---@param instigator Unit
---@param type string
---@param overkillRatio number
AirUnit.OnKilled = function(self, instigator, type, overkillRatio)
    -- A completed, flying plane expects an OnImpact event due to air crash.
    -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
    -- stupid check.

    -- Additional stupidity: An idle transport, bot loaded and unloaded, counts as 'Land' layer so it would die with the wreck hovering.
    -- It also wouldn't call this code, and hence the cargo destruction. Awful!
    if self:GetFractionComplete() == 1 and
        (self.Layer == 'Air' or EntityCategoryContains(categories.TRANSPORTATION, self))
    then
        self.Dead = true
        -- We want to skip all the visual/audio/shield bounce/death weapon stuff if we're in internal storage
        if type ~= "TransportDamage" then
            self:CreateUnitAirDestructionEffects(1.0)
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            self:DisableShield()

            -- Store our death weapon's damage on the unit so it can be edited remotely by the shield bouncer projectile
            local bp = self.Blueprint
            local i = 1
            for i, numweapons in bp.Weapon do
                if bp.Weapon[i].Label == 'DeathImpact' then
                    self.deathWep = bp.Weapon[i]
                    break
                end
            end

            if not self.deathWep or self.deathWep == {} then
                WARN(string.format('(%s) has no death weapon or the death weapon has an incorrect label!',
                    tostring(bp.BlueprintId)))
            else
                self.DeathCrashDamage = self.deathWep.Damage
            end

            -- Create a projectile we'll use to interact with Shields
            local proj = self:CreateProjectileAtBone('/projectiles/ShieldCollider/ShieldCollider_proj.bp', 0)
            self.colliderProj = proj
            proj:Start(self, 0)
            self.Trash:Add(proj)
        end

        self:VeterancyDispersal()

        local army = self.Army
        -- awareness for traitor game mode and game statistics
        ArmyBrains[army].LastUnitKilledBy = (instigator or self).Army
        ArmyBrains[army]:AddUnitStat(self.UnitId, "lost", 1)

        -- awareness of instigator that it killed a unit, but it can also be a projectile or nil
        if instigator and instigator.OnKilledUnit then
            instigator:OnKilledUnit(self)
        end

        self.Brain:OnUnitKilled(self, instigator, type, overkillRatio)

        -- If we're in internal storage, we're done, destroy the unit to avoid OnImpact errors
        if type == "TransportDamage" then
            self:Destroy()
        end
    else
        MobileUnitOnKilled(self, instigator, type, overkillRatio)
    end
end

--- Called when a unit collides with a projectile to check if the collision is valid, allows
-- ASF to be destroyed when they impact with strategic missiles
---@param self AirUnit # The unit we're checking the collision for
---@param other Projectile # other The projectile we're checking the collision with
---@param firingWeapon Weapon # The weapon that the projectile originates from
---@return boolean
AirUnit.OnCollisionCheck = function(self, other, firingWeapon)
    if self.DisallowCollisions then
        return false
    end

    local selfBlueprintCategoriesHashed = self.Blueprint.CategoriesHash
    local otherBlueprintCategoriesHashed = other.Blueprint.CategoriesHash

    -- allow regular air units to be killed by the projectiles of SMDs and SMLs
    -- prevent falling satellites from blocking projectiles of SMDs and SMLs
    if otherBlueprintCategoriesHashed["KILLAIRONCOLLISION"] then
        if not selfBlueprintCategoriesHashed["EXPERIMENTAL"] or selfBlueprintCategoriesHashed["SATELLITE"] and self.Dead then
            self:Kill()
            return false
        end
    end

    -- disallow ASF to intercept certain projectiles
    if otherBlueprintCategoriesHashed["IGNOREASFONCOLLISION"] and selfBlueprintCategoriesHashed["ASF"] then
        return false
    end

    return MobileUnitOnCollisionCheck(self, other, firingWeapon)
end

    -- Planes need to crash. Called by engine or by ShieldCollider projectile on collision with ground or water
---@param self AirUnit
---@param with string
AirUnit.OnImpact = function(self, with)

    LOG("asdasdasdasdasdasdasd")

    if self.GroundImpacted then return end

    -- Only call this code once
    self.GroundImpacted = true

    -- Damage the area we hit. For damage, use the value which may have been adjusted by a shield impact
    if not self.deathWep or not self.DeathCrashDamage then -- Bail if stuff is missing
        WARN('defaultunits.lua OnImpact: did not find a deathWep on the plane! Is the weapon defined in the blueprint? '
            .. self.UnitId)
    elseif self.DeathCrashDamage > 0 then -- It was completely absorbed by a shield!
        local deathWep = self.deathWep -- Use a local copy for speed and easy reading
        DamageArea(self, self:GetPosition(), deathWep.DamageRadius, self.DeathCrashDamage, deathWep.DamageType,
            deathWep.DamageFriendly)
        DamageArea(self, self:GetPosition(), deathWep.DamageRadius, 1, 'TreeForce', false)
    end

    if with == 'Water' then
        self:PlayUnitSound('AirUnitWaterImpact')
        EffectUtil.CreateEffectsOpti(self, self.Army, EffectTemplate.DefaultProjectileWaterImpact)
        self.shallSink = true
        self.colliderProj:Destroy()
        self.colliderProj = nil
    end

    self:DisableUnitIntel('Killed')
    self:DisableIntel('Vision') -- Disable vision seperately, it's not handled in DisableUnitIntel
    self:ForkThread(self.DeathThread, self.OverKillRatio)
end