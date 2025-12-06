function OnClickHandler(button, modifiers)
    PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
    local item = button.Data

    if options.gui_improved_unit_deselection ~= 0 then
        -- Improved unit deselection -ghaleon
        if item.type == 'unitstack' then
            if modifiers.Right then
                if modifiers.Shift or modifiers.Ctrl or (modifiers.Shift and modifiers.Ctrl) then -- we have one of our modifiers
                    local selectionx = {}
                    local countx = 0
                    if modifiers.Shift then countx = 1 end
                    if modifiers.Ctrl then countx = 5 end
                    if modifiers.Shift and modifiers.Ctrl then countx = 10 end
                    for _, unit in sortedOptions.selection do
                        local foundx = false
                        for _, checkUnit in item.units do
                            if checkUnit == unit and countx > 0 then
                                foundx = true
                                countx = countx - 1
                                break
                            end
                        end
                        if not foundx then
                            table.insert(selectionx, unit)
                        end
                    end
                    SelectUnits(selectionx)
                else -- Default right-click behavior
                    local selection = {}
                    for _, unit in sortedOptions.selection do
                        local found = false
                        for _, checkUnit in item.units do
                            if checkUnit == unit then
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(selection, unit)
                        end
                    end
                    SelectUnits(selection)
                end

                return
            end
        end
    end

    if item.type == "templates" and allFactories then

        if modifiers.Right then
            -- Options menu
            if button.OptionMenu then
                button.OptionMenu:Destroy()
                button.OptionMenu = nil
            else
                button.OptionMenu = CreateFacTemplateOptionsMenu(button)
            end
            for _, otherBtn in controls.choices.Items do
                if button ~= otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = false
                end
            end
        else
            -- Add template to build queue
            for _, data in ipairs(item.template.templateData) do
                local blueprint = __blueprints[data.id]
                if blueprint.General.UpgradesFrom == 'none' then
                    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", data.id, data.count)
                else
                    IssueBlueprintCommand("UNITCOMMAND_Upgrade", data.id, 1, false)
                end
            end
        end
    elseif item.type == 'item' then
        ClearBuildTemplates()
        local itembp = __blueprints[item.id]
        local count = 1
        local performUpgrade = false
        local buildCmd = "build"

        if modifiers.Ctrl or modifiers.Shift then
            count = 5
        end

        if modifiers.Left then
            -- See if we are issuing an upgrade order
            if itembp.General.UpgradesFrom == 'none' then
                performUpgrade = false
            else
                for i, v in sortedOptions.selection do
                    if v then -- Its possible that your unit will have died by the time this gets to it
                        local unitBp = v:GetBlueprint()
                        if itembp.General.UpgradesFrom == unitBp.BlueprintId then
                            performUpgrade = true
                        elseif itembp.General.UpgradesFrom == unitBp.General.UpgradesTo then
                            performUpgrade = true
                        elseif itembp.General.UpgradesFromBase ~= "none" then
                            -- Try testing against the base
                            if itembp.General.UpgradesFromBase == unitBp.BlueprintId then
                                performUpgrade = true
                            elseif itembp.General.UpgradesFromBase == unitBp.General.UpgradesFromBase then
                                performUpgrade = true
                            end
                        end
                    end
                end
            end

            -- Hold alt to reset queue, same as hotbuild
            if modifiers.Alt then
                ResetOrderQueues(sortedOptions.selection)
            end

            if performUpgrade then
                IssueUpgradeOrders(sortedOptions.selection, item.id)
            else
                local selection = GetSelectedUnits()

                -- separate factories from engineers
                local factories = {}
                local selection = GetSelectedUnits()
                for index, unit in selection do
                    if EntityCategoryContains(categories.FACTORY, unit) then
                        table.insert(factories, unit)
                    end
                end 

                if table.getsize(factories) > 0 then
                    local exFacs = EntityCategoryFilterDown(categories.EXTERNALFACTORY, selection)
                    if not table.empty(exFacs) then
                        local exFacUnits = EntityCategoryFilterOut(categories.EXTERNALFACTORY, selection)
                        for _, exFac in exFacs do
                            table.insert(exFacUnits, exFac:GetCreator())
                        end
                        -- in case we've somehow selected both the platform and the factory, only put the fac in once
                        exFacUnits = table.unique(exFacUnits)
                        IssueBlueprintCommandToUnits(exFacUnits, "UNITCOMMAND_BuildFactory", item.id, count)
                    else
                        IssueBlueprintCommand("UNITCOMMAND_BuildFactory", item.id, count)
                    end
                else
                    import("/lua/ui/game/commandmode.lua").StartCommandMode(buildCmd, {name = item.id})
                end
            end
        else
            local unitIndex = false
            for index, unitStack in currentCommandQueue or {} do
                if unitStack.id == item.id then
                    unitIndex = index
                end
            end
            if unitIndex ~= false then
                DecreaseBuildCountInQueue(unitIndex, count)
            end
        end
        RefreshUI()
    elseif item.type == 'unitstack' then
        if modifiers.Left then
            SelectUnits(item.units)
        elseif modifiers.Right then
            local selection = {}
            for _, unit in sortedOptions.selection do
                local found = false
                for _, checkUnit in item.units do
                    if checkUnit == unit then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(selection, unit)
                end
            end
            SelectUnits(selection)
        end
    elseif item.type == 'attachedunit' then
        if modifiers.Left then
            -- Toggling selection of the entity
            button:ToggleOverride()

            -- Add or Remove the entity to the session selection
            if button:GetOverrideEnabled() then
                AddToSessionExtraSelectList(item.unit)
            else
                RemoveFromSessionExtraSelectList(item.unit)
            end
        end
    elseif item.type == 'templates' then
        ClearBuildTemplates()
        if modifiers.Right then
            if button.OptionMenu then
                button.OptionMenu:Destroy()
                button.OptionMenu = nil
            else
                button.OptionMenu = CreateTemplateOptionsMenu(button)
            end
            for _, otherBtn in controls.choices.Items do
                if button ~= otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = false
                end
            end
        else
            import("/lua/ui/game/commandmode.lua").StartCommandMode('build', {name = item.template.templateData[3][1]})
            SetActiveBuildTemplate(item.template.templateData)
        end

    elseif item.type == 'enhancement' and button.Data.TooltipOnly == false then
        local doOrder = true
        local clean = not modifiers.Shift
        local enhancementQueue = getEnhancementQueue()

        local enhId = item.id
        local enh = item.enhTable
        local slot = enh.Slot
        local prereqs = GetPrerequisites(enh)
        for _, unit in sortedOptions.selection do
            local unitId = unit:GetEntityId()
            local existingEnhancements = EnhanceCommon.GetEnhancements(unitId)
            local existingEnh = existingEnhancements[slot]
            if not existingEnh or table.find(prereqs, existingEnh) then
                continue
            end

            local alreadyWarned = false
            for _, enhancement in enhancementQueue[unitId] or {} do
                if enhancement.ID == existingEnh .. 'Remove' then
                    alreadyWarned = true
                    break
                end
            end
            if alreadyWarned then
                continue
            end

            if existingEnh ~= enhId then
                UIUtil.QuickDialog(GetFrame(0), "<LOC enhancedlg_0000>Choosing this enhancement will destroy the existing enhancement in this slot.  Are you sure?",
                    "<LOC _Yes>", function()
                        safecall("OrderEnhancement", OrderEnhancement, item, clean, true)
                    end,
                    "<LOC _No>", function()
                        safecall("OrderEnhancement", OrderEnhancement, item, clean, false)
                    end,
                    nil, nil,
                    true,  {worldCover = true, enterButton = 1, escapeButton = 2}
                )
                doOrder = false
                break
            end
        end

        if doOrder then
            OrderEnhancement(item, clean, false)
        end
    elseif item.type == 'queuestack' then
        local count = 1
        if modifiers.Shift or modifiers.Ctrl then
            count = 5
        end

        if modifiers.Left then
            IncreaseBuildCountInQueue(item.position, count)
            
        elseif modifiers.Right then
            DecreaseBuildCountInQueue(item.position, count)
        end
        RefreshUI()
    end
