local OrigUnit = Unit

-- Local helper functions for physics vector math
local function GetVectorLength(v)
    return math.sqrt(math.pow(v.x, 2) + math.pow(v.y, 2) + math.pow(v.z, 2))
end

local function NormalizeVector(v)
    local length = GetVectorLength(v)
    if length > 0 then
        local invlength = 1 / length
        return Vector(v.x * invlength, v.y * invlength, v.z * invlength)
    else
        return Vector(0,0,0)
    end
end

local function GetDirectionVector(v1, v2)
    return NormalizeVector(Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z))
end

Unit = Class(OrigUnit) {

    OnCreate = function(self)
        OrigUnit.OnCreate(self)
        self:SetFireState(2)
    end,

    -- Same as default, except mass reduction
    CreateWreckageProp = function(self, overkillRatio)
        local bp = self.Blueprint

        local wreck = bp.Wreckage.Blueprint
        if not wreck then
            return nil
        end

        local mass, energy = self:GetTotalResourceCosts()
        mass = mass * (bp.Wreckage.MassMult or 0)
        energy = energy * (bp.Wreckage.EnergyMult or 0)
        local time = (bp.Wreckage.ReclaimTimeMultiplier or 1)
        local pos = self:GetPosition()
        local wasOutside = false
        local layer = self.Layer

        -- Create potentially offmap wrecks on-map. Exclude campaign maps that may do weird scripted things.
        if self.Brain.BrainType == 'Human' and (not ScenarioInfo.CampaignMode) then
            pos, wasOutside = GetNearestPlayablePoint(pos)
        end

        local halfBuilt = self:GetFractionComplete() < 1

        -- Make sure air / naval wrecks stick to ground / seabottom, unless they're in a factory.
        if not halfBuilt and (layer == 'Air' or EntityCategoryContains(categories.NAVAL - categories.STRUCTURE, self)) then
            pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        end

        local prop = Wreckage.CreateWreckage(bp, pos, self:GetOrientation(), mass, energy, time, self.DeathHitBox)
        --prop:AttachTo(self, -1)

        -- Attempt to copy our animation pose to the prop. Only works if
        -- the mesh and skeletons are the same, but will not produce an error if not.
        -- if not bp.Wreckage.UseCustomMesh and (self.Tractored or (layer ~= 'Air' or (layer == "Air" and halfBuilt))) then
        --     TryCopyPose(self, prop, not wasOutside)
        -- end

        -- Create some ambient wreckage smoke
        if layer == 'Land' then
            Explosion.CreateWreckageEffects(self, prop)
        end

        return prop
    end,

    UpdateBuildRestrictions = function(self)
        -- -- retrieve info of factory
        -- local faction = self.Blueprint.FactionCategory
        -- local layer = self.Blueprint.LayerCategory
        -- local aiBrain = self:GetAIBrain()

        -- -- the pessimists we are, remove all the units!
        -- self:AddBuildRestriction((categories.TECH3 + categories.TECH2))

        -- -- if there is a specific T3 HQ - allow all t2 / t3 units of this type
        -- if aiBrain:CountHQs(faction, layer, "TECH3") > 0 then 
        --     self:RemoveBuildRestriction((categories.TECH3 + categories.TECH2))

        -- -- if there is some T3 HQ - allow t2 / t3 engineers
        -- elseif aiBrain:CountHQsAllLayers(faction, "TECH3") > 0 then 
        --     self:RemoveBuildRestriction((categories.TECH3 + categories.TECH2) * categories.CONSTRUCTION)
        -- end 

        -- -- if there is a specific T2 HQ - allow all t2 units of this type
        -- if aiBrain:CountHQs(faction, layer, "TECH2") > 0 then 
        --     self:RemoveBuildRestriction(categories.TECH2)

        -- -- if there is some T2 HQ - allow t2 engineers
        -- elseif aiBrain:CountHQsAllLayers(faction, "TECH2") > 0 then 
        --     self:RemoveBuildRestriction(categories.TECH2 * categories.CONSTRUCTION)
        -- end
    end,

    OnAttachedToTransport = function(self, transport, bone)
        -- self:MarkWeaponsOnTransport(true)
        -- if self:ShieldIsOn() or self.MyShield.Charging then

        --     local shield = self.MyShield
        --     if shield and not (shield.SkipAttachmentCheck or shield.RemainEnabledWhenAttached) then
        --         self:DisableShield()
        --     end

        --     self:DisableDefaultToggleCaps()

        -- end
        self:DoUnitCallbacks('OnAttachedToTransport', transport, bone)

        -- for AI events
        self.Brain:OnUnitAttachedToTransport(self, transport, bone)
    end,

    OnDetachedFromTransport = function(self, transport, bone)
        self.Trash:Add(ForkThread(self.OnDetachedFromTransportThread, self, transport, bone))
        -- self:MarkWeaponsOnTransport(false)
        self:EnableShield()
        -- self:EnableDefaultToggleCaps()
        self:TransportAnimation(-1)
        self:DoUnitCallbacks('OnDetachedFromTransport', transport, bone)

        -- for AI events
        self.Brain:OnUnitDetachedFromTransport(self, transport, bone)
    end,

    OnDetachedFromTransportThread = function(self, transport, bone)
        -- if IsDestroyed(transport) then
        --     self:Destroy()
        -- end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        -- invulnerable little fella
        if not (self.CanBeKilled) then
            return
        end

        -- this flag is used to skip the need of `IsDestroyed`
        self.Dead = true

        local layer = self.Layer
        local bp = self.Blueprint
        local army = self.Army

        -- Skip all audio/visual/death threads/shields/etc. if we're in internal storage
        -- (presumably these should already have been removed when the unit entered storage)
        if type ~= "TransportDamage" then
            -- Units killed while being invisible because they're teleporting should show when they're killed
            if self.TeleportFx_IsInvisible then
                self:ShowBone(0, true)
                self:ShowEnhancementBones()
            end

            if layer == 'Water' and bp.Physics.MotionType == 'RULEUMT_Hover' then
                self:PlayUnitSound('HoverKilledOnWater')
            elseif layer == 'Land' and bp.Physics.MotionType == 'RULEUMT_AmphibiousFloating' then
                -- Handle ships that can walk on land
                self:PlayUnitSound('AmphibiousFloatingKilledOnLand')
            else
                self:PlayUnitSound('Killed')
            end

            -- apply death animation on half built units (do not apply for ML and mega)
            local FractionThreshold = bp.General.FractionThreshold or 0.5
            if self.PlayDeathAnimation and self:GetFractionComplete() > FractionThreshold then
                self:ForkThread(self.PlayAnimationThread, 'AnimationDeath')
                self.DisallowCollisions = true
            end

            self:DoUnitCallbacks('OnKilled')
            if self.UnitBeingTeleported and not self.UnitBeingTeleported.Dead then
                self.UnitBeingTeleported:Destroy()
                self.UnitBeingTeleported = nil
            end

            if self.DeathWeaponEnabled ~= false then
                self:DoDeathWeapon()
            end

            self:DisableShield()
            self:DisableUnitIntel('Killed')
            self:ForkThread(self.DeathThread, overkillRatio , instigator)
        end

        -- veterancy computations should happen after triggering death weapons
        VeterancyComponent.VeterancyDispersal(self)

        -- awareness for traitor game mode and game statistics
        ArmyBrains[army].LastUnitKilledBy = (instigator or self).Army
        ArmyBrains[army]:AddUnitStat(self.UnitId, "lost", 1)

        -- awareness of instigator that it killed a unit, but it can also be a projectile or nil
        if instigator and instigator.OnKilledUnit then
            instigator:OnKilledUnit(self)
        end

        self.Brain:OnUnitKilled(self, instigator, type, overkillRatio)

        -- If we're in internal storage, destroy the unit since DeathThread isn't played to destroy it
        -- if type == "TransportDamage" then
        --     self:Destroy()
        -- end
    end,

    CreateWreckage = function (self, overkillRatio)
        -- if overkillRatio and overkillRatio > 1.0 then
        --     return
        -- end
        local bp = self.Blueprint
        local fractionComplete = self:GetFractionComplete()
        if fractionComplete < 0.5 or ((bp.TechCategory == 'EXPERIMENTAL' or bp.CategoriesHash["STRUCTURE"]) and fractionComplete < 1) then
            return
        end
        return self:CreateWreckageProp(overkillRatio)
    end,

    DeathThread = function(self, overkillRatio, instigator)
        local isNaval = EntityCategoryContains(categories.NAVAL, self)
        local shallSink = self:ShallSink()
        WaitSeconds(utilities.GetRandomFloat(self.DestructionExplosionWaitDelayMin, self.DestructionExplosionWaitDelayMax))

        if not self.BagsDestroyed then
            self:DestroyAllBuildEffects()
            self:DestroyAllTrashBags()
            self.BagsDestroyed = true
        end

        -- Stop any motion sounds we may have
        self:StopUnitAmbientSound()

        -- BOOM!
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(overkillRatio)
        end

        -- Flying bits of metal and whatnot. More bits for more overkill.
        if self.ShowUnitDestructionDebris and overkillRatio then
            self:CreateUnitDestructionDebris(true, true, overkillRatio > 2)
        end

        if shallSink then
            self.DisallowCollisions = true

            -- Bubbles and stuff coming off the sinking wreck.
            self:ForkThread(self.SinkDestructionEffects)

            -- Avoid slightly ugly need to propagate this through callback hell...
            self.overkillRatio = overkillRatio

            if isNaval and self.Blueprint.Display.AnimationDeath then
                -- Waits for wreck to hit bottom or end of animation
                if self:GetFractionComplete() > 0.5 then
                    self:SeabedWatcher()
                else
                    self:DestroyUnit(overkillRatio)
                end
            else
                -- A non-naval unit or boat with no sinking animation dying over water needs to sink, but lacks an animation for it. Let's make one up.
                local this = self
                self:StartSinking(
                    function()
                        this:DestroyUnit(overkillRatio)
                    end
                )

                -- Wait for the sinking callback to actually destroy the unit.
                return
            end
        elseif self.DeathAnimManip then -- wait for non-sinking animations
            WaitFor(self.DeathAnimManip)
        end

        -- If we're not doing fancy sinking rubbish, just blow the damn thing up.
        self:DestroyUnit(overkillRatio)
    end,

    DestroyUnit = function(self, overkillRatio)
        self:CreateWreckage(overkillRatio or self.overkillRatio)

        -- wait at least 1 tick before destroying unit
        WaitSeconds(math.max(0.1, self.DeathThreadDestructionWaitTime))

        -- do not play sound after sinking
        if not self.Sinking then 
            self:PlayUnitSound('Destroyed')
        end

        self:Destroy()
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)

        -- ignore specific types
        if damageType == "TreeForce" or damageType == "TreeFire" or damageType == "FAF_AntiShield" then 
            return 
        end

        -- PHYSICS: "Creeper Fluid" behavior on damage
        -- If unit takes significant damage, it gets knocked around like a prop
        if self.CanTakeDamage and instigator and amount > 0 then
            
            -- Only trigger physics if we aren't already flying (prevent infinite recursion/stacking)
            if self.FluidPhysicsProj == nil or IsDestroyed(self.FluidPhysicsProj) then
                
                local unitPos = self:GetPosition()
                local instPos = instigator:GetPosition()

                -- Flatten positions to ignore height differences for impulse direction
                local flatUnit = {x=unitPos[1], y=unitPos[2], z=unitPos[3]}
                local flatInst = {x=instPos[1], y=instPos[2], z=instPos[3]}

                -- Calculate direction: away from source
                local dir = GetDirectionVector(flatUnit, flatInst)
                
                -- Calculate Impulse Force
                -- Logarithmic scaling for damage amount, inversely proportional to unit Mass
                -- Heavier units are harder to knock around
                local massCost = self:GetTotalMassCost() or 100
                local multM = math.log(amount, 2) + 1
                local mult = multM / math.max((math.sqrt(massCost) * 0.1), 1)

                -- Create physics carrier projectile
                local proj = self:CreateProjectile('/projectiles/TDFGauss01/TDFGauss01_proj.bp', 0, 0, 0, nil, nil, nil)
                self.FluidPhysicsProj = proj -- Save reference to prevent double-launch
                
                -- Configure Projectile
                proj:SetLifetime(10) -- Failsafe
                proj:SetVelocity(dir.x * mult * 2.5, multM * 2, dir.z * mult * 2.5) -- Add Y-lift
                proj:SetVelocityAlign(false)
                
                -- Attach Unit
                self:SetImmobile(true) -- Stop navigation while airborne
                self:AttachTo(proj, -1)
                
                -- Handle Impact/Landing
                local originalOrientation = self:GetOrientation()
                
                proj.OnImpact = function(p, targetType, targetEntity)
                    if not self:IsDead() then
                        self:DetachFrom()
                        -- Ensure unit lands on the ground properly
                        local finalPos = p:GetPosition()
                        local landHeight = GetTerrainHeight(finalPos[1], finalPos[3])
                        Warp(self, Vector(finalPos[1], landHeight, finalPos[3]))
                        
                        self:SetImmobile(false) -- Regain control
                        self:SetOrientation(originalOrientation, true)
                    end
                    p:Destroy()
                end
                
                proj.OnDestroy = function(p)
                    -- Failsafe if projectile dies without impact
                    if not self:IsDead() and self:IsAttached() then
                        self:DetachFrom()
                        self:SetImmobile(false)
                    end
                end
            end
        end

        -- DAMAGE APPLICATION: Standard Logic + Shields
        -- Pass damage to an active personal shield, as personal shields no longer have collisions
        local myShield = self.MyShield
        if myShield and myShield:IsUp() and damageType ~= 'FAF_AntiShield' then
            -- Note: Personal shields usually skip ApplyDamage from collision check, so we do it here
            myShield:ApplyDamage(instigator, amount, vector, damageType)
        else
            -- Apply direct damage
            local preAdjHealth = self:GetHealth()
            self:AdjustHealth(instigator, -amount)
            
            -- Check for death
            if self:GetHealth() <= 0 then
                if damageType == 'Reclaimed' then
                    self:Destroy()
                else
                    local excessDamageRatio = 0.0
                    local excess = preAdjHealth - amount
                    local maxHealth = self:GetMaxHealth()
                    if excess < 0 and maxHealth > 0 then
                        excessDamageRatio = -excess / maxHealth
                    end
                    self:Kill(instigator, damageType, excessDamageRatio)
                end
            end
        end
    end,
}