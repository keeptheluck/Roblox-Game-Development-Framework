local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

local suffixes = {"K", "M", "B", "T", "qd", "Qn", "sx", "Sp", "O", "N", "de", "Ud", "DD", "tdD",
"qdD", "QnD", "sxD", "SpD", "OcD", "NvD", "Vgn", "UVg", "DVg", "TVg", "qtV",
"QnV", "SeV", "SPG", "OVG", "NVG", "TGN", "UTG", "DTG", "tsTG", "qtTG", "QnTG",
"ssTG", "SpTG", "OcTG", "NoTG", "QdDR", "uQDR", "dQDR", "tQDR", "qdQDR", "QnQDR",
"sxQDR", "SpQDR", "OQDDr", "NQDDr", "qQGNT", "uQGNT", "dQGNT", "tQGNT", "qdQGNT",
"QnQGNT", "sxQGNT", "SpQGNT", "OQQGNT", "NQQGNT", "SXGNTL", "USXGNTL", "DSXGNTL",
"TSXGNTL", "QTSXGNTL", "QNSXGNTL", "SXSXGNTL", "SPSXGNTL", "OSXGNTL", "NVSXGNTL",
"SPTGNTL", "USPTGNTL", "DSPTGNTL", "TSPTGNTL", "QTSPTGNTL", "QNSPTGNTL", "SXSPTGNTL",
"SPSPTGNTL", "OSPTGNTL", "NVSPTGNTL", "OTGNTL", "UOTGNTL", "DOTGNTL", "TOTGNTL", "QTOTGNTL",
"QNOTGNTL", "SXOTGNTL", "SPOTGNTL", "OTOTGNTL", "NVOTGNTL", "NONGNTL", "UNONGNTL", "DNONGNTL",
"TNONGNTL", "QTNONGNTL", "QNNONGNTL", "SXNONGNTL", "SPNONGNTL", "OTNONGNTL", "NONONGNTL", "CENT", "UNCENT"}

local bigNum = require(ReplicatedStorage.SharedModules:WaitForChild("BigNum"))

function addCommas(str)
	return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

local function ToSuffixString(n)
	if tonumber(n)>9999 then
		for i = #suffixes, 1, -1 do
			local v = math.pow(10, i * 3)
			if tonumber(n) >= v then
				return ("%.1f"):format(n / v) .. suffixes[i]
			end
		end
		return tostring(n)
	else
		return addCommas(tostring(n))
	end
end

local function ToSuffixStringBigNum(numString: string)
    local currentBigNum = bigNum.new(numString)
    if bigNum.lt(bigNum.new(9999), currentBigNum) then
        for i = #suffixes, 1, -1 do
			local v = bigNum.new(math.pow(10, i * 3))
            if bigNum.le(currentBigNum, v) == false then
                return ("%.1f"):format(tostring(currentBigNum / v)) .. suffixes[i]
            end
		end
		return tostring(numString)
    else
        return addCommas(numString)
    end
end

function module:toSuffixString(args)
	return ToSuffixString(args)
end

function module:toSuffixStringBigNum(numString: string)
    return ToSuffixStringBigNum(numString)
end

function module:AddCommas(str)
	return addCommas(tostring(str))
end

return module
--[[

For ordered datastores, you'd have to use this math to get around the ordered value limitations:
local value = 9.99e50
local storedValue = value ~= 0 and math.floor(math.log(value) / math.log(1.0000001)) or 0

print(storedValue) -> -- 1174308450
local value = ...



local value = ...
local retrievedValue = value ~= 0 and (1.0000001^value) or 0

print(retrievedValue) -- 9.9899995470475e+50
]]