end

function CommonLogic()
    controls.choices:SetupScrollControls(controls.scrollMin, controls.scrollMax, controls.pageMin, controls.pageMax)
    controls.secondaryChoices:SetupScrollControls(controls.secondaryScrollMin, controls.secondaryScrollMax, controls.secondaryPageMin, controls.secondaryPageMax)

    controls.secondaryProgress:SetNeedsFrameUpdate(true)
    controls.secondaryProgress.OnFrame = function(self, delta)
        local frontOfQueue = sortedOptions.selection[1]
        if not frontOfQueue or frontOfQueue:IsDead() then
            return
        end

        controls.secondaryProgress:SetValue(frontOfQueue:GetWorkProgress() or 0)
        if controls.secondaryChoices.top == 1 and not controls.selectionTab:IsChecked() and not controls.constructionGroup:IsHidden() then
            self:SetAlpha(1, true)
        else
            self:SetAlpha(0, true)
        end
    end

    controls.secondaryChoices.SetControlToType = function(control, type)
        local function SetIconTextures(control)
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. control.Data.id .. '_icon.dds', true)) then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/' .. control.Data.id .. '_icon.dds', true))
            else
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            if __blueprints[control.Data.id].StrategicIconName then
                local iconName = __blueprints[control.Data.id].StrategicIconName
                if DiskGetFileInfo('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds') then
                    control.StratIcon:SetTexture('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds')
                    LayoutHelpers.SetDimensions(control.StratIcon, control.StratIcon.BitmapWidth(), control.StratIcon.BitmapHeight())
                    --control.StratIcon.Height:Set(control.StratIcon.BitmapHeight)
                    --control.StratIcon.Width:Set(control.StratIcon.BitmapWidth)
                else
                    control.StratIcon:SetSolidColor('ff00ff00')
                end
            else
                control.StratIcon:SetSolidColor('00000000')
            end
        end

        if type == 'spacer' then
            if controls.secondaryChoices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_horizontal_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 48, 20)
                --control.Width:Set(48)
                --control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 20, 48)
                --control.Width:Set(20)
                --control.Height:Set(48)
            end
            LayoutHelpers.SetDimensions(control.Icon, control.Icon.BitmapWidth(), control.Icon.BitmapHeight())
            --control.Icon.Width:Set(control.Icon.BitmapWidth)
            --control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Count:SetText('')
            control:Disable()
            control.StratIcon:SetSolidColor('00000000')
            control:SetSolidColor('00000000')
            control.BuildKey = nil
        elseif type == 'queuestack' or type == 'attachedunit' then
            SetIconTextures(control)
            local up, down, over, dis = GetBackgroundTextures(control.Data.id)
            control:SetNewTextures(up, down, over, dis)
            control:SetOverrideTexture(down)
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control:DisableOverride()
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.BuildKey = nil
            if control.Data.count > 1 then
                control.Count:SetText(control.Data.count)
                control.Count:SetColor('ffffffff')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
        elseif type == 'enhancementqueue' then
            local data = control.Data
            local _, down, over, _, up = GetEnhancementTextures(data.unitID, data.icon)

            control:SetSolidColor('00000000')
            control.Icon:SetSolidColor('00000000')
            control.tooltipID = data.name
            control:SetNewTextures(GetEnhancementTextures(data.unitID, data.icon))
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.StratIcon:SetSolidColor('00000000')
            control.Count:SetText('')

            if control.SetOverrideTexture then
                control:SetOverrideTexture(up)
            else
                control:SetUpAltButtons(up, up, up, up)
            end

            control:Disable()
            control.Icon:Show()
            control:Enable()
        end
    end

    controls.secondaryChoices.CreateElement = function()
        local btn = FixableButton(controls.choices)

        btn.Icon = Bitmap(btn)
        btn.Icon:DisableHitTest()
        LayoutHelpers.AtCenterIn(btn.Icon, btn)

        btn.StratIcon = Bitmap(btn.Icon)
        btn.StratIcon:DisableHitTest()
        LayoutHelpers.AtTopIn(btn.StratIcon, btn.Icon, 4)
        LayoutHelpers.AtLeftIn(btn.StratIcon, btn.Icon, 4)

        btn.Count = UIUtil.CreateText(btn.Icon, '', 20, UIUtil.bodyFont)
        btn.Count:SetColor('ffffffff')
        btn.Count:SetDropShadow(true)
        btn.Count:DisableHitTest()
        LayoutHelpers.AtBottomIn(btn.Count, btn, 4)
        LayoutHelpers.AtRightIn(btn.Count, btn, 3)
        btn.Count.Depth:Set(function() return btn.Icon.Depth() + 10 end)

        btn.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                PlaySound(Sound({Cue = "UI_MFD_Rollover", Bank = "Interface"}))
                Tooltip.CreateMouseoverDisplay(self, self.tooltipID, nil, false)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            return Button.HandleEvent(self, event)
        end

        btn.OnRolloverEvent = OnRolloverHandler
        btn.OnClick = OnClickHandler

        return btn
    end

    controls.choices.CreateElement = function()
        local btn = FixableButton(controls.choices)

        btn.Icon = Bitmap(btn)
        btn.Icon:DisableHitTest()
        LayoutHelpers.AtCenterIn(btn.Icon, btn)

        btn.StratIcon = Bitmap(btn.Icon)
        btn.StratIcon:DisableHitTest()
        LayoutHelpers.AtTopIn(btn.StratIcon, btn.Icon, 4)
        LayoutHelpers.AtLeftIn(btn.StratIcon, btn.Icon, 4)

        btn.Count = UIUtil.CreateText(btn.Icon, '', 20, UIUtil.bodyFont)
        btn.Count:SetColor('ffffffff')
        btn.Count:SetDropShadow(true)
        btn.Count:DisableHitTest()
        LayoutHelpers.AtBottomIn(btn.Count, btn)
        LayoutHelpers.AtRightIn(btn.Count, btn)
        btn.LowFuel = Bitmap(btn)
        btn.LowFuel:SetSolidColor('ffff0000')
        btn.LowFuel:DisableHitTest()
        LayoutHelpers.FillParent(btn.LowFuel, btn)
        btn.LowFuel:SetAlpha(0)
        btn.LowFuel:DisableHitTest()
        btn.LowFuel.Incrementing = 1

        btn.LowFuelIcon = Bitmap(btn.LowFuel, UIUtil.UIFile('/game/unit_view_icons/fuel.dds'))
        LayoutHelpers.AtLeftIn(btn.LowFuelIcon, btn, 4)
        LayoutHelpers.AtBottomIn(btn.LowFuelIcon, btn, 4)
        btn.LowFuelIcon:DisableHitTest()

        btn.LowFuel.OnFrame = function(glow, elapsedTime)
            local curAlpha = glow:GetAlpha()
            curAlpha = curAlpha + (elapsedTime * glow.Incrementing)
            if curAlpha > .4 then
                curAlpha = .4
                glow.Incrementing = -1
            elseif curAlpha < 0 then
                curAlpha = 0
                glow.Incrementing = 1
            end
            glow:SetAlpha(curAlpha)
        end

        btn.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                PlaySound(Sound({Cue = "UI_MFD_Rollover", Bank = "Interface"}))
                Tooltip.CreateMouseoverDisplay(self, self.tooltipID, nil, false)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            return Button.HandleEvent(self, event)
        end
        btn.OnRolloverEvent = OnRolloverHandler
        btn.OnClick = OnClickHandler

        return btn
    end

    local key = nil
    local id = nil

    controls.choices.SetControlToType = function(control, type)
        local function SetIconTextures(control, optID)
            local id = optID or control.Data.id
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. id .. '_icon.dds', true)) then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/' .. id .. '_icon.dds', true))
            else
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            if __blueprints[id].StrategicIconName then
                local iconName = __blueprints[id].StrategicIconName
                if DiskGetFileInfo('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds') then
                    control.StratIcon:SetTexture('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds')
                    LayoutHelpers.SetDimensions(control.StratIcon, control.StratIcon.BitmapWidth(), control.StratIcon.BitmapHeight())
                    --control.StratIcon.Height:Set(control.StratIcon.BitmapHeight)
                    --control.StratIcon.Width:Set(control.StratIcon.BitmapWidth)
                else
                    control.StratIcon:SetSolidColor('ff00ff00')
                end
            else
                control.StratIcon:SetSolidColor('00000000')
            end
        end

        if type == 'arrow' then
            control.Count:SetText('')
            control:Disable()
            control:SetSolidColor('00000000')
            if controls.choices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/arrow_vert_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 48, 20)
                --control.Width:Set(48)
                --control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/arrow_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 20, 48)
                --control.Width:Set(20)
                --control.Height:Set(48)
            end
            control.Icon.Depth:Set(function() return control.Depth() + 5 end)
            LayoutHelpers.SetDimensions(control.Icon, 30, control.Icon.BitmapHeight())
            --control.Icon.Height:Set(control.Icon.BitmapHeight)
            --control.Icon.Width:Set(30)
            control.Icon:Show()
            control.StratIcon:SetSolidColor('00000000')
            control.StratIcon:Hide()
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
        elseif type == 'spacer' then
            if controls.choices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_horizontal_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 48, 20)
                --control.Width:Set(48)
                --control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 20, 48)
                --control.Width:Set(20)
                --control.Height:Set(48)
            end
            LayoutHelpers.SetDimensions(control.Icon, control.Icon.BitmapWidth(), control.Icon.BitmapHeight())
            --control.Icon.Width:Set(control.Icon.BitmapWidth)
            --control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Count:SetText('')
            control:Disable()
            control.StratIcon:SetSolidColor('00000000')
            control:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
        elseif type == 'enhancement' then
            control.Icon:SetSolidColor('00000000')
            local up, down, over, _, selected = GetEnhancementTextures(control.Data.unitID, control.Data.icon)
            control:SetNewTextures(up, down, over, up)
            control:SetOverrideTexture(selected)
            control.tooltipID = LOC(control.Data.enhTable.Name) or 'no description'
            control:SetOverrideEnabled(control.Data.Selected)
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.Count:SetText('')
            control.StratIcon:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
            if control.Data.Disabled then
                control:Enable()
                control.Data.TooltipOnly = true
                if not control.Data.Selected then
                    control.Icon:SetSolidColor('aa000000')
                end
            else
                control.Data.TooltipOnly = false
                control:Enable()
            end
        elseif type == 'templates' then
            control:DisableOverride()
            SetIconTextures(control, control.Data.template.icon)
            control:SetNewTextures(GetBackgroundTextures(control.Data.template.icon))
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            if control.Data.template.icon then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/' .. control.Data.template.icon .. '_icon.dds', true))
            else
                control.Icon:SetTexture('/textures/ui/common/icons/units/default_icon.dds')
            end
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.StratIcon:SetSolidColor('00000000')
            control.tooltipID = control.Data.template.name or 'no description'
            control.BuildKey = control.Data.template.key
            if showBuildIcons and control.Data.template.key then
                control.Count:SetText(string.char(control.Data.template.key) or '')
                control.Count:SetColor('ffff9000')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
        elseif type == 'item' then
            local id = control.Data.id
            SetIconTextures(control)
            control:SetNewTextures(GetBackgroundTextures(id))
            local _, down = GetBackgroundTextures(id)
            control.tooltipID = LOC(__blueprints[id].Description) or 'no description'
            control:SetOverrideTexture(down)
            control:DisableOverride()
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.BuildKey = nil
            if showBuildIcons then
                local unitBuildKeys = BuildMode.GetUnitKeys(sortedOptions.selection[1]:GetBlueprint().BlueprintId, GetCurrentTechTab())
                control.Count:SetText(unitBuildKeys[id] or '')
                control.Count:SetColor('ffff9000')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)

            if id == upgradesTo and upgradeKey then
                hotkeyLabel_addLabel(control, control.Icon, upgradeKey)
            elseif allowOthers or upgradesTo == nil then
                local key = idRelations[id]
                if key then
                    hotkeyLabel_addLabel(control, control.Icon, key)
                end
            end
        elseif type == 'unitstack' then
            SetIconTextures(control)
            control:SetNewTextures(GetBackgroundTextures(control.Data.id))
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control:DisableOverride()
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.LowFuel:SetAlpha(0, true)
            control.BuildKey = nil
            if control.Data.lowFuel then
                control.LowFuel:SetNeedsFrameUpdate(true)
                control.LowFuelIcon:SetAlpha(1)
            else
                control.LowFuel:SetNeedsFrameUpdate(false)
            end
            if table.getn(control.Data.units) > 1 then
                control.Count:SetText(table.getn(control.Data.units))
                control.Count:SetColor('ffffffff')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
        end
    end
    if options.gui_bigger_strat_build_icons ~= 0 then
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        -- Add idle icon to buttons
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
            btn.IdleIcon = Bitmap(btn.Icon, UIUtil.SkinnableFile('/game/idle_mini_icon/idle_icon.dds'))
            LayoutHelpers.AtBottomIn(btn.IdleIcon, btn)
            LayoutHelpers.AtLeftIn(btn.IdleIcon, btn)
            btn.IdleIcon:DisableHitTest()
            btn.IdleIcon:SetAlpha(0)
            return btn
        end
        controls.secondaryChoices.SetControlToType = function(control, type)
            oldSecondary(control, type)
            if control.StratIcon.Underlay then
                control.StratIcon.Underlay:Hide()
            end
            StratIconReplacement(control)
        end
        controls.choices.SetControlToType = function(control, type)
            oldPrimary(control, type)
            if control.StratIcon.Underlay then
                control.StratIcon.Underlay:Hide()
            end
            StratIconReplacement(control)

            -- AZ improved selection code
            if type == 'unitstack' and control.Data.idleCon then
                control.IdleIcon:SetAlpha(1)
            end
        end
    else -- If we dont have bigger strat icons selected, just do the idle icon
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        -- Add idle icon to buttons
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
            btn.IdleIcon = Bitmap(btn.Icon, UIUtil.SkinnableFile('/game/idle_mini_icon/idle_icon.dds'))
            LayoutHelpers.AtBottomIn(btn.IdleIcon, btn)
            LayoutHelpers.AtLeftIn(btn.IdleIcon, btn)
            btn.IdleIcon:DisableHitTest()
            btn.IdleIcon:SetAlpha(0)
            return btn
        end

        controls.secondaryChoices.SetControlToType = function(control, type)
            oldSecondary(control, type)
        end

        controls.choices.SetControlToType = function(control, type)
            oldPrimary(control, type)
            -- AZ improved selection code
            if type == 'unitstack' and control.Data.idleCon then
                control.IdleIcon:SetAlpha(1)
            end
        end
    end

    if options.gui_visible_template_names ~= 0 then
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
            -- Create the display area
            btn.Tmplnm = UIUtil.CreateText(btn.Icon, '', 11, UIUtil.bodyFont)
            btn.Tmplnm:SetColor('ffffff00')
            btn.Tmplnm:DisableHitTest()
            btn.Tmplnm:SetDropShadow(true)
            btn.Tmplnm:SetCenteredHorizontally(true)
            LayoutHelpers.CenteredBelow(btn.Tmplnm, btn, 0)
            btn.Tmplnm.Depth:Set(function() return btn.Icon.Depth() + 10 end)
            return btn
        end
        controls.secondaryChoices.SetControlToType = function(control, type)
            oldSecondary(control, type)
        end
        controls.choices.SetControlToType = function(control, type)
            oldPrimary(control, type)
            -- The text
            if type == 'templates' and 'templates' then
                control.Tmplnm.Width:Set(48)
                if STR_Utf8Len(control.Data.template.name) >= cutA then
                    control.Tmplnm:SetText(STR_Utf8SubString(control.Data.template.name, cutA, cutB))
                end
            end
        end
    end
