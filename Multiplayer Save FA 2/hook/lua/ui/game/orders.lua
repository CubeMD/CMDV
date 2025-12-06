-- -- called by gamemain when new orders are available, 
-- function SetAvailableOrders(availableOrders, availableToggles, newSelection)
--     -- save new selection
    
--     LOG('available orders: ', repr(availableOrders))
--     LOG('available toggles: ', repr(availableToggles))
--     LOG(' newSelection: ', repr(newSelection))
--     currentSelection = newSelection

--     LOG('clear existing orders')
--     orderCheckboxMap = {}
--     controls.orderButtonGrid:DestroyAllItems(true)

--     -- create our copy of orders table
--     LOG('create our copy of orders table')
--     standardOrdersTable = table.deepcopy(defaultOrdersTable)
    
--     -- look in blueprints for any icon or tooltip overrides
--     -- note that if multiple overrides are found for the same order, then the default is used
--     -- the syntax of the override in the blueprint is as follows (the overrides use same naming as in the default table above):
--     -- In General table
--     -- OrderOverrides = {
--     --     RULEUTC_IntelToggle = {
--     --         bitmapId = 'custom',
--     --         helpText = 'toggle_custom',
--     --     },
--     --  },
--     -- 
--     LOG("MultiplayerSave DEBUG: Look in blueprints for any icon or tooltip overrides")
--     local orderDiffs
    
--     for index, unit in newSelection do
--         local overrideTable = unit:GetBlueprint().General.OrderOverrides
--         if overrideTable then
--             for orderKey, override in overrideTable do
--                 if orderDiffs == nil then
--                     orderDiffs = {}
--                 end
--                 if orderDiffs[orderKey] != nil and (orderDiffs[orderKey].bitmapId != override.bitmapId or orderDiffs[orderKey].helpText != override.helpText) then
--                     -- found order diff already, so mark it false so it gets ignored when applying to table
--                     orderDiffs[orderKey] = false
--                 else
--                     orderDiffs[orderKey] = override
--                 end
--             end
--         end
--     end
    
--     LOG("MultiplayerSave DEBUG: apply overrides")
--     -- apply overrides
--     if orderDiffs != nil then
--         for orderKey, override in orderDiffs do
--             if override and override != false then
--                 if override.bitmapId then
--                     standardOrdersTable[orderKey].bitmapId = override.bitmapId
--                 end
--                 if override.helpText then
--                     standardOrdersTable[orderKey].helpText = override.helpText
--                 end
--             end
--         end
--     end
    
--     LOG("MultiplayerSave DEBUG: CreateCommonOrders")
--     CreateCommonOrders(availableOrders)
    
--     LOG("MultiplayerSave DEBUG: Iterating over avaialbeOrders ")
--     local numValidOrders = 0
--     for i, v in availableOrders do
--         if standardOrdersTable[v] then
--             numValidOrders = numValidOrders + 1
--         end
--     end
--     LOG("MultiplayerSave DEBUG: Iterating over avaialbeOrders 2")
--     for i, v in availableToggles do
--         if standardOrdersTable[v] then
--             numValidOrders = numValidOrders + 1
--         end
--     end
    
--     if numValidOrders <= 12 then
--         CreateAltOrders(availableOrders, availableToggles, currentSelection)
--     end
    
--      LOG("MultiplayerSave DEBUG: EndBatch")
--     controls.orderButtonGrid:EndBatch()
--     if table.getn(currentSelection) == 0 and controls.bg.Mini then
--         controls.bg.Mini(true)
--     elseif controls.bg.Mini then
--         controls.bg.Mini(false)
--     end
-- end
