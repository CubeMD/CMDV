--- START OF FILE gamemain.txt ---

local originalCreateUI = CreateUI
local originalSetLayout = SetLayout

-- Deadlock Control State
local DeadlockMode = true
local DeadlockThread = nil

function CreateUI(isReplay)
    originalCreateUI(isReplay)
    InitSharedMouse(isReplay)
    
    -- Initialize Deadlock Controls
    if not isReplay then
        DeadlockThread = ForkThread(DeadlockControlLoop)
    end
end

playersUI = false
function SetLayout(layout)
	originalSetLayout(layout)
	if not playersUI then return end
	SetPlayerSelectionLayout()
end

local modPath = {
	textures = '/mods/PMS/textures/',
	cursors = '/mods/PMS/textures/cursors/'
}
local sharedWith = {}

-- ... (Existing SharedMouse Code preserved below) ...

local WorldLabel = Class(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent
        self.Top:Set(0)
        self.Left:Set(0)
        self.position = {0,0,0}
        LayoutHelpers.SetDimensions(self, 25, 25)
        self:SetNeedsFrameUpdate(true)
    end,

    Update = function(self)
    end,

    OnFrame = function(self, delta)
        self:Update()
    end
}

local function CreateWorldLabel(parent, player, texture)
    local label = WorldLabel(parent)

    label.icon = Bitmap(label)
    label.icon:SetTexture(texture)
	
    LayoutHelpers.AtCenterIn(label.icon, label)
    LayoutHelpers.SetDimensions(label.icon, 25, 25)

    label.text = UIUtil.CreateText(label, player.nickname, 12, UIUtil.bodyFont)
	label.text:SetColor(player.color)
    label.text:SetDropShadow(true)
    LayoutHelpers.CenteredBelow(label.text, label.icon)

    label:DisableHitTest(true)
    label.icon:DisableHitTest(true)
    label.text:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end

    label.Update = function(self)
        local view = self.parent
        local proj = view:Project(self.position)
        LayoutHelpers.AtLeftTopIn(self, self.parent, (proj.x - self.Width() / 2) / LayoutHelpers.GetPixelScaleFactor(), (proj.y - self.Height() / 2 + 1) / LayoutHelpers.GetPixelScaleFactor())
    end
	
    return label
end

local OrdersToNum = {
	["selectable"] = 1,
	["selectable-invalid"] = 2,
	["attack"] = 3,
	["attack-invalid"] = 4,
	["attack_coordinated"] = 5,
	["capture"] = 6,
	["capture-invalid"] = 7,
	["construct"] = 8,
	["construct-invalid"] = 9,
	["ferry"] = 10,
	["ferry-invalid"] = 11,
	["guard"] = 12,
	["guard-invalid"] = 13,
	["launc"] = 14, -- to launch
	["launch-invalid"] = 15,
	["load"] = 16,
	["load-invalid"] = 17,
	["message"] = 18, -- to message-01
	["move"] = 19,
	["move-invalid"] = 20,
	["move_window"] = 21,
	["n_s"] = 22,
	["ne_sw"] = 23,
	["nw_se"] = 24,
	["w_e"] = 25,
	["overcharge_grey"] = 26, -- to overcharge-06 / overcharge
	["patrol"] = 27,
	["patrol-invalid"] = 28,
	["reclaim02"] = 29,
	["reclaim-invalid"] = 30,
	["repair"] = 31,
	["repair-invalid"] = 32,
	["sacrifice"] = 33,
	["transport"] = 34,
	["transport-invalid"] = 35,
	["unload"] = 36,
	["unload-invalid"] = 37,
	["waypoint-drag"] = 38,
	["waypoint-hover"] = 39,
	["attack_move"] = 3, -- to attack[3]
	["attack-coordinated-invalid"] = 40
}
local NumToOrders = {
	"selectable",
	"selectable-invalid",
	"attack",
	"attack-invalid",
	"attack_coordinated",
	"capture",
	"capture-invalid",
	"construct",
	"construct-invalid",
	"ferry",
	"ferry-invalid",
	"guard",
	"guard-invalid",
	"launch",
	"launch-invalid",
	"load",
	"load-invalid",
	"message-01", -- no message.dds
	"move",
	"move-invalid",
	"move_window",
	"n_s",
	"ne_sw",
	"nw_se",
	"w_e",
	"overcharge-06", -- no overcharge.dds
	"patrol",
	"patrol-invalid",
	"reclaim",
	"reclaim-invalid",
	"repair",
	"repair-invalid",
	"sacrifice",
	"transport",
	"transport-invalid",
	"unload",
	"unload-invalid",
	"waypoint-drag",
	"waypoint-hover",
	"attack_move",
	"attack-coordinated-invalid"
}

