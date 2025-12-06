-- turn everyone hostile by default, this is corrected for teams in `BeginSessionTeams`
-- local tblArmy = ListArmies()
-- for iArmy, strArmy in tblArmy do
-- for iEnemy, _ in tblArmy do

--     -- only run this logic once for each pair
--     if iEnemy >= iArmy then
--         continue
--     end

--     -- by default we are enemies
--     local state = "Enemy"
--     if armyIsCiv then
--         -- or neutral, to the neutral civilians
--         if civOpt == "neutral" or strArmy == "NEUTRAL_CIVILIAN" then
--             state = "Neutral"
--         end
--     end

--     SetAlliance(iArmy, iEnemy, state)
-- end

-- ---------------------------------------------------------------
-- -- Modified victory.lua to transfer SACU upon ACU death

-- gameOver = false

-- local victoryCategories = {
--     demoralization = categories.COMMAND + categories.SUBCOMMANDER,
--     domination = categories.STRUCTURE + categories.ENGINEER - categories.WALL,
--     eradication = categories.ALLUNITS - categories.WALL,
-- }

-- -- Check if any units in a category are alive
-- function AllUnitsInCategoryDead(brain, categoryCheck)
--     local ListOfUnits = brain:GetListOfUnits(categoryCheck, false)
--     for _, unit in ListOfUnits do
--         if unit.CanBeKilled and not unit.Dead and unit:GetFractionComplete() == 1 then
--             return false
--         end
--     end
--     return true
-- end

-- -- Find an ally with SACUs
-- function FindAllyWithSACU(armyIndex)
--     local selfArmy = ScenarioInfo.ArmySetup['ARMY_' .. armyIndex]
--     local team = selfArmy.Team

--     for i = 1, 8 do
--         local allyArmy = ScenarioInfo.ArmySetup['ARMY_' .. i]
--         if allyArmy.ArmyIndex ~= selfArmy.ArmyIndex and allyArmy.Team == team then
--             local allyBrain = ArmyBrains[allyArmy.ArmyIndex]
--             if not allyBrain:IsDefeated() and allyBrain:GetCurrentUnits(categories.SUBCOMMANDER) > 0 then
--                 return allyBrain
--             end
--         end
--     end
--     return nil
-- end

-- -- Transfer a SACU from an ally to the defeated army
-- function TransferSACU(allyBrain, defeatedBrain)
--     local sacu = allyBrain:GetListOfUnits(categories.SUBCOMMANDER, false)[1]
--     if sacu then
--         local posX, posY = defeatedBrain:GetArmyStartPos()

--         -- Transfer unit
--         sacu:SetArmy(defeatedBrain:GetArmyIndex())

--         -- Move the SACU to the defeated army's starting position
--         sacu:SetPosition({posX, posY, 0}, true)

--         -- Apply any additional effects (optional)
--         sacu:PlayTeleportInEffects()
--         sacu:SetCanBeKilled(true)
--         sacu:SetCanTakeDamage(true)
--         sacu:SetUnSelectable(false)
--         sacu:SetBusy(false)
--         sacu:SetBlockCommandQueue(false)

--         LOG("TransferSACU: SACU transferred successfully to " .. defeatedBrain:GetArmyIndex())
--     end
-- end

-- -- Check victory and manage SACU transfers upon ACU death
-- function CheckVictory(scenarioInfo)
--     local categoryCheck = victoryCategories[scenarioInfo.Options.Victory]
--     if not categoryCheck then return end

--     local victoryTime = nil
--     local potentialWinners = {}

--     while true do
--         local stillAlive = {}
--         for index, brain in ArmyBrains do
--             if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
--                 if AllUnitsInCategoryDead(brain, categories.COMMAND) then
--                     -- The army lost its last ACU, try to transfer a SACU from an ally
--                     local allyBrain = FindAllyWithSACU(brain:GetArmyIndex())
--                     if allyBrain then
--                         -- Transfer a SACU from an ally to the defeated army
--                         TransferSACU(allyBrain, brain)
--                     else
--                         -- No SACU available, the army is defeated
--                         brain:OnDefeat()
--                         ObserverAfterDeath(brain:GetArmyIndex())
--                     end
--                 else
--                     -- The army still has either an ACU or SACU, keep them in the game
--                     table.insert(stillAlive, brain)
--                 end
--             end
--         end

