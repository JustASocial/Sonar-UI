local Variables = require(script.Parent.Variables)

local Ticker = {}

local subscribers = {}
local connection = nil
local count = 0

local function pump(delta)
	local dead = nil
	for handle, callback in pairs(subscribers) do
		local ok = pcall(callback, delta)
		if not ok then
			if dead == nil then
				dead = {}
			end
			table.insert(dead, handle)
		end
	end
	if dead then
		for _, handle in ipairs(dead) do
			subscribers[handle] = nil
			count = count - 1
		end
	end
	if count <= 0 then
		connection:Disconnect()
		connection = nil
	end
end

function Ticker.subscribe(callback)
	count = count + 1
	local handle = {}
	subscribers[handle] = callback
	if not connection then
		connection = Variables.services.RunService.RenderStepped:Connect(pump)
	end
	return handle
end

function Ticker.unsubscribe(handle)
	if handle == nil or subscribers[handle] == nil then
		return
	end
	subscribers[handle] = nil
	count = count - 1
	if count <= 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

function Ticker.active()
	return count
end

return Ticker
