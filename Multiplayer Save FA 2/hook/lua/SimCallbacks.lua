-- Callbacks for handling save data in the sim
LOG('SAVE/LOAD: Registering sim callbacks')
Callbacks.SaveGame = msimport('code/sim/save.lua').SaveGame
Callbacks.LoadGame = msimport('code/sim/save.lua').LoadGame
Callbacks.LoadGame_SendDataChunks = msimport('code/sim/save.lua').LoadGame_SendDataChunks