--         if table.empty(stillAlive) then
--             -- No armies left alive, it's a draw
--             CallEndGame()
--             return
--         end

--         -- Victory logic (similar to original)
--         local win = true
--         local draw = true
--         for i, brain in stillAlive do
--             if not brain.OfferingDraw then
--                 draw = false
--             end

--             if not (draw or win) then break end

--             for j, other in stillAlive do
--                 if i ~= j then
--                     if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
--                         win = false
--                         break
--                     end
--                 end
--             end
--         end

--         local callback = nil
--         if win then
--             local equal = table.equal(stillAlive, potentialWinners)
--             if not equal then
--                 victoryTime = GetGameTimeSeconds() + 5
--                 potentialWinners = stillAlive
--             end

--             if equal and GetGameTimeSeconds() >= victoryTime then
--                 callback = 'OnVictory'
--             end
--         elseif draw then
--             callback = 'OnDraw'
--         else
--             victoryTime = nil
--             potentialWinners = {}
--         end

--         if callback then
--             for _, brain in stillAlive do
--                 brain[callback](brain)
--             end

--             CallEndGame()
--             return
--         end

--         WaitSeconds(3)
--     end
-- end



-- ------------------------------------------------------------------------------

-- -- gameOver = false

-- -- local victoryCategories = {
-- --     demoralization = categories.COMMAND + categories.SUBCOMMANDER,
-- --     domination = categories.STRUCTURE + categories.ENGINEER - categories.WALL,
-- --     eradication = categories.ALLUNITS - categories.WALL,
-- -- }

-- -- function AllUnitsInCategoryDead(brain, categoryCheck)
-- --     local ListOfUnits = brain:GetListOfUnits(categoryCheck, false)
-- --     for _, unit in ListOfUnits do
-- --         if unit.CanBeKilled and not unit.Dead and unit:GetFractionComplete() == 1 then
-- --             return false
-- --         end
-- --     end
-- --     return true
-- -- end

-- -- function CheckTeam(armyID, categoryCheck)
-- --     local result = 0
-- --     local myArmy = ScenarioInfo.ArmySetup['ARMY_' .. armyID]
-- --     local team = myArmy.Team

-- --     for i = 1, 8 do
-- --         local token = 'ARMY_' .. i
-- --         local army = ScenarioInfo.ArmySetup[token]

-- --         if army.ArmyIndex ~= myArmy.ArmyIndex and army.Team == team then
-- --             result = result + ArmyBrains[army.ArmyIndex]:GetCurrentUnits(categoryCheck)
-- --         end
-- --     end
-- --     return result
-- -- end

-- -- function CallEndGame()
-- --     gameOver = true
-- --     ForkThread(CallEndGameThread)
-- -- end

-- -- function CallEndGameThread()
-- --     WaitSeconds(2.9)

-- --     for _, v in GameOverListeners do
-- --         v()
-- --     end
-- --     Sync.GameEnded = true
-- --     WaitSeconds(0.1)

-- --     EndGame()
-- -- end

-- -- function CheckVictory(scenarioInfo)
-- --     local categoryCheck = victoryCategories[scenarioInfo.Options.Victory]
-- --     if not categoryCheck then return end

-- --     local victoryTime = nil
-- --     local potentialWinners = {}

-- --     while true do
-- --         local stillAlive = {}
-- --         for index, brain in ArmyBrains do
-- --             if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
-- --                 local unitsAlive = brain:GetCurrentUnits(categoryCheck) + CheckTeam(index, categoryCheck)
-- --                 if unitsAlive == 0 then
-- --                     brain:OnDefeat()
-- --                     ObserverAfterDeath(brain:GetArmyIndex())
-- --                 else
-- --                     table.insert(stillAlive, brain)
-- --                 end
-- --             end
-- --         end

