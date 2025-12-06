-- BLUEPRINT UTILITIES
-- Functions to make manipulating blueprints easier

-- CATEGORY HELPER FUNCTIONS: Useful because EntityContainsCategory and friends are not normally defined yet.

-- Helper function to see wether a unit contains a category
function HasCategory( bp, cat )
	for i, bpCat in bp.Categories do
		if cat == bpCat then 
			do return true end
		end
	end
end

-- Helper function to see wether a unit contains all categories in list
function HasAllCategories( bp, catList )
	local matched = 0 
	for i, bpCat in bp.Categories do
		for ii, listCat in catList do
			if listCat == bpCat then 
				matched = matched + 1
			end
		end
	end
	if matched == table.getn(catList) then
		do return true end
	else
		do return false end
	end
end

-- Helper function to see wether a unit contains any of the categories in list
function HasAnyCategories( bp, catList )
	for i, bpCat in bp.Categories do
		for ii, listCat in catList do
			if listCat == bpCat then 
				do return true end
			end
		end
	end
	return false
end

-- Helper function to see wether a unit contains any of the BlueprindIds in list
function IdIn( id, idList )
	for i, listId in idList do
		if listId == id then 
			do return true end
		end
	end
	return false
end

-- Helper function to remove all of value from a table/list (compares on values, not keys)
function RemoveValue( tbl, val )
	for i, tblVal in tbl do
		if tblVal == val then 
			tbl[i] = nil
		end
	end
end

-- Helper function to add a value to a table/list if it doesn't already exist
function AddOrReplaceValue( tbl, val )
	local found = false
	for i, tblVal in tbl do
		if tblVal == val then 
			found = true
		end
	end
	if not found then
		table.insert(tbl,val)
	end
end

-- Helper function to replace a value in a table/list (compares on values, not keys)
function ReplaceValue( tbl, val, newVal )
	for i, tblVal in tbl do
		if tblVal == val then 
			tbl[i] = newVal
		end
	end
end


-- Helper function to uniformly scale a units engieering rate (building, reclaiming, etc..)
function ScaleEngineering( bp, factor )
	if bp.Economy.MaxEnergyUse then
		bp.Economy.MaxEnergyUse = bp.Economy.MaxEnergyUse * factor
	end
	if bp.Economy.MaxMassUse then
		bp.Economy.MaxMassUse = bp.Economy.MaxMassUse * factor
	end
end