function InitSharedMouse(isReplay)
    if isReplay then
		LOG('Gameplay sharing currently is not supported in replay')
        return
    end
    local view = import("/lua/ui/game/worldview.lua").viewLeft
    
	local armies = GetArmiesTable().armiesTable
	
    local i = 1
	
	local cursor = GetCursor()
	
    local me = GetFocusArmy()
	local myName = armies[me].nickname
	
	local function CreatePlayerSharing(player)
		local mouse = CreateWorldLabel(view, player, modPath.cursors..player.color..'.png')
		mouse.order = "selectable"
		mouse.color = player.color
		
		mouse.UpdateCursor = function(self, data)
			self.position = {data[1], data[2], data[3]}
			local newOrder = NumToOrders[data[4]] or 'selectable'
			if self.order == newOrder then return end
			if newOrder == "selectable" then
				self.icon:SetTexture(modPath.cursors..self.color..'.png')
			else
				self.icon:SetTexture("/textures/ui/common/game/cursors/"..newOrder..".dds")
			end
			self.order = newOrder
		end
		
		sharedWith[player.nickname] = {
			mouse = mouse
		}
	end
	local enemies = {}
	-- register allies shared stuff before start
	for id, player in armies do
		if player.nickname ~= myName and player.human then
			if IsAlly(me, id) then
				CreatePlayerSharing(player)
			else
				enemies[player.nickname] = 1
			end
		end
	end
	
	local clients = {}
	for index, client in GetSessionClients() do
		if client.name ~= myName then
			if me ~= -1 then
				if not enemies[client.name] then
					clients[index] = index
				end
			else
				clients[index] = index
			end
		end
	end
	
    if table.empty(sharedWith) then
        LOG("No allies to share with")
		if table.empty(clients) then
			LOG("No observers to share with")
			return
		end
    end
	
	-- lets save order for sharing
	cursor.SetTexture = function(self, filename, hotspotX, hotspotY, numFrames, fps)
        local hotspotX = hotspotX or 0
        local hotspotY = hotspotY or 0
        self._hotspotX = hotspotX
        self._hotspotY = hotspotY

        KillThread(self._animThread)
        local extPos = string.find(filename, ".dds")
        if numFrames and numFrames != 1 then
            local curFrame = 1
            filename = string.sub(filename, 1, extPos - 1)
            self._animThread = ForkThread(function()
                while true do
                    self._filename:Set(string.format("%s%02d.dds", filename, tostring(curFrame)))
                    curFrame = curFrame + 1
                    if curFrame > numFrames then
                        curFrame = 1
                    end
                    WaitSeconds(1/fps)
                end
            end)
        else
            self._filename:Set(filename)
        end
		self.order = string.sub(filename, 34, extPos - 2)
    end

	-- lets clear our reserved order on cancel to default
	cursor.Reset = function(self)
        if self._animThread then
            KillThread(self._animThread)
        end
        self:ResetToDefault()
		self.order = "selectable"
    end
	
	RegisterChatFunc(function(player, msg)
		if sharedWith[player] then
			sharedWith[player].mouse:UpdateCursor(msg.b)
		end
	    LOG(msg)
	end, 'a')	
    
    local lastMouse = {0,0,0}
	local lastOrder = 'selectable'
    
    local function isMouseEqual(mouse)
        return mouse[1] == lastMouse[1] and
               mouse[2] == lastMouse[2] and
               mouse[3] == lastMouse[3]
    end
    
	if me ~= -1 then
		ForkThread(function()
			local fps = 1/30
			local data = {}
			local function newFormat(value)
				return tonumber(string.format("%.1f", value))
			end
			while true do
				local mouse = GetMouseWorldPos()
				if not isMouseEqual(mouse) or lastOrder ~= cursor.order then
					lastMouse = mouse
					lastOrder = cursor.order
								
					data[1] = newFormat(mouse[1])
					data[2] = newFormat(mouse[2])
					data[3] = newFormat(mouse[3])
					data[4] = OrdersToNum[cursor.order]

					SessionSendChatMessage(clients, {a = true, b = data})
				end
				WaitSeconds(fps)
			end
		end)
	end
end

-----------------------------------------------------------------------
-- DEADLOCK CONTROL LOOP
-----------------------------------------------------------------------