-- --         if table.empty(stillAlive) then
-- --             CallEndGame()
-- --             return
-- --         end

-- --         local win = true
-- --         local draw = true
-- --         for i, brain in stillAlive do
-- --             if not brain.OfferingDraw then
-- --                 draw = false
-- --             end

-- --             if not (draw or win) then break end

-- --             for j, other in stillAlive do
-- --                 if i ~= j then
-- --                     if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
-- --                         win = false
-- --                         break
-- --                     end
-- --                 end
-- --             end
-- --         end

-- --         local callback = nil
-- --         if win then
-- --             local equal = table.equal(stillAlive, potentialWinners)
-- --             if not equal then
-- --                 victoryTime = GetGameTimeSeconds() + 5
-- --                 potentialWinners = stillAlive
-- --             end

-- --             if equal and GetGameTimeSeconds() >= victoryTime then
-- --                 callback = 'OnVictory'
-- --             end
-- --         elseif draw then
-- --             callback = 'OnDraw'
-- --         else
-- --             victoryTime = nil
-- --             potentialWinners = {}
-- --         end

-- --         if callback then
-- --             for _, brain in stillAlive do
-- --                 brain[callback](brain)
-- --             end

-- --             CallEndGame()
-- --             return
-- --         end

-- --         WaitSeconds(3)
-- --     end
-- -- end

-- ---------------------------------------------------------------

-- -- --almost Original victory.lua

gameOver = false

local victoryCategories = {
    demoralization=categories.COMMAND + categories.SUBCOMMANDER,
    domination=categories.STRUCTURE + categories.ENGINEER - categories.WALL,
    eradication=categories.ALLUNITS - categories.WALL,
}

function AllUnitsInCategoryDead(brain,categoryCheck)
    local ListOfUnits = brain:GetListOfUnits(categoryCheck, false)
    for index, unit in ListOfUnits do
        if unit.CanBeKilled and not unit.Dead and unit:GetFractionComplete() == 1 then
            return false
        end
    end
    return true
end

function ObserverAfterDeath(armyIndex)
    if not ScenarioInfo.Options.AllowObservers then return end
    local humans = {}
    local humanIndex = 0
    for i, data in ArmyBrains do
        if data.BrainType == 'Human' then
            if IsAlly(armyIndex, i) then
                if not ArmyIsOutOfGame(i) then
                    return
                end
                table.insert(humans, humanIndex)
            end
            humanIndex = humanIndex + 1
        end
    end

    for _, index in humans do
        for i in ArmyBrains do
            SetCommandSource(i - 1, index, false)
        end
    end
end

function CallEndGame()
    gameOver = true
    ForkThread(CallEndGameThread)
end

function CallEndGameThread()
    WaitSeconds(2.9)

    for _, v in GameOverListeners do
        v()
    end
    Sync.GameEnded = true
    WaitSeconds(0.1)

    EndGame()
end

