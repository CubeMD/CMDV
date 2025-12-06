
-- local BaseAIBrain = AIBrain
-- AIBrain = Class(BaseAIBrain) {

--     revivalCount = 0, 
    
--     SpawnRevivalUnits = function(self, shouldKillArmy)
--         if self.revivalCount > 1 then
--             LOG("SpawnRevivalUnits: Failed!")
--             return false
--         end

--         LOG("Attempt Spawn Revival Unit")
--         local factionIndex = self:GetFactionIndex()
--         local selfIndex = self:GetArmyIndex()
--         local unitsToSpawn = nil
--         local transferBrain = nil
--         local transferBrainScore = 0
    
--         if factionIndex == 1 then
--             unitsToSpawn = { 'uel0001' }
--         elseif factionIndex == 2 then
--             unitsToSpawn = { 'ual0001' }
--         elseif factionIndex == 3 then
--             unitsToSpawn = { 'url0001' }
--         elseif factionIndex == 4 then
--             unitsToSpawn = { 'xsl0001' }
--         end

--         for index, brain in ArmyBrains do
--             if not brain:IsDefeated() and selfIndex ~= index then
--                 local brainIndex = brain:GetArmyIndex()
--                 if not ArmyIsCivilian(brainIndex) and IsAlly(selfIndex, brainIndex) then
--                     if CalculateBrainScore(brain) > transferBrainScore then
--                         transferBrain = brain
--                     end
--                 end
--             end
--         end  

--         local spawnSucceeded = false
        
--         if transferBrain then
--             local posX, posY = transferBrain:GetArmyStartPos()
--             local spawnedUnits = {}
--             if unitsToSpawn then
--                 local spawnCount = 0
--                 for j, u in unitsToSpawn do
--                     local unit = self:CreateUnitNearSpot(u, posX, posY)
    
--                     if unit ~= nil then
--                         LOG("SpawnRevivalUnits: Succeeded!")

--                         LOG("SpawnRevivalUnits: Start Effects")
--                         if unit:GetBlueprint().Physics.FlattenSkirt then
--                             unit:CreateTarmac(true, true, true, false, false)
--                         end
        
--                         unit:SetImmobile(true)               
--                         unit:SetCanBeKilled(false)
--                         unit:SetCanTakeDamage(false)
--                         unit:SetUnSelectable(true)
--                         unit:SetBusy(true)
--                         unit:SetBlockCommandQueue(true)                        

--                         unit:HideBone(0, true)

--                         table.insert(spawnedUnits,unit) 

--                         spawnCount = spawnCount + 1
--                         spawnSucceeded = true
--                     end                
--                 end
--                 LOG("SpawnRevivalUnits: " .. tostring(spawnCount) .. "!")
--                 if spawnCount > 0 then
--                     self.revivalCount = self.revivalCount + 1
--                     LOG("Revival Count: " .. tostring(self.revivalCount))

--                     self:ForkThread(self.FinishSpawnEvent, spawnedUnits)

--                     local standingArmy = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
--                     for index,unit in standingArmy do
--                         unit:Kill()
--                     end                    
--                 end
--             end
--         end

--         LOG("SpawnRevivalUnits: Failed!")
--         return spawnSucceeded
--     end,

--     FinishSpawnEvent = function(self, units)

--         LOG("SpawnRevivalUnits: FinishSpawnEvent")

--         WaitSeconds( 5.0 )

--         LOG("SpawnRevivalUnits: FinishSpawnEvent Started")

--         for index,unit in units do
--             unit:PlayUnitSound('TeleportStart')
--             unit:PlayUnitAmbientSound('TeleportLoop')

--             unit:PlayTeleportChargeEffects(unit:GetPosition(), unit:GetOrientation())
--             unit:PlayUnitSound('GateCharge')                 

--             unit:ShowBone(0, true)
--             unit:SetCanBeKilled(true)
--             unit:SetCanTakeDamage(true)

--             -- if EntityCategoryContains(categories.COMMAND, unit) then
--             --     unit:CreateEnhancement("ResourceAllocation")
--             -- end            
--         end

--         WaitSeconds( 10.0 )

--         for index,unit in units do
--             unit:PlayTeleportOutEffects()
--             unit:CleanupTeleportChargeEffects()      
--         end
    
--         WaitSeconds( 0.1 )
    
--         for index,unit in units do
--             unit:PlayTeleportInEffects()
--             unit:SetWorkProgress(0.0)       
--             unit:CleanupRemainingTeleportChargeEffects()                 
--         end
    
--         WaitSeconds( 0.1 )  

--         for index,unit in units do
--             unit:StopUnitAmbientSound('TeleportLoop')
--             unit:PlayUnitSound('TeleportEnd')       
--             unit:SetImmobile(false)
--             unit:SetUnSelectable(false)
--             unit:SetBusy(false)
--             unit:SetBlockCommandQueue(false)     
--         end

--         LOG("SpawnRevivalUnits: FinishSpawnEvent Completed")
--     end,
-- }

