--- START OF FILE prop.txt ---

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

                self.SavedProj.OnImpact = function(self, targetType, targetEntity)
                    local a = prop
                    local b = projecto
                    local p = b:GetPosition()

                    local merged = false
                    
                    if a ~= nil and IsDestroyed(a) == false then
                        -- CLUMPING LOGIC: Search for nearby mass props to merge into
                        local checkRect = Rect(p[1]-1, p[3]-1, p[1]+1, p[3]+1)
                        local candidates = GetReclaimablesInRect(checkRect)
                        
                        if candidates then
                            for _, r in candidates do
                                -- Check if it's a valid prop, not us, not the projectile, and has mass
                                if r and not IsDestroyed(r) and IsProp(r) and r ~= a and r ~= b and r.MaxMassReclaim then
                                    local rPos = r:GetPosition()
                                    local dist = VDist2(p[1], p[3], rPos[1], rPos[3])
                                    
                                    -- Distance threshold for merging (fluid drop coalescence)
                                    if dist < 0.5 then
                                        local aMass = (a.MaxMassReclaim or 0) * (a.ReclaimLeft or 1)
                                        local aEnergy = (a.MaxEnergyReclaim or 0) * (a.ReclaimLeft or 1)
                                        
                                        local rMass = (r.MaxMassReclaim or 0) * (r.ReclaimLeft or 1)
                                        local rEnergy = (r.MaxEnergyReclaim or 0) * (r.ReclaimLeft or 1)
                                        
                                        local newMass = rMass + aMass
                                        local newEnergy = rEnergy + aEnergy
                                        
                                        -- Update target prop values
                                        r.MaxMassReclaim = newMass
                                        r.MaxEnergyReclaim = newEnergy
                                        r.ReclaimLeft = 1 -- Reset health ratio since we updated max
                                        
                                        -- Update scale based on mass (Cube root approximation for volume -> radius)
                                        -- Assuming standard mass is around 10-100, we apply a factor
                                        local bpMass = r:GetBlueprint().Economy.ReclaimMassMax or r:GetBlueprint().Economy.BuildCostMass or 10
                                        if bpMass < 1 then bpMass = 10 end
                                        
                                        -- Determine current scale relative to BP (if previously scaled)
                                        -- Since we don't store previous scale easily, let's recalculate based on total mass vs BP mass
                                        local newScale = math.pow(newMass / bpMass, 0.333) * (r:GetBlueprint().Display.UniformScale or 1)
                                        
                                        r:SetScale(newScale)
                                        r:UpdateUILabel()
                                        
                                        -- Destroy the falling prop
                                        a:Destroy()
                                        merged = true
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if not merged and a ~= nil and IsDestroyed(a) == false then
                        a:DetachFrom(true)
                        b:DetachFrom(true)
                        local z = Vector(p[1], GetTerrainHeight(p[1],p[3]), p[3])
                        Warp( a, z)
                        a:SetOrientation(o, true)
                        a.CachePosition = z
                        a:UpdateUILabel()
                    end

                    b:OnImpactDestroy(targetType, targetEntity)
                end

                self.SavedProj.DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)
                end

                self.SavedProj.OnDamage = function(self, instigator, amount, vector, damageType)
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