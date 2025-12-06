-- list of possible states a unit can be in
states = msimport('code/sim/UnitStates.lua').all
-- list of layers a unit can be on
layers = {'Land','Air','Water','Seabed','Sub','Orbit'}

-- Get the number of a state name from the states array. It's more compact than storing the name string
function GetStateId(name)
	return table.find(states,name)
end

-- Get the name of a state from the states array.
function GetStateName(id)
	return states[id]
end

-- Get the number of a layer name from the layers array. It's more compact than storing the name string
function GetLayerId(name)
	return table.find(layers,name)
end

-- Get the name of a layer from the layers array.
function GetLayerName(id)
	return layers[id]
end

-- Returns the name of the map with special characters removed
function GetMapName(name)
	return string.lower(string.gsub(ScenarioInfo.name, '%W',''))
end

function DumpUnit(u)
	if u.GetEntityId then
		return 'unit: '..u:GetEntityId()
	elseif type(u) == 'table' then
		return 'table: '..table.getn(u)..' items'
	else
		return type(u)
	end
end


function ReportSystemTimeToUI()
    local now = GetSystemTimeSecondsOnlyForProfileUse()
    SimCallback({
        Func = 'OnReportSystemTime',
        Time = now,
    })
end
