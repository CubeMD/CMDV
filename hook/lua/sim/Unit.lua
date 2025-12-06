local OrigUnit = Unit

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

    -- OnDamage = function(self, instigator, amount, vector, damageType)

    --     -- only applies to trees
    --     if damageType == "TreeForce" or damageType == "TreeFire" then 
    --         return 
    --     end

    --     if self.CanTakeDamage then

    --         if instigator ~= nil and (self.IsFlying == nil or self.IsFlying == false) then
    --             -- Create a projectile and launch it
    --             local o = self:GetOrientation()
    --             local propPosition = self:GetPosition()       
    --             local meteorProj = instigator:CreateProjectile('/projectiles/TDFGauss01/TDFGauss01_proj.bp', propPosition[1], propPosition[2], propPosition[3], nil, nil, nil):SetLifetime(30)
    --             Warp( meteorProj, Vector(propPosition[1], propPosition[2], propPosition[3]))
    --             meteorProj:SetVelocityAlign(false)
    --             self:AttachTo(meteorProj, 0)

    --             meteorProj.SavedProp = self
    --             meteorProj.SavedProp:SetOrientation(o, true)
    --             self.IsFlying = true
                
    --             --local instigatorPosition = instigator:GetPosition()

    --             -- meteorProj.AssociatedProp = prop

    --             meteorProj:SetNewTargetGround({propPosition[1], propPosition[2] - 100, propPosition[3]})

    --             -- local max = (1 - t) * 15
    --             -- local min = math.max(max - 3, 0)

    --             local mult = amount / (self:GetTotalMassCost() * 2 + 30)

    --             meteorProj:SetVelocity(vector[1] * mult, 0.2 + mult, vector[3] * mult)

    --             -- meteorProj:PassDamageData(GetMeteorDamageTable())

    --             --Warp( meteorProj, Vector(propPosition[1], propPosition[2], propPosition[3]))

    --             local oldOnDestroy = meteorProj.OnDestroy
    --             meteorProj.OnDestroy = function(self)
                    
    --                 --local prop = CreateProp(Vector(p[1], GetTerrainHeight(p[1],p[3]), p[3]), "/env/Geothermal/Props/Rocks/GeoRockGroup01_prop.bp")
    --                 --prop:SetMaxReclaimValues(1, 12 + t * 500, 0)
    --                 --prop:AddWorldImpulse(1000,1000,1000,1000,1000,1000)
    --                 -- local motor = prop:FallDown()
    --                 -- motor:Whack(100, 100, 100, 0, false)
                    
    --                 --Warp( prop, Vector(p[1] + Random(0,300), GetTerrainHeight(p[1],p[3]), p[3] + Random(0,300)))
                    
                    
    --                 if meteorProj.SavedProp ~= nil and meteorProj.SavedProp:IsDead() == false then
    --                     local p = meteorProj:GetPosition()
    --                     meteorProj:DetachFrom(true)
    --                     meteorProj.SavedProp:DetachFrom(true)

    --                     Warp( meteorProj.SavedProp, Vector(p[1], GetTerrainHeight(p[1],p[3]), p[3]))
    --                     meteorProj.SavedProp:SetOrientation(o, true)
    --                     meteorProj.SavedProp.IsFlying = false
    --                 end
                   
    --                 -- if GridReclaimInstance then
    --                 --     GridReclaimInstance:OnReclaimUpdate(meteorProj.SavedProp)
    --                 -- end
    --                 -- Destroy the projectile
    --                 oldOnDestroy(self)
    --             end
    --         end

    --         -- Pass damage to an active personal shield, as personal shields no longer have collisions
    --         local myShield = self.MyShield
    --         if myShield.ShieldType == "Personal" and myShield:IsUp() then
    --             self:DoOnDamagedCallbacks(instigator)
    --             self.MyShield:ApplyDamage(instigator, amount, vector, damageType)
    --         elseif damageType ~= "FAF_AntiShield" then
    --             self:DoOnDamagedCallbacks(instigator)
    --             self:DoTakeDamage(instigator, amount, vector, damageType)
    --         end
    --     end
    -- end,
}