end

function BuildTemplate(key, modifiers)
    for _, item in controls.choices.Items do
        if item.BuildKey == key then
            OnClickHandler(item, modifiers)
            return true
        end
    end
    return false
end

function FormatData(unitData, type)
    local retData = {}
    if type == 'construction' then
        local function SortFunc(unit1, unit2)
            local bp1 = __blueprints[unit1]
            local bp2 = __blueprints[unit2]
            local v1 = bp1.BuildIconSortPriority or bp1.StrategicIconSortPriority
            local v2 = bp2.BuildIconSortPriority or bp2.StrategicIconSortPriority

            if v1 >= v2 then
                return false
            else
                return true
            end
        end

        local sortedUnits = {}
        local sortCategories = {
            categories.SORTCONSTRUCTION,
            categories.SORTECONOMY,
            categories.SORTDEFENSE,
            categories.SORTSTRATEGIC,
            categories.SORTINTEL,
            categories.SORTOTHER,
        }
        local miscCats = categories.ALLUNITS
        local borders = {}
        for i, v in sortCategories do
            local category = v
            local index = i - 1
            local tempIndex = i
            while index > 0 do
                category = category - sortCategories[index]
                index = index - 1
            end
            local units = EntityCategoryFilterDown(category, unitData)
            table.insert(sortedUnits, units)
            miscCats = miscCats - v
        end

        miscCats = miscCats - categories.LAND - categories.AIR - categories.NAVAL + categories.CRABEGG

        table.insert(sortedUnits, EntityCategoryFilterDown(categories.LAND - categories.STRUCTURE, unitData))
        table.insert(sortedUnits, EntityCategoryFilterDown(categories.AIR - categories.STRUCTURE, unitData))
        table.insert(sortedUnits, EntityCategoryFilterDown(categories.NAVAL - categories.STRUCTURE, unitData))

        table.insert(sortedUnits, EntityCategoryFilterDown(miscCats, unitData))

        -- Get function for checking for restricted units
        local IsRestricted = import("/lua/game.lua").IsRestricted

        -- This section adds the arrows in for a build icon which is an upgrade from the
        -- selected unit. If there is an upgrade chain, it will display them split by arrows.
        -- I'm excluding Factories from this for now, since the chain of T1 -> T2 HQ -> T3 HQ
        -- or T1 -> T2 Support -> T3 Support is not supported yet by the code which actually
        -- looks up, stores, and executes the upgrade chain. This needs doing for 3654.
        local unitSelected = sortedOptions.selection[1]
        local isStructure = EntityCategoryContains(categories.STRUCTURE - (categories.FACTORY + categories.EXTERNALFACTORY), unitSelected)

        for i, units in sortedUnits do
            table.sort(units, SortFunc)
            local index = i
            if not table.empty(units) then
                if not table.empty(retData) then
                    table.insert(retData, {type = 'spacer'})
                end

                for index, unit in units do
                    -- Show UI data/icons only for not restricted units
                    local restrict = false
                    if not IsRestricted(unit, GetFocusArmy()) then
                        local bp = __blueprints[unit]
                        -- Check if upgradeable structure
                        if isStructure and
                                bp and bp.General and
                                bp.General.UpgradesFrom and
                                bp.General.UpgradesFrom ~= 'none' then

                            restrict = IsRestricted(bp.General.UpgradesFrom, GetFocusArmy())
                            if not restrict then
                                table.insert(retData, {type = 'arrow'})
                            end
                        end

                        if not restrict then
                            table.insert(retData, {type = 'item', id = unit})
                        end
                    end
                end
            end
        end

        CreateExtraControls('construction')
        SetSecondaryDisplay('buildQueue')
    elseif type == 'selection' then
        local sortedUnits = {
            [1] = {cat = "ALLUNITS", units = {}},
            [2] = {cat = "LAND", units = {}},
            [3] = {cat = "AIR", units = {}},
            [4] = {cat = "NAVAL", units = {}},
            [5] = {cat = "STRUCTURE", units = {}},
            [6] = {cat = "SORTCONSTRUCTION", units = {}},
        }

        local lowFuelUnits = {}
        local idleConsUnits = {}

        for _, unit in unitData do
            local id = unit:GetBlueprint().BlueprintId

            if unit:IsInCategory('AIR') and unit:GetFuelRatio() < .2 and unit:GetFuelRatio() > -1 then
                if not lowFuelUnits[id] then
                    lowFuelUnits[id] = {}
                end
                table.insert(lowFuelUnits[id], unit)
            elseif options.gui_seperate_idle_builders ~= 0 and unit:IsInCategory('CONSTRUCTION') and unit:IsIdle() then
                if not idleConsUnits[id] then
                    idleConsUnits[id] = {}
                end
                table.insert(idleConsUnits[id], unit)
            else
                local cat = 0
                for i, t in sortedUnits do
                    if unit:IsInCategory(t.cat) then
                        cat = i
                    end
                end

                if not sortedUnits[cat].units[id] then
                    sortedUnits[cat].units[id] = {}
                end

                table.insert(sortedUnits[cat].units[id], unit)
            end
        end

        local function insertSpacer(didPutUnits)
            if didPutUnits then
                table.insert(retData, {type = 'spacer'})
                return not didPutUnits
            end
        end

        -- Sort selected units into order and insert spaces
        local didPutUnits = false
        for _, t in sortedUnits do
            didPutUnits = insertSpacer(didPutUnits)

            retData, didPutUnits = insertIntoTableLowestTechFirst(t.units, retData, false, false)
        end

        -- Split out low fuel
        didPutUnits = insertSpacer(didPutUnits)
        retData, didPutUnits = insertIntoTableLowestTechFirst(lowFuelUnits, retData, true, false)

        -- Split out idle constructors
        didPutUnits = insertSpacer(didPutUnits)
        retData, didPutUnits = insertIntoTableLowestTechFirst(idleConsUnits, retData, false, true)

        -- Remove trailing spacer if there is one
        if retData[table.getn(retData)].type == 'spacer' then
            table.remove(retData, table.getn(retData))
        end

        CreateExtraControls('selection')
        SetSecondaryDisplay('attached')

        import(UIUtil.GetLayoutFilename('construction')).OnTabChangeLayout(type)
    elseif type == 'templates' then
        if unitData then
            table.sort(unitData, function(a, b)
                if a.key and not b.key then
                    return true
                elseif b.key and not a.key then
                    return false
                elseif a.key and b.key then
                    return a.key <= b.key
                elseif a.name == b.name then
                    return false
                else
                    if LOC(a.name) <= LOC(b.name) then
                        return true
                    else
                        return false
                    end
                end
            end)
            for _, v in unitData do
                table.insert(retData, {type = 'templates', id = 'template', template = v})
            end
        end
        CreateExtraControls('templates')
        SetSecondaryDisplay('buildQueue')
    else
        -- Enhancements
        local existingEnhancements = EnhanceCommon.GetEnhancements(sortedOptions.selection[1]:GetEntityId())
        local enhancementQueue
        if table.getn(sortedOptions.selection) == 1 then
            enhancementQueue = getEnhancementQueue()[sortedOptions.selection[1]:GetEntityId()] or {}
        end

        -- Filter enhancements based on restrictions
        local restEnh = EnhanceCommon.GetRestricted()
        local filteredEnh = {}
        local totalEnhancements = 0
        for _, enhTable in unitData do
            local enhId = enhTable.ID
            if not restEnh[enhId] and not enhId:find("Remove") then
                totalEnhancements = totalEnhancements + 1
                filteredEnh[totalEnhancements] = enhTable
            end
        end

        local function FindDependency(id)
            for _, enh in filteredEnh do
                if enh.Prerequisite == id then
                    return enh
                end
            end
        end

        local function AddEnhancement(enhTable)
            local iconData = {
                type = 'enhancement',
                enhTable = enhTable,
                unitID = enhTable.UnitID,
                id = enhTable.ID,
                icon = enhTable.Icon,
                Selected = false,
                Disabled = false,
            }
            if enhancementQueue then
                local slot = enhTable.Slot
                if existingEnhancements[slot] == enhTable.ID then
                    iconData.Selected = true
                end
                local prereqs = GetPrerequisites(enhTable)
                for _, queuedEnh in enhancementQueue do
                    if queuedEnh.Slot == slot and not table.find(prereqs, queuedEnh.ID) and not queuedEnh.ID:find("Remove") then
                        iconData.Disabled = true
                        break
                    end
                end
            end
            table.insert(retData, iconData)
        end

        local usedEnhancements = {}
        local totalUsed = 0
        for _, enhTable in filteredEnh do
            local enhId = enhTable.ID
            if usedEnhancements[enhId] or enhTable.Prerequisite then
                continue
            end

            AddEnhancement(enhTable)
            usedEnhancements[enhId] = true

            local curEnh = FindDependency(enhId)
            while curEnh do
                table.insert(retData, {type = 'arrow'})
                AddEnhancement(curEnh)
                usedEnhancements[curEnh.ID] = true
                totalUsed = totalUsed + 1
                curEnh = FindDependency(curEnh.ID)
            end
            if totalUsed < totalEnhancements then
                table.insert(retData, {type = 'spacer'})
            end
        end

        CreateExtraControls('enhancement')
        SetSecondaryDisplay('buildQueue')
    end

    import(UIUtil.GetLayoutFilename('construction')).OnTabChangeLayout(type)

    if type == 'templates' and allFactories then
        -- Replace Infinite queue with Create template
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'save_template')
        if not table.empty(currentCommandQueue) then
            controls.extraBtn1:Enable()
            controls.extraBtn1.OnClick = function(self, modifiers)
                TemplatesFactory.CreateBuildTemplate(currentCommandQueue)
            end
        else
            controls.extraBtn1:Disable()
        end
        controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/template_on.dds')
        controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/template_off.dds')
        if controls.extraBtn1:IsDisabled() then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        else
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end
    end


    return retData
end