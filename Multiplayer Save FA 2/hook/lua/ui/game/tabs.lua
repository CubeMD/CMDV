
-- Add save/load to MP game menu
table.insert(menus.main.lan, 1, {
            action = 'Load',
            label = '<LOC _Load_Game>Load Game',
            tooltip = 'esc_load',
})
table.insert(menus.main.lan, 1, {
            action = 'Save',
            disableOnGameOver = true,
            label = '<LOC _Save_Game>Save Game',
            tooltip = 'esc_save',
})

table.insert(menus.main.gpgnet, 1, {
            action = 'Load',
            label = '<LOC _Load_Game>Load Game',
            tooltip = 'esc_load',
})
table.insert(menus.main.gpgnet, 1, {
            action = 'Save',
            disableOnGameOver = true,
            label = '<LOC _Save_Game>Save Game',
            tooltip = 'esc_save',
})

-- add Save and Load actions
actions.MPSave = msimport('code/ui/actions.lua').CreateSaveDialog(GetFrame(0))
actions.MPLoad = msimport('code/ui/actions.lua').CreateLoadDialog(GetFrame(0))