function CheckVictory(scenarioInfo)
    local categoryCheck = victoryCategories[scenarioInfo.Options.Victory]
    if not categoryCheck then return end

    -- tick number we are going to issue a victory on.  Or nil if we are not.
    local victoryTime = nil
    local potentialWinners = {}

    while true do
        -- Look for newly defeated brains and tell them they're dead
        local stillAlive = {}
        for _, brain in ArmyBrains do
            if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
                if AllUnitsInCategoryDead(brain,categoryCheck) then
                    brain:OnDefeat()
                    ObserverAfterDeath(brain:GetArmyIndex())
                else
                    table.insert(stillAlive, brain)
                end
            end
        end

        -- uh-oh, there is nobody alive... It's a draw.
        if table.empty(stillAlive) then
            CallEndGame()
            return
        end

        -- check to see if everyone still alive is allied and is requesting an allied victory.
        local win = true
        local draw = true
        for i, brain in stillAlive do
            if not brain.OfferingDraw then
                draw = false
            end

            if not (draw or win) then break end

            for j, other in stillAlive do
                if i ~= j then
                    if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
                        win = false
                        break
                    end
                end
            end
        end

        local callback = nil
        if win then
            local equal = table.equal(stillAlive, potentialWinners)
            if not equal then
                victoryTime = GetGameTimeSeconds() + 5
                potentialWinners = stillAlive
            end

            if equal and GetGameTimeSeconds() >= victoryTime then
                callback = 'OnVictory'
            end
        elseif draw then
            callback = 'OnDraw'
        else
            victoryTime = nil
            potentialWinners = {}
        end

        if callback then
            for _, brain in stillAlive do
                brain[callback](brain)
            end

            CallEndGame()
            return
        end

        WaitSeconds(3)
    end
end

-- ----------------------------------------------------------

-- -- MOD1

-- -- function CheckTeam(armyID, categoryCheck)
-- --   local result = 0;
-- --   local myArmy = ScenarioInfo.ArmySetup['ARMY_' .. armyID]
-- --   local team = myArmy.Team

-- --   for i=1,8 do
-- --     local token = 'ARMY_' .. i 
-- --     local army = ScenarioInfo.ArmySetup[token]

-- --     if army.ArmyIndex != myArmy.ArmyIndex then
-- --         if army.Team == team then result = result + ArmyBrains[army.ArmyIndex]:GetCurrentUnits(categoryCheck)
-- --         end
-- --     end
-- --   end
-- --   --LOG("ID: " .. armyID .. " result: " .. result)
-- --   return result
-- -- end


-- -- function CheckVictory(scenarioInfo)

-- --     local categoryCheck = nil
-- --     if scenarioInfo.Options.Victory == 'demoralization' then
-- --         -- You're dead if you have no commanders
-- --         categoryCheck = categories.COMMAND
-- --     elseif scenarioInfo.Options.Victory == 'domination' then
-- --         -- You're dead if all structures and engineers are destroyed
-- --         categoryCheck = categories.STRUCTURE + categories.ENGINEER - categories.WALL
-- --     elseif scenarioInfo.Options.Victory == 'eradication' then
-- --         -- You're dead if you have no units
-- --         categoryCheck = categories.ALLUNITS - categories.WALL
-- --     else
-- --         -- no victory condition
-- --         return
-- --     end

-- --     -- tick number we are going to issue a victory on.  Or nil if we are not.
-- --     local victoryTime = nil
-- --     local potentialWinners = {}

-- --     while true do

-- --         -- Look for newly defeated brains and tell them they're dead
-- --         local stillAlive = {}
-- --         for index,brain in ArmyBrains do
-- --             if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
-- --                 if brain:GetCurrentUnits(categoryCheck) + CheckTeam(index, categoryCheck) == 0 then
-- --                     brain:OnDefeat()
-- --                     CallEndGame(false, true)
-- --                 else
-- --                     table.insert(stillAlive, brain)
-- --                 end
-- --             end
-- --         end

-- --         -- uh-oh, there is nobody alive... It's a draw.
-- --         if table.empty(stillAlive) then
-- --             CallEndGame(true, false)
-- --             return
-- --         end

-- --         -- check to see if everyone still alive is allied and is requesting an allied victory.
-- --         local win = true
-- --         local draw = true
-- --         for index,brain in stillAlive do
-- --             for index2,other in stillAlive do
-- --                 if index != index2 then
-- --                     if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
-- --                         win = false
-- --                     end
-- --                 end
-- --             end
-- --             if not brain.OfferingDraw then
-- --                 draw = false
-- --             end
-- --         end

