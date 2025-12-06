-- TODO: IMPLEMENT THESE
-- actions.MPSave = msimport('code/ui/actions.lua').CreateSaveDialog(GetFrame(0))
-- actions.MPLoad = msimport('code/ui/actions.lua').CreateLoadDialog(GetFrame(0))


--local saveMenu = import('../../hook/lua/ui/dialogs/saveload.lua')
-- local loadMenu = import('../../hook/lua/ui/dialogs/saveload.lua')

local saveMenu = import('/lua/ui/dialogs/saveload.lua')
local loadMenu = import('/lua/ui/dialogs/saveload.lua')

function CreateSaveDialog(parent)
    saveMenu.CreateSaveDialog(parent, nil, 'MultiplayerSave')
end

function CreateLoadDialog(parent)
    loadMenu.CreateLoadDialog(parent, nil, 'MultiplayerSave')
    -- loadMenu.CreateLoadDialog(parent)
end