function DeadlockControlLoop()
    local cam = GetCamera("WorldCamera")
    local UIUtil = import('/lua/ui/uiutil.lua')
    
    -- Reset Camera Accel for instant response
    cam:SetAccMode("None")
    
    -- Control Settings
    local yaw = 0
    local pitch = 0.5
    local distance = 18 -- Distance behind commander
    local sensitivity = 0.003
    local moveStep = 50 -- Distance to project move order
    
    -- Key Codes (Standard US Layout)
    local KEY_W = 87
    local KEY_A = 65
    local KEY_S = 83
    local KEY_D = 68
    local KEY_F1 = 112 -- Toggle Key
    local KEY_LCLICK = 1
    
    -- Screen Center
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    -- State
    local acu = nil
    
    while true do
        
        -- 1. TOGGLE LOGIC
        if IsKeyDown(KEY_F1) then
            DeadlockMode = not DeadlockMode
            -- Simple debounce
            WaitSeconds(0.25)
        end
        
        -- 2. ACU FINDING LOGIC
        if not acu or acu:IsDead() then
            local selection = GetSelectedUnits()
            if selection then
                for _, u in selection do
                    if u:GetBlueprint().CategoriesHash.COMMAND then
                        acu = u
                        break
                    end
                end
            end
            
            -- Fallback: If not selected, try to find in focus army (requires iterating UI units, which is hard, relying on selection for now)
            -- Or just check selection again next frame
        end
        
        if DeadlockMode and acu and not acu:IsDead() then
            
            -- 3. MOUSE AIM (YAW/PITCH)
            local mousePos = GetMousePosition()
            local dx = mousePos[1] - centerX
            local dy = mousePos[2] - centerY
            
            if dx ~= 0 or dy ~= 0 then
                yaw = yaw + dx * sensitivity
                pitch = pitch + dy * sensitivity
                
                -- Clamp pitch to avoid flipping over
                if pitch < 0.2 then pitch = 0.2 end
                if pitch > 1.3 then pitch = 1.3 end
                
                -- Lock mouse to center
                WarpMouse(centerX, centerY)
            end
            
            -- 4. CAMERA UPDATE
            local pos = acu:GetPosition()
            
            -- Calculate Camera Offset based on Yaw/Pitch
            -- SupCom World: Y is Up.
            local sinYaw = math.sin(yaw)
            local cosYaw = math.cos(yaw)
            local sinPitch = math.sin(pitch)
            local cosPitch = math.cos(pitch)
            
            -- Camera position: Behind unit based on yaw
            local camX = pos[1] + (sinYaw * distance * cosPitch)
            local camZ = pos[3] + (cosYaw * distance * cosPitch)
            local camY = pos[2] + (distance * sinPitch) + 2 -- Lift camera slightly
            
            -- Look Target: Slightly above unit's head
            local targetX = pos[1]
            local targetY = pos[2] + 2
            local targetZ = pos[3]
            
            -- Apply Camera
            cam:SnapTo({targetX, targetY, targetZ}, {camX, camY, camZ}, 0)
            
            -- 5. MOVEMENT (WASD)
            local moveX = 0
            local moveZ = 0
            
            if IsKeyDown(KEY_W) then moveZ = -1 end
            if IsKeyDown(KEY_S) then moveZ = 1 end
            if IsKeyDown(KEY_A) then moveX = -1 end
            if IsKeyDown(KEY_D) then moveX = 1 end
            
            if moveX ~= 0 or moveZ ~= 0 then
                -- Translate WASD to World Space based on Camera Yaw
                -- Forward Vector (Flattened) is opposite to Camera Offset Vector
                local fwdX = -sinYaw
                local fwdZ = -cosYaw
                
                -- Right Vector is perpendicular to Forward
                local rightX = -fwdZ
                local rightZ = fwdX
                
                -- Combine
                local worldX = (fwdX * -moveZ) + (rightX * moveX)
                local worldZ = (fwdZ * -moveZ) + (rightZ * moveX)
                
                -- Project Destination
                local dest = {
                    pos[1] + worldX * moveStep,
                    pos[2],
                    pos[3] + worldZ * moveStep
                }
                
                -- Issue Move Command
                -- Clear previous commands to ensure instant response
                IssueClearCommands({acu})
                IssueMove({acu}, dest)
                
            else
                -- Stop if no keys pressed
                -- Only clear if we were moving previously? 
                -- For smoothness, clearing continuously ensures we don't drift.
                -- However, clearing stops shooting.
                -- We only clear if we are NOT shooting.
                if not IsKeyDown(KEY_LCLICK) then
                   -- IssueClearCommands({acu}) -- Optional: Stops unit instantly, but looks jerky
                end
            end
            
            -- 6. SHOOTING
            if IsKeyDown(KEY_LCLICK) then
                -- Get Aim Point (World Pos at Screen Center)
                local aimPos = GetMouseWorldPos()
                
                -- Issue Attack
                -- In SupCom, IssueAttack stops movement. 
                -- To strafe (Move + Shoot), we rely on Move command + Auto-fire, 
                -- OR we prioritize Attack.
                -- Deadlock style: Attack takes priority for aiming.
                
                IssueAttack({acu}, aimPos)
            end
        end
        
        -- High refresh rate for smooth camera
        WaitSeconds(0.01)
    end
end