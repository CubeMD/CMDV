local OrigProp = Prop

function GetVectorLength(v)
    return math.sqrt(math.pow(v.x, 2) + math.pow(v.y, 2) + math.pow(v.z, 2))
end

function NormalizeVector(v)
    local length = GetVectorLength(v)
    if length > 0 then
        local invlength = 1 / length
        return Vector(v.x * invlength, v.y * invlength, v.z * invlength)
    else
        return Vector(0,0,0)
    end
end

function GetDirectionVector(v1, v2)
    return NormalizeVector(Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z))
end

Prop = Class(OrigProp) {

    SavedProj = nil,

    OnDamage = function(self, instigator, amount, direction, damageType)
        if damageType == "TreeFire" or damageType == "FAF_AntiShield" then
            return
        end

        if damageType == 'Reclaimed' then
            -- adjust our health
            local preHealth = self:GetHealth()
            self:AdjustHealth(instigator, -amount)
            local health = preHealth - amount
            if health < 0 then
                health = 0
                self:Destroy()
                return
            else
                self:UpdateReclaimLeft()
                return
            end
        end

        if instigator ~= nil and IsDestroyed(instigator) == false and IsUnit(instigator) and instigator ~= self then
            if self.SavedProj == nil or IsDestroyed(self.SavedProj) then
                local prop = self
                local propPosition = self:GetPosition()
                local o = self:GetOrientation()

                local projecto = instigator:CreateProjectile('/projectiles/TDFGauss01/TDFGauss01_proj.bp', propPosition[1], GetTerrainHeight(propPosition[1],propPosition[3]), propPosition[3], 0, 0, 0):SetLifetime(600000)
                self.SavedProj = projecto
                self.SavedProj.SavedProp = self

                -- local oldOnDestroy = self.SavedProj.OnDestroy
                -- self.SavedProj.OnDestroy = function(self)
                --     local p1 = prop
                --     if (p1 ~= nil and IsDestroyed(p1) == false) then
                --         p1:UpdateUILabel()
                --     end

                --     oldOnDestroy(self)
                -- end

                self.SavedProj.OnImpact = function(self, targetType, targetEntity)
                    local a = prop
                    local b = projecto
                    -- local vc = b:GetPosition()
                    -- local vx, vy, vz = b:GetVelocity()

                    -- local nv = NormalizeVector(Vector(vx, 0, vz))
                    
                    -- local mult = GetVectorLength(Vector(nv[1], vy, nv[3])) * (a.MaxMassReclaim * a.ReclaimLeft + 0.1)

                    -- local damageData = {}
                    -- damageData.DamageRadius = math.min(math.max(mult * 0.1, 0), 2)
                    -- damageData.DamageAmount = mult
                    -- damageData.DamageType = 'TreeForce'
                    -- damageData.DamageFriendly = false
                    -- damageData.CollideFriendly = false
                    
                    -- b:SetVelocity(0, 0, 0)
                    -- b:SetBallisticAcceleration(0)
                    local p = b:GetPosition()
                    
                    -- b:SetCollideSurface(false)

                    -- if damageData.DamageAmount > 10 then
                    --     DamageArea(
                    --         instigator,
                    --         vc,
                    --         damageData.DamageRadius,
                    --         damageData.DamageAmount,
                    --         damageData.DamageType,
                    --         damageData.DamageFriendly,
                    --         false
                    --     )
                    -- end

                    if a ~= nil and IsDestroyed(a) == false then
                        a:DetachFrom(true)
                        b:DetachFrom(true)
                        local z = Vector(p[1], GetTerrainHeight(p[1],p[3]), p[3])
                        Warp( a, z)
                        a:SetOrientation(o, true)
                        a.CachePosition = z
                    end

                    -- Warp( b, Vector(p[1], GetTerrainHeight(p[1],p[3]) + 0.2, p[3]))

                    b:OnImpactDestroy(targetType, targetEntity)

                    a:UpdateUILabel()
                end

                self.SavedProj.DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)
                end

                self.SavedProj.OnDamage = function(self, instigator, amount, vector, damageType)
                    -- if self.Blueprint.Defense.MaxHealth then
                    --     -- we have some health, try and survive
                    --     self:DoTakeDamage(instigator, amount, vector, damageType)
                    -- else
                    --     -- we have no health, just perish
                    --     self:OnKilled(instigator, damageType)
                    -- end
                end

                self.SavedProj.OnTrackTargetGround = function(self)
                end

                self.SavedProj.OnCollisionCheck = function(self, other)
                    return false
                end

                self.SavedProj.OnCollisionCheckWeapon = function(self, firingWeapon)
                    return false
                end

                self.SavedProj.OnKilled = function(self, instigator, type, overkillRatio)
                end

                self.SavedProj.OnExitWater = function(self)
                end
                
                self.SavedProj.OnEnterWater = function(self)
                end

                self.SavedProj.OnLostTarget = function(self)
                end

                self.SavedProj.RetargetThread = function(self)
                end

                self.SavedProj.DoUnitImpactBuffs = function(self, target)
                end

                -- self.SavedProj.OnImpactDestroy = function(self, targetType, targetEntity)
                --     -- if self.DestroyOnImpact or
                --     --     (not targetEntity) or
                --     --     (not EntityCategoryContains(OnImpactDestroyCategories, targetEntity))
                --     -- then
                --     --     self:Destroy()
                --     -- end
                -- end

                self.SavedProj.AddFlare = function(self, tbl)
                end

                self.SavedProj.AddDepthCharge = function(self, blueprint)
                end

                self.SavedProj.CreateImpactEffects = function(self, army, effectTable, effectScale)
                end

                self.SavedProj.CreateTerrainEffects = function(self, army, effectTable, effectScale)
                end

                self.SavedProj.GetTerrainEffects = function(self, targetType, impactEffectType, position)
                end

                self.SavedProj.DoTakeDamage = function(self, instigator, amount, vector, damageType)
                    -- Check for valid projectile
                    -- if not self or self:BeenDestroyed() then
                    --     return
                    -- end

                    -- self:AdjustHealth(instigator, -amount)
                    -- local health = self:GetHealth()
                    -- if health <= 0 then
                    --     if damageType == 'Reclaimed' then
                    --         self:Destroy()
                    --     else
                    --         local excessDamageRatio = 0.0

                    --         -- Calculate the excess damage amount
                    --         local excess = health - amount
                    --         local maxHealth = self.Blueprint.Defense.MaxHealth or 10
                    --         if excess < 0 and maxHealth > 0 then
                    --             excessDamageRatio = -excess / maxHealth
                    --         end
                    --         self:OnKilled(instigator, damageType, excessDamageRatio)
                    --     end
                    -- end
                end

                self.SavedProj:SetNewTargetGround({propPosition[1], propPosition[2] - 1000, propPosition[3]})
                self.SavedProj:SetVelocityAlign(false)
                --self.SavedProj:SetOrientation(o, true)
                Warp( self.SavedProj, Vector(propPosition[1], GetTerrainHeight(propPosition[1],propPosition[3]) + 0.15, propPosition[3]))

                propPosition[2] = 0
                local iP = instigator:GetPosition()
                iP[2] = 0

                local nv1 = GetDirectionVector(iP, propPosition)

                local multM = math.log(amount, 2) + 1
                local mult = multM / math.max((math.sqrt((self.MaxMassReclaim * self.ReclaimLeft) + 0.000001) * 0.1), 1)-- * GetVectorLength(Vector(direction[1]/10, 0 , direction[3]/10)))
                self.SavedProj:SetVelocity(nv1[1] * mult * 2.5, multM * 2, nv1[3] * mult * 2.5)
                
                self:AttachTo(self.SavedProj, -1)
                self:SetOrientation(o, true)
                -- self.SavedProj:SetBallisticAcceleration(-9.8)
                -- self.SavedProj:SetCollideSurface(true)
            else
                -- local propPosition = self:GetPosition()
                -- propPosition[2] = 0
                -- local iP = instigator:GetPosition()
                -- iP[2] = 0

                -- local nv1 = GetDirectionVector(iP, propPosition)

                -- local multM = math.log(amount, 2) + 1
                -- local mult = multM / math.max((math.sqrt((self.MaxMassReclaim * self.ReclaimLeft) + 0.000001) * 0.1), 1)-- * GetVectorLength(Vector(direction[1]/10, 0 , direction[3]/10)))
                -- local vx, vy, vz = self.SavedProj:GetVelocity()
                -- self.SavedProj:SetVelocity(nv1[1] * mult * 2.5 + vx, multM * 2 + vy, nv1[3] * mult * 2.5 + vz)
            end
        end
    end,

    OnDestroy = function(self)
        -- if (self.SavedProj ~= nil and IsDestroyed(self.SavedProj) == false) then
        --     self.SavedProj:Destroy()
        -- end

        self:CleanupUILabel()
        self.Trash:Destroy()

        -- keep track of reclaim
        if GridReclaimInstance then
            GridReclaimInstance:OnReclaimDestroyed(self)
        end
    end,

    UpdateUILabel = function(self)
        local data = self.SyncData
        if data then
            local mass = self.MaxMassReclaim * self.ReclaimLeft

            if mass < 12 then
                self:CleanupUILabel()
                return
            end

            data.mass = mass
            data.position = self.CachePosition
            Sync.Reclaim[self.EntityId] = data
        end

        if GridReclaimInstance then
            GridReclaimInstance:OnReclaimUpdate(self)
        end
    end,

        --- Set the mass/energy value of this wreck when at full health, and the time coefficient
    --- that determine how quickly it can be reclaimed. These values are used to set the real reclaim
    --- values as fractions of the health as the wreck takes damage.
    ---@param self Prop
    ---@param time number
    ---@param mass number
    ---@param energy number
    SetMaxReclaimValues = function(self, time, mass, energy)
        self.MaxMassReclaim = mass
        self.MaxEnergyReclaim = energy
        self.TimeReclaim = time
        self:UpdateReclaimLeft()

        if self.MaxMassReclaim * self.ReclaimLeft >= 12 then
            self:SetupUILabel()
        end
    end,

    --- Mimics the engine behavior when calculating the reclaim value of a prop
    ---@param self Prop
    UpdateReclaimLeft = function(self)
        if not self:BeenDestroyed() then
            local max = self:GetMaxHealth()
            local health = self:GetHealth()
            local ratio = (max and max > 0 and health / max) or 1

            -- we have to take into account if the wreck has been partly reclaimed by an engineer
            self.ReclaimLeft = ratio * self:GetFractionComplete()
            self:UpdateUILabel()
        else
            self.ReclaimLeft = 0
        end

        -- keep track of reclaim
        if GridReclaimInstance then
            GridReclaimInstance:OnReclaimUpdate(self)
        end
    end,

    SplitOnBonesByName = function(self, dirprefix)

        -- -- compute reclaim time of props
        -- local economy = self.Blueprint.Economy
        -- local time = 1
        -- if economy then
        --     time = economy.ReclaimTimeMultiplier or economy.ReclaimMassTimeMultiplier or
        --         economy.ReclaimEnergyTimeMultiplier or 1
        -- end

        -- -- compute directory prefix if it is not set
        -- if not dirprefix then
        --     -- default dirprefix to parent dir of our own blueprint
        --     -- trim ".../groups/blah_prop.bp" to just ".../"
        --     dirprefix = StringGsub(self.Blueprint.BlueprintId, "[^/]*/[^/]*$", "")
        -- end

        -- -- values used in the for loop
        -- local trimmedBoneName, blueprint, bone, ok, out

        -- -- contains the new props and the expected number of props
        -- local props = {}
        -- local count = self:GetBoneCount() - 1

        -- -- compute information of new props
        -- local compensationMult = 2
        -- local time = time / count
        -- local mass = (self.MaxMassReclaim * self.ReclaimLeft * compensationMult) / count
        -- local energy = (self.MaxEnergyReclaim * self.ReclaimLeft * compensationMult) / count
        -- for ibone = 1, count do

        --     -- get the bone name
        --     bone = self:GetBoneName(ibone)

        --     -- determine prop name (removing _01, _02 from bone name)
        --     trimmedBoneName = StringGsub(bone, "_?[0-9]+$", "")
        --     blueprint = dirprefix .. trimmedBoneName .. "_prop.bp"

        --     -- attempt to make the prop
        --     ok, out = pcall(self.CreatePropAtBone, self, ibone, blueprint)
        --     if ok then
        --         out:SetMaxReclaimValues(time, mass, energy)
        --         props[ibone] = out
        --     else
        --         WARN("Unable to split a prop: " .. self.Blueprint.BlueprintId .. " -> " .. blueprint)
        --         WARN(out)
        --     end
        -- end

        -- self:Destroy()
        -- return props
    end,
}