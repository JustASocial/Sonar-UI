local Variables = require(script.Parent.Variables)

local TextMetrics = {}

local cache = {}
local pending = {}
local count = 0
local cap = 2048

local function key(font, size, text)
	local family = typeof(font) == "table" and font.Family or tostring(font)
	local weight = typeof(font) == "table" and tostring(font.Weight) or "regular"
	return tostring(family) .. "|" .. tostring(weight) .. "|" .. tostring(size) .. "|" .. tostring(text)
end

local function measure(font, size, text)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = tostring(text)
	params.Font = font
	params.Size = size
	params.Width = math.huge
	local ok, bounds = pcall(function()
		return Variables.services.TextService:GetTextBoundsAsync(params)
	end)
	if not ok or not bounds then
		return nil
	end
	return bounds
end

function TextMetrics.width(font, size, text)
	text = tostring(text)
	local cacheKey = key(font, size, text)
	local cached = cache[cacheKey]
	if cached ~= nil then
		return cached
	end

	if pending[cacheKey] == nil then
		pending[cacheKey] = true
		task.spawn(function()
			local bounds = measure(font, size, text)
			pending[cacheKey] = nil
			if bounds == nil then
				return
			end
			local width = math.ceil(bounds.X)
			if count >= cap then
				cache = {}
				count = 0
			end
			cache[cacheKey] = width
			count = count + 1
		end)
	end

	return nil
end

function TextMetrics.widthSync(font, size, text)
	local cacheKey = key(font, size, text)
	local cached = cache[cacheKey]
	if cached ~= nil then
		return cached
	end
	local bounds = measure(font, size, text)
	if bounds == nil then
		local length = utf8.len(tostring(text)) or #tostring(text)
		return math.ceil(size * 0.55 * length)
	end
	local width = math.ceil(bounds.X)
	cache[cacheKey] = width
	count = count + 1
	return width
end

function TextMetrics.clear()
	cache = {}
	count = 0
end

return TextMetrics
