function CreateScalableUnitExplosion(unit, debrisMultiplier, circularDebris)

    debrisMultiplier = debrisMultiplier or 1
    circularDebris = circularDebris or false

    if unit and (not IsDestroyed(unit)) then
        if IsUnit(unit) then

            -- cache blueprint values
            local blueprint = EntityGetBlueprint(unit)
            local sx = blueprint.SizeX or 1 
            local sy = blueprint.SizeY or 1 
            local sz = blueprint.SizeZ or 1 

            -- cache stats 
            local army = unit.Army
            local boundingXZRadius = 0.25 * (sx + sz)
            local boundingXYZRadius = 0.166 * (sx + sy + sz)
            local volume = sx * sy * sz
            local layer = unit.Layer

            -- data for emitters / shaking
            local baseEffects = false
            local environmentEffects = false 
            local shakeTimeModifier = 0
            local shakeMaxMul = 1

            if layer == 'Land' then
                -- determine land effects
                if boundingXZRadius < 1.1 then
                    baseEffects = ExplosionSmall
                elseif boundingXZRadius > 3.75 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionLarge
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMedium
                end

                -- environment effects (splat / decal creation)
                local position = EntityGetPosition(unit)
                local scorchRotation = 6.28 * Random()
                local scorchDuration = 200 + 150 * Random()
                local scorchLOD = 99999
                if boundingXZRadius > 1.2 then
                    CreateDecal(
                        position, 
                        scorchRotation, 
                        UpvaluedScorchDecalTextures[Random(1, ScorchDecalTexturesN)], 
                        '', 
                        'Albedo', 
                        boundingXZRadius, 
                        boundingXZRadius, 
                        scorchLOD, 
                        scorchDuration, 
                        army
                    )
                else
                    CreateSplat(
                        position, 
                        scorchRotation, 
                        UpvaluedScorchSplatTextures[Random(1, ScorchSplatTexturesN)], 
                        boundingXZRadius, 
                        boundingXZRadius, 
                        scorchLOD,
                        scorchDuration, 
                        army
                    )
                end

            elseif layer == 'Air' then
                -- determine air effects
                if boundingXZRadius < 1.1 then
                    baseEffects = ExplosionSmallAir
                elseif boundingXZRadius > 7 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionLarge
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMedium
                end
            elseif layer == 'Water' then
                -- determine water effects
                if boundingXZRadius < 2 then
                    baseEffects = ExplosionSmallWater
                elseif boundingXZRadius > 3.6 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionMediumWater
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMediumWater
                end

                -- environment effects
                if boundingXZRadius < 1.0 then
                    environmentEffects = Splashy
                end
            end

            -- create the emitters  
            if baseEffects then 
                CreateEffectsOpti(unit, army, baseEffects)
            end

            if environmentEffects then 
                CreateEffectsOpti(unit, army, environmentEffects)       
            end    

            -- create the flash
            CreateLightParticle(
                unit, 
                -1, 
                army, 
                boundingXZRadius * (2 + 1 * Random()),  -- (2, 3)
                10.5 + 4 * Random(), -- (10.5, 14.5)
                'glow_03', 
                'ramp_flare_02'
            )

            -- determine debris amount
            local amount = debrisMultiplier * MathMin(Random(1 + (boundingXYZRadius * 6), (boundingXYZRadius * 15)) , 100)

            -- determine debris velocity range
            local velocity = 2 * boundingXYZRadius
            local hVelocity = 0.5 * velocity

            -- determine heading adjustments for debris origin
            local heading = -1 * unit:GetHeading() -- inverse heading because Supreme Commander :)
            local mch = MathCos(heading)
            local msh = MathSin(heading)

            -- make it slightly smaller so that debris originates from mesh and not from the air
            sx = 0.8 * sx 
            sy = 0.8 * sy 
            sz = 0.8 * sz

            -- create debris
            for i = 1, amount do

                -- get some random numbers
                local r1, r2, r3 = Random(), Random(), Random() 

                -- position somewhere in the size of the unit
                local xpos = r1 * sx - (sx * 0.5)
                local ypos = 0.1 * sy + 0.5 * r2 * sy
                local zpos = r3 * sz - (sz * 0.5)

                -- launch them into space
                local xdir, ydir, zdir 
                if circularDebris then 
                    xdir = velocity * r1 - (hVelocity)
                    ydir = velocity * r2 - (hVelocity)
                    zdir = velocity * r3 - (hVelocity)
                else 
                    xdir = velocity * r1 - (hVelocity)
                    ydir = boundingXYZRadius + velocity * r2
                    zdir = velocity * r3 - (hVelocity)
                end

                -- choose a random blueprint
                local bp = ProjectileDebrisBps[MathMin(ProjectileDebrisBpsN, Random(1, i))]

                EntityCreateProjectile(
                    unit, 
                    bp, 
                    xpos * mch - zpos * msh, -- adjust for orientation of unit
                    ypos, 
                    xpos * msh + zpos * mch, -- adjust for orientation of unit
                    xdir * mch - zdir * msh, -- adjust for orientation of unit 
                    ydir, 
                    xdir * msh + zdir * mch  -- adjust for orientation of unit
                )
            end

            -- do camera shake
            EntityShakeCamera(unit, 30 * boundingXZRadius, boundingXZRadius * shakeMaxMul, 0, 0.5 + shakeTimeModifier)
        end
    end
end