-- --         if win then
-- --             if table.equal(stillAlive, potentialWinners) then
-- --                 if GetGameTimeSeconds() > victoryTime then
-- --                     -- It's a win!
-- --                     for index,brain in stillAlive do
-- --                         brain:OnVictory()
-- --                     end
-- --                     CallEndGame(true, true)
-- --                     return
-- --                 end
-- --             else
-- --                 victoryTime = GetGameTimeSeconds() + 15
-- --                 potentialWinners = stillAlive
-- --             end
-- --         elseif draw then
-- --             for index,brain in stillAlive do
-- --                 brain:OnDraw()
-- --             end
-- --             CallEndGame(true, true)
-- --             return
-- --         else
-- --             victoryTime = nil
-- --             potentialWinners = {}
-- --         end

-- --         WaitSeconds(3.0)
-- --     end
-- -- end


-- -----------------

-- -- MOD2

-- -- function CheckVictory(scenarioInfo)

-- --     local categoryCheck = nil
-- --     if scenarioInfo.Options.Victory == 'demoralization' then
-- --         -- You're dead if you have no commanders
-- --         categoryCheck = categories.COMMAND + categories.SUBCOMMANDER
-- --     elseif scenarioInfo.Options.Victory == 'domination' then
-- --         -- You're dead if all structures and engineers are destroyed
-- --         categoryCheck = categories.STRUCTURE + categories.ENGINEER - categories.WALL
-- --     elseif scenarioInfo.Options.Victory == 'eradication' then
-- --         -- You're dead if you have no units
-- --         categoryCheck = categories.ALLUNITS - categories.WALL
-- --     else
-- --         -- no victory condition
-- --         return
-- --     end

-- --     -- tick number we are going to issue a victory on.  Or nil if we are not.
-- --     local victoryTime = nil
-- --     local potentialWinners = {}

-- --     while true do

-- --         -- Look for newly defeated brains and tell them they're dead
-- --         local stillAlive = {}
-- --         for index,brain in ArmyBrains do
-- --             if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
-- --                 if brain:GetCurrentUnits(categoryCheck) == 0 then
-- --                     brain:OnDefeat()
-- --                     CallEndGame(false, true)
-- --                 else
-- --                     table.insert(stillAlive, brain)
-- --                 end
-- --             end
-- --         end

-- --         -- uh-oh, there is nobody alive... It's a draw.
-- --         if table.empty(stillAlive) then
-- --             CallEndGame(true, false)
-- --             return
-- --         end

-- --         -- check to see if everyone still alive is allied and is requesting an allied victory.
-- --         local win = true
-- --         local draw = true
-- --         for index,brain in stillAlive do
-- --             for index2,other in stillAlive do
-- --                 if index != index2 then
-- --                     if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
-- --                         win = false
-- --                     end
-- --                 end
-- --             end
-- --             if not brain.OfferingDraw then
-- --                 draw = false
-- --             end
-- --         end

-- --         if win then
-- --             if table.equal(stillAlive, potentialWinners) then
-- --                 if GetGameTimeSeconds() > victoryTime then
-- --                     -- It's a win!
-- --                     for index,brain in stillAlive do
-- --                         brain:OnVictory()
-- --                     end
-- --                     CallEndGame(true, true)
-- --                     return
-- --                 end
-- --             else
-- --                 victoryTime = GetGameTimeSeconds() + 15
-- --                 potentialWinners = stillAlive
-- --             end
-- --         elseif draw then
-- --             for index,brain in stillAlive do
-- --                 brain:OnDraw()
-- --             end
-- --             CallEndGame(true, true)
-- --             return
-- --         else
-- --             victoryTime = nil
-- --             potentialWinners = {}
-- --         end

-- --         WaitSeconds(3.0)
-- --     end
-- -- end

-- -- function CallEndGame(callEndGame, submitXMLStats)
-- --     if submitXMLStats then
-- --         SubmitXMLArmyStats()
-- --     end
-- --     if callEndGame then
-- --         gameOver = true
-- --         ForkThread(function()
-- --             WaitSeconds(3)
-- --             EndGame()
-- --         end)
-- --     end
-- -- end

-- -- gameOver = false
