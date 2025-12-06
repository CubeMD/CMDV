--~ text = "10:01"
--~ fields = {}
--~ sep = ":"

--~ text:gsub("([^"..sep.."]*)"..sep, function(c) table.insert(fields, c) end)
--~ print(fields[1])
--~ print(fields[2])
text = 'prefs/spliff/spliff.SCFAVirtualSave'
for x in string.gfind(text,'f%.([^.]-)$') do
	print(x)
end

-----------------------------------------------------------------------------------------------
-- string.findall(str,pattern) Return table with all non-overlapping matches of pattern in string
-----------------------------------------------------------------------------------------------
function string.findall(str,pattern)
	local t = {}
	for match in string.gfind(str,pattern) do
		table.insert(t,match)
	end
	return t
end

-----------------------------------------------------------------------------------------------
-- string.findone(str,pattern) Return first match of pattern in string
-----------------------------------------------------------------------------------------------
function string.findone(str,pattern)
	local s = ''
	for match in string.gfind(str,pattern) do
		return match
	end
	return s
end

-----------------------------------------------------------------------------------------------
-- string.findlast(str,pattern) Return last match of pattern in string
-----------------------------------------------------------------------------------------------
function string.findlast(str,pattern)
	local s = ''
	for match in string.gfind(str,pattern) do
		s = match
	end
	return s
end

print(string.findlast('ab.cd.ef.gh.ij.kl','%.([^.]-)%.'))