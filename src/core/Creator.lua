local Variables = require(script.Parent.Variables)

local Creator = {}

Creator.instances = {}
Creator.themeBindings = {}
Creator.localeBindings = {}
Creator.connections = {}

local function resolveLookup(theme, key)
	local colors = theme.colors
	if colors[key] ~= nil then
		return colors[key]
	end
	local shape = theme.shape
	if shape[key] ~= nil then
		return shape[key]
	end
	local elevation = theme.elevation
	if elevation[key] ~= nil then
		return elevation[key].color
	end
	local fonts = theme.fonts
	if fonts[key] ~= nil then
		return fonts[key]
	end
	local scale = theme.type
	if scale[key] ~= nil then
		return scale[key]
	end
	return theme[key]
end

function Creator.resolveThemeValue(spec, theme)
	if type(spec) == "string" then
		return resolveLookup(theme, spec)
	end
	if type(spec) == "function" then
		return spec(theme)
	end
	if type(spec) == "table" then
		local base
		local key = spec[1]
		if type(key) == "function" then
			base = key(theme)
		elseif type(key) == "string" then
			base = resolveLookup(theme, key)
		else
			base = key
		end
		local transform = spec[2]
		if transform then
			return transform(base, theme)
		end
		return base
	end
	return spec
end

function Creator.new(className, properties, themeProperties)
	local instance = Instance.new(className)

	if themeProperties then
		local window = Creator.window
		if window then
			for property, spec in pairs(themeProperties) do
				instance[property] = Creator.resolveThemeValue(spec, window.theme)
			end
			Creator.themeBindings[instance] = themeProperties
		end
	end

	if properties then
		for property, value in pairs(properties) do
			if property == "Text" and type(value) == "string" and value:sub(1, 4) == "loc:" then
				local window = Creator.window
				if window and window.locale then
					window.locale:bind(instance, property, value:sub(5))
					instance[property] = window.locale:resolve(value:sub(5))
				else
					instance[property] = value:sub(5)
				end
			else
				instance[property] = value
			end
		end
	end

	table.insert(Creator.instances, instance)
	return instance
end

function Creator.bindTheme(instance, themeProperties)
	Creator.themeBindings[instance] = themeProperties
	return instance
end

function Creator.applyTheme(theme, animate)
	local tweenService = Variables.services.TweenService
	for instance, bindings in pairs(Creator.themeBindings) do
		if instance.Parent == nil then
			Creator.themeBindings[instance] = nil
			continue
		end
		for property, spec in pairs(bindings) do
			local target = Creator.resolveThemeValue(spec, theme)
			if target == nil then
				continue
			end
			local current = instance[property]
			if animate and (typeof(target) == "Color3" or typeof(target) == "number") then
				if typeof(current) == typeof(target) and current ~= target then
					tweenService:Create(
						instance,
						TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ [property] = target }
					):Play()
				else
					instance[property] = target
				end
			else
				instance[property] = target
			end
		end
	end
end

function Creator.connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Creator.connections, connection)
	return connection
end

function Creator.disconnect(connection)
	if not connection then
		return
	end
	connection:Disconnect()
	for index, entry in ipairs(Creator.connections) do
		if entry == connection then
			table.remove(Creator.connections, index)
			break
		end
	end
end

function Creator.disconnectMany(list)
	if not list or #list == 0 then
		return
	end
	local dropping = {}
	for _, connection in ipairs(list) do
		dropping[connection] = true
		connection:Disconnect()
	end
	local function filter(target)
		if not target then
			return
		end
		local kept = 0
		for index = 1, #target do
			local entry = target[index]
			if not dropping[entry] then
				kept = kept + 1
				target[kept] = entry
			end
		end
		for index = #target, kept + 1, -1 do
			target[index] = nil
		end
	end
	filter(Creator.connections)
end

function Creator.prune(roots)
	if not roots or #roots == 0 then
		return
	end
	local doomed = {}
	for _, root in ipairs(roots) do
		doomed[root] = true
	end
	local kept = 0
	for index = 1, #Creator.instances do
		local instance = Creator.instances[index]
		if not doomed[instance] then
			kept = kept + 1
			Creator.instances[kept] = instance
		else
			Creator.themeBindings[instance] = nil
		end
	end
	for index = #Creator.instances, kept + 1, -1 do
		Creator.instances[index] = nil
	end
end

function Creator.destroyAll()
	for _, connection in ipairs(Creator.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	Creator.connections = {}
	for _, instance in ipairs(Creator.instances) do
		pcall(function()
			instance:Destroy()
		end)
	end
	Creator.instances = {}
	Creator.themeBindings = {}
	Creator.localeBindings = {}
end

return Creator
