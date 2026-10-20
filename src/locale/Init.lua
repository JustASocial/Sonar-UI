local Locale = {}
Locale.__index = Locale

function Locale.new(config)
	config = config or {}
	local self = setmetatable({}, Locale)
	self.default = config.default or "en"
	self.languages = config.languages or {}
	self.prefix = config.prefix or "loc:"
	self.current = config.current or self.default
	self.bindings = {}
	self.listeners = {}
	return self
end

function Locale:resolve(key)
	if type(key) ~= "string" then
		return tostring(key)
	end
	local table_ = self.languages[self.current]
	if table_ and table_[key] ~= nil then
		return table_[key]
	end
	local fallback = self.languages[self.default]
	if fallback and fallback[key] ~= nil then
		return fallback[key]
	end
	return key
end

function Locale:bind(instance, property, key)
	table.insert(self.bindings, { instance = instance, property = property, key = key })
	instance[property] = self:resolve(key)
end

function Locale:register(language, table_)
	if type(language) ~= "string" or type(table_) ~= "table" then
		return
	end
	local target = self.languages[language]
	if not target then
		target = {}
		self.languages[language] = target
	end
	for key, value in pairs(table_) do
		target[key] = value
	end
end

function Locale:setLanguage(language)
	if type(language) ~= "string" then
		return
	end
	self.current = language
	local kept = {}
	for _, binding in ipairs(self.bindings) do
		if binding.instance.Parent ~= nil then
			binding.instance[binding.property] = self:resolve(binding.key)
			table.insert(kept, binding)
		end
	end
	self.bindings = kept
	for _, listener in ipairs(self.listeners) do
		pcall(listener, language)
	end
end

function Locale:onChange(listener)
	table.insert(self.listeners, listener)
	return listener
end

function Locale:available()
	local names = {}
	for key in pairs(self.languages) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

return Locale
