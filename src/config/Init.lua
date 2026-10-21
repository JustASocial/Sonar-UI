local Variables = require(script.Parent.Parent.core.Variables)

local Config = {}

local SERIALIZERS = {
	Toggle = function(element)
		return element.value
	end,
	Checkbox = function(element)
		return element.value
	end,
	Radio = function(element)
		return element.value
	end,
	Slider = function(element)
		return element.value
	end,
	Input = function(element)
		return element.value
	end,
	TextArea = function(element)
		return element.value
	end,
	Dropdown = function(element)
		return element.value
	end,
	Keybind = function(element)
		local value = element.value
		if value == nil then
			return "None"
		end
		if type(value) == "string" then
			return value
		end
		return tostring(value.Name)
	end,
	ColorPicker = function(element)
		return { color = element.value and element.value:ToHex() or "#FFFFFF", alpha = element.alpha or 0 }
	end,
	Chip = function(element)
		return element.value
	end,
	Rating = function(element)
		return element.value
	end,
	ImageUploader = function(element)
		return element.value
	end,
}

local DESERIALIZERS = {
	Toggle = function(element, data)
		element:Set(data, true)
	end,
	Checkbox = function(element, data)
		element:Set(data, true)
	end,
	Radio = function(element, data)
		element:Set(data, true)
	end,
	Slider = function(element, data)
		element:Set(tonumber(data) or 0, true)
	end,
	Input = function(element, data)
		element:Set(tostring(data), true)
	end,
	TextArea = function(element, data)
		element:Set(tostring(data), true)
	end,
	Dropdown = function(element, data)
		element:Set(data, true)
	end,
	Keybind = function(element, data)
		element:Set(data, true)
	end,
	ColorPicker = function(element, data)
		if type(data) == "table" then
			local color = Color3.fromHex(data.color or "#FFFFFF")
			element:Set(color, data.alpha or 0, true)
		end
	end,
	Chip = function(element, data)
		element:Set(data, true)
	end,
	Rating = function(element, data)
		element:Set(tonumber(data) or 0, true)
	end,
	ImageUploader = function(element, data)
		element:Set(data, true)
	end,
}

local ConfigModule = {}
ConfigModule.__index = ConfigModule

function ConfigModule:register(flag, element)
	self.elements[flag] = element
end

function ConfigModule:set(key, value)
	self.custom[key] = value
end

function ConfigModule:get(key)
	return self.custom[key]
end

function ConfigModule:serialize()
	local payload = {}
	for flag, element in pairs(self.elements) do
		local serializer = SERIALIZERS[element.__type]
		if serializer then
			local ok, value = pcall(serializer, element)
			if ok then
				payload[flag] = { __type = element.__type, value = value }
			end
		end
	end
	return {
		__version = 1,
		__elements = payload,
		__custom = self.custom,
	}
end

function ConfigModule:write(payload)
	local ok, json = pcall(function()
		return Variables.services.HttpService:JSONEncode(payload)
	end)
	if not ok or type(json) ~= "string" then
		return false
	end
	if Variables.hasWrite() then
		if Variables.hasMakeDir() then
			pcall(makedir, self.manager.path)
		end
		local written = pcall(writefile, self.path, json)
		if not written then
			local fallback = self.name .. ".json"
			written = pcall(writefile, fallback, json)
			if written then
				self.path = fallback
			end
		end
		if not written then
			self.memory = json
			return false
		end
		return true
	end
	self.memory = json
	return true
end

function ConfigModule:read()
	if Variables.hasRead() and Variables.hasIsFile() and isfile(self.path) then
		local ok, content = pcall(readfile, self.path)
		if ok then
			return content
		end
	end
	return self.memory
end

function ConfigModule:save()
	local payload = self:serialize()
	return self:write(payload)
end

function ConfigModule:load()
	local content = self:read()
	if not content then
		return false
	end
	local ok, payload = pcall(function()
		return Variables.services.HttpService:JSONDecode(content)
	end)
	if not ok or type(payload) ~= "table" then
		return false
	end

	local elements = payload.__elements or {}
	for flag, data in pairs(elements) do
		local element = self.elements[flag]
		if element and type(data) == "table" then
			local deserializer = DESERIALIZERS[data.__type]
			if deserializer then
				pcall(deserializer, element, data.value)
			end
		end
	end

	local custom = payload.__custom or {}
	for key, value in pairs(custom) do
		self.custom[key] = value
	end

	return true
end

function ConfigModule:delete()
	if Variables.hasWrite() and Variables.hasIsFile() and isfile(self.path) then
		pcall(delfile, self.path)
	end
	self.memory = nil
	self.elements = {}
	self.custom = {}
end

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(window)
	local self = setmetatable({}, ConfigManager)
	self.window = window
	self.configs = {}
	self.path = "sonar"
	return self
end

function ConfigManager:create(name, autosave)
	local module = setmetatable({}, ConfigModule)
	module.name = name
	module.path = self.path .. "/" .. name .. ".json"
	module.elements = {}
	module.custom = {}
	module.autosave = autosave
	module.manager = self
	self.configs[name] = module
	return module
end

function ConfigManager:get(name)
	return self.configs[name]
end

function ConfigManager:list()
	local names = {}
	for key in pairs(self.configs) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

function ConfigManager:delete(name)
	local module = self.configs[name]
	if module then
		module:delete()
		self.configs[name] = nil
	end
end

return {
	Manager = ConfigManager,
	Module = ConfigModule,
	Serializers = SERIALIZERS,
	Deserializers = DESERIALIZERS,
}
