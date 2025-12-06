-- Multiplayer Save: Fix for broken exitBehaviour not closing window. Normally not an issue because GPG's load rebuilds the whole UI
-- local base = import('/lua/ui/dialogs/saveload.lua')


function CreateLoadDialog(parent, exitBehavior, fileType)
    local function DoLoad(fileInfo, lparent, killBehavior)
        SetFrontEndData('NextOpBriefing', nil)
        local worked, error, detail = LoadSavedGame(fileInfo.fspec)
        if not worked then
            UIUtil.ShowInfoDialog(lparent,
                                  -- note - the 'Unknown error...' string below is intentionally not localized because
                                  -- it should never show up.  If it does, add the error string to SaveErrors.
                                  LOCF(SaveErrors[error] or ('Unknown error ' .. repr(error) .. 'loading savegame %s: %s'),
                                       Basename(fileInfo.fspec, true),
                                       InternalErrors[detail] or detail),
                                  "<LOC _Ok>")
        else
            if parent then
		-- MP SAVE: Fix for GPG bug. Destroy() doesn't work.
                --parent:Destroy()
		killBehavior(true)
            end
            MenuCommon.MenuCleanup()
        end
    end
    dlg = CreateDialog(parent, true, DoLoad, exitBehavior, fileType)
end


-- -- Multiplayer Save: Fix for broken exitBehaviour not closing window. Normally not an issue because GPG's load rebuilds the whole UI
-- function CreateSaveDialog(parent, exitBehavior, fileType)
--     LOG('MultiplayerSave DEBUG: : WHAHTHAH!')
--     local function DoSave(fileInfo, lparent, killBehavior)

--         LOG('MultiplayerSave DEBUG: : Must implement DoSave!')
--         -- PROBS COPY FROM THE LOADMENU ONE
--     end
    
--     dlg = CreateSaveDialog(parent, true, DoSave, exitBehavior, fileType)
-- end
