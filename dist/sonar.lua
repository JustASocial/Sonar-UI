-- Sonar UI - Material Design 3 GUI library for Roblox
-- Single file build. Load it with:
--   local Sonar = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustASocial/Sonar-UI/main/dist/sonar.lua"))()
-- Source: https://github.com/JustASocial/Sonar-UI

local __mods = {}
local __cache = {}


local function __require(key)
	if __cache[key] ~= nil then
		return __cache[key]
	end
	local loader = __mods[key]
	if not loader then
		error("[Sonar] module not found: " .. tostring(key))
	end
	local result = loader()
	__cache[key] = result
	return result
end

__mods["config.Init"] = function()
	local Variables = __require("core.Variables")

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
		Stepper = function(element)
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
		Stepper = function(element, data)
			element:Set(tonumber(data) or 1, true)
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

end

__mods["core.Container"] = function()
	local Creator = __require("core.Creator")

	local Container = {}
	Container.__index = Container

	function Container.init(self)
		self.children = {}
		self.built = false
		self.order = 0
	end

	function Container.addChild(self, handle)
		self.order = self.order + 1
		handle._order = self.order
		table.insert(self.children, handle)
		if handle.flag and self.window and self.window.config then
			self.window.config:register(handle.flag, handle)
			self.window.flags[handle.flag] = handle
		end
		if self.built then
			self:buildChild(handle)
			local Element = __require("core.Element")
			Element.reveal(handle, 0)
		end
	end

	function Container.buildChild(self, handle)
		if handle.__built then
			return
		end
		handle.__built = true
		Creator.window = self.window
		local ok, err = pcall(function()
			handle:_build(self.contentFrame, handle._order)
		end)
		if not ok then
			self:createError((handle.__type or "Element") .. ": " .. tostring(err))
		end
	end

	function Container.createError(self, message)
		if not self.contentFrame then
			return
		end
		local theme = self.window.theme
		local frame = Creator.new("Frame", {
			Name = "Error",
			LayoutOrder = 99999,
			Size = UDim2.new(1, 0, 0, 64),
			BackgroundColor3 = theme.colors.errorContainer,
			BorderSizePixel = 0,
			Parent = self.contentFrame,
		}, { BackgroundColor3 = "errorContainer" })

		Creator.new("UICorner", {
			CornerRadius = theme.shape.element,
			Parent = frame,
		})

		Creator.new("TextLabel", {
			Position = UDim2.new(0, 12, 0, 8),
			Size = UDim2.new(1, -24, 1, -16),
			BackgroundTransparency = 1,
			Font = theme.fonts.mono,
			Text = tostring(message),
			TextColor3 = theme.colors.onErrorContainer,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = frame,
		}, { TextColor3 = "onErrorContainer" })
	end

	function Container.flush(self)
		if self.built then
			return
		end
		self.built = true
		local children = self.children
		local index = 0

		local function step()
			local budget = 6
			local batch = {}
			for _ = 1, budget do
				if index >= #children then
					break
				end
				index = index + 1
				self:buildChild(children[index])
				table.insert(batch, children[index])
			end
			self:_reveal(batch)
			if index < #children then
				task.defer(step)
			end
		end

		step()
	end

	function Container:_reveal(children)
		local Element = __require("core.Element")
		local index = 0
		for _, handle in ipairs(children) do
			index = index + 1
			if handle.main then
				Element.reveal(handle, (index - 1) * 0.035)
			end
		end
	end

	function Container.createElement(self, typeName, props)
		local Elements = __require("elements.Init")
		local module = Elements.get(typeName)
		if not module then
			self:createError("unknown element type: " .. tostring(typeName))
			return nil
		end
		local ok, handle = pcall(function()
			return module.new({
				window = self.window,
				container = self,
				props = props or {},
			})
		end)
		if not ok then
			self:createError(typeName .. ": " .. tostring(handle))
			return nil
		end
		self:addChild(handle)
		return handle
	end

	function Container.createSection(self, props)
		local Section = __require("core.Section")
		local ok, section = pcall(function()
			return Section.new({
				window = self.window,
				container = self,
				props = props or {},
			})
		end)
		if not ok then
			self:createError("Section: " .. tostring(section))
			return nil
		end
		self:addChild(section)
		return section
	end

	function Container.createGroup(self, props)
		local Group = __require("core.Group")
		local ok, group = pcall(function()
			return Group.new({
				window = self.window,
				container = self,
				props = props or {},
			})
		end)
		if not ok then
			self:createError("Group: " .. tostring(group))
			return nil
		end
		self:addChild(group)
		return group
	end

	function Container.moveChild(self, handle, index)
		local position = nil
		for offset, entry in ipairs(self.children) do
			if entry == handle then
				position = offset
				break
			end
		end
		if position == nil then
			return
		end
		table.remove(self.children, position)
		table.insert(self.children, index, handle)
		local order = 0
		for _, entry in ipairs(self.children) do
			order = order + 1
			entry._order = order
			if entry.main then
				entry.main.LayoutOrder = order
			end
		end
	end

	function Container.removeChild(self, handle)
		for offset, entry in ipairs(self.children) do
			if entry == handle then
				table.remove(self.children, offset)
				break
			end
		end
		if handle.main then
			handle.main:Destroy()
		end
	end

	function Container.reset(self)
		self.built = false
		for _, handle in ipairs(self.children) do
			handle.__built = false
			if handle.reset then
				handle:reset()
			end
		end
	end

	function Container.destroy(self)
		for _, handle in ipairs(self.children) do
			if handle._destroy then
				handle:_destroy()
			elseif handle.main then
				handle.main:Destroy()
			end
		end
		self.children = {}
		self.built = false
	end

	setmetatable(Container, {
		__index = function(_, key)
			local Elements = __require("elements.Init")
			local name = key:match("^[Cc]reate(.+)$")
			if name then
				if Elements.get(name) then
					return function(self, props)
						return Container.createElement(self, name, props)
					end
				end
				if name == "Section" then
					return function(self, props)
						return Container.createSection(self, props)
					end
				end
				if name == "Group" then
					return function(self, props)
						return Container.createGroup(self, props)
					end
				end
				return nil
			end
			if key == "Section" then
				return function(self, props)
					return Container.createSection(self, props)
				end
			end
			if key == "Group" then
				return function(self, props)
					return Container.createGroup(self, props)
				end
			end
			if Elements.get(key) then
				return function(self, props)
					return Container.createElement(self, key, props)
				end
			end
			return nil
		end,
	})

	return Container

end

__mods["core.Creator"] = function()
	local Variables = __require("core.Variables")

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

end

__mods["core.Element"] = function()
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Element = {}
	Element.__index = Element

	Element.Metrics = {
		padLeft = 16,
		padRight = 16,
		iconSize = 22,
		iconGap = 14,
		titleGap = 12,
		rowHeight = 52,
		rowHeightTall = 68,
		titleSize = 15,
		descSize = 12,
	}

	function Element.new(ctx)
		local props = ctx.props or {}
		Creator.window = ctx.window
		local handle = setmetatable({
			__type = ctx.typeName,
			__built = false,
			window = ctx.window,
			container = ctx.container,
			props = props,
			connections = {},
			instances = {},
			locked = false,
			flag = props.Flag,
		}, Element)
		return handle
	end

	function Element.track(handle, instance)
		table.insert(handle.instances, instance)
		return instance
	end

	function Element.connect(handle, signal, callback)
		local connection = signal:Connect(callback)
		table.insert(handle.connections, connection)
		return connection
	end

	function Element.themeColor(handle, key)
		return handle.window.theme.colors[key]
	end

	function Element.themeShape(handle, key)
		return handle.window.theme.shape[key]
	end

	function Element.typeOf(handle, name)
		return handle.window.theme.type[name]
	end

	function Element.fontFor(handle, weight)
		local fonts = handle.window.theme.fonts
		return fonts[weight] or fonts.regular
	end

	function Element.setLocked(handle, locked, reason)
		handle.locked = locked
		if not handle.main then
			return
		end
		if locked then
			if not handle.lockFrame then
				local overlay = Creator.new("Frame", {
					Name = "Lock",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = handle.window.theme.colors.surfaceContainerHighest,
					BackgroundTransparency = 0.35,
					BorderSizePixel = 0,
					ZIndex = 50,
					Parent = handle.main,
				}, { BackgroundColor3 = "surfaceContainerHighest" })
				Creator.new("UICorner", { CornerRadius = handle.window.theme.shape.element, Parent = overlay })
				local icon = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(20, 20),
					BackgroundTransparency = 1,
					Image = Icons.image("lock") or "",
					ImageColor3 = handle.window.theme.colors.onSurfaceVariant,
				}, { ImageColor3 = "onSurfaceVariant" })
				icon.Parent = overlay
				handle.lockFrame = overlay
			end
			handle.lockFrame.Visible = true
			if reason then
				handle.lockFrame.Name = "Lock:" .. tostring(reason)
			end
		else
			if handle.lockFrame then
				handle.lockFrame.Visible = false
			end
		end
	end

	function Element.setHover(handle, hovered)
		if not handle.stateLayer or handle.locked then
			return
		end
		local theme = handle.window.theme
		local target = hovered and 1 - theme.state.hover or 1
		Motion.tween(handle.stateLayer, { BackgroundTransparency = target }, theme.motion.short)
	end

	function Element.setPressed(handle, pressed)
		if not handle.stateLayer or handle.locked then
			return
		end
		local theme = handle.window.theme
		local target = pressed and 1 - theme.state.pressed or 1
		Motion.tween(handle.stateLayer, { BackgroundTransparency = target }, theme.motion.short)
	end

	function Element.wireHover(handle, target)
		target = target or handle.main
		if not target then
			return
		end
		Element.connect(handle, target.MouseEnter, function()
			if handle.locked then
				return
			end
			Element.setHover(handle, true)
		end)
		Element.connect(handle, target.MouseLeave, function()
			Element.setPressed(handle, false)
			Element.setHover(handle, false)
		end)
		Element.connect(handle, target.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				Element.setPressed(handle, true)
			end
		end)
		Element.connect(handle, target.InputEnded, function()
			Element.setPressed(handle, false)
		end)
	end

	function Element.reveal(handle, delay)
		local main = handle.main
		if not main or not main.Parent then
			return
		end
		local theme = handle.window.theme
		local targets = {}
		local originals = {}

		for _, child in ipairs(main:GetChildren()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
				table.insert(targets, child)
				if child:IsA("ImageLabel") then
					originals[child] = child.ImageTransparency
				else
					originals[child] = child.TextTransparency
				end
			end
		end

		local originalTransparency = main.BackgroundTransparency
		main.BackgroundTransparency = 1
		for _, target in ipairs(targets) do
			if target:IsA("ImageLabel") then
				target.ImageTransparency = 1
			else
				target.TextTransparency = 1
			end
		end

		task.delay(delay or 0, function()
			if not main.Parent then
				return
			end
			Motion.tween(main, {
				BackgroundTransparency = originalTransparency,
			}, theme.motion.emphasizedDecelerate)
			for _, target in ipairs(targets) do
				if target:IsA("ImageLabel") then
					Motion.tween(target, { ImageTransparency = originals[target] }, theme.motion.emphasizedDecelerate)
				else
					Motion.tween(target, { TextTransparency = originals[target] }, theme.motion.emphasizedDecelerate)
				end
			end
		end)
	end

	function Element.destroy(handle)
		for _, connection in ipairs(handle.connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		handle.connections = {}
		if handle.main then
			for _, instance in ipairs(handle.instances) do
				if instance ~= handle.main and instance.Parent ~= nil then
					instance:Destroy()
				end
			end
			Creator.prune({ handle.main })
			handle.main:Destroy()
		end
	end

	function Element.refreshTheme(handle)
		if handle._refreshTheme then
			handle:_refreshTheme()
		end
	end

	return Element

end

__mods["core.Group"] = function()
	local Creator = __require("core.Creator")
	local Container = __require("core.Container")

	local Group = {}
	Group.__index = Group

	function Group.new(ctx)
		local props = ctx.props or {}
		local window = ctx.window
		Creator.window = window

		local direction = props.Direction or props.FillDirection or "row"
		if direction == "horizontal" then
			direction = "row"
		elseif direction == "vertical" then
			direction = "column"
		end

		local self = setmetatable({
			window = window,
			container = ctx.container,
			props = props,
			direction = direction,
			gap = props.Gap or 8,
			__type = "Group",
			__built = false,
			connections = {},
		}, Group)

		Container.init(self)
		return self
	end

	function Group:_build(parentFrame, order)
		local theme = self.window.theme
		local main = Creator.new("Frame", {
			Name = "Group",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = self.direction == "row" and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main
		self.contentFrame = main

		Creator.new("UIListLayout", {
			FillDirection = self.direction == "row" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, self.gap),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = main,
		})

		self:_relayout()
	end

	function Group:_relayout()
		if not self.main then
			return
		end
		local count = #self.children
		if count == 0 then
			return
		end
		local gap = self.gap
		for _, child in ipairs(self.children) do
			if child.main then
				local height = child.main.Size.Y
				if self.direction == "row" then
					local share = 1 / count
					local offset = -(gap * (count - 1) / count)
					child.main.Size = UDim2.new(share, offset, height.Scale, height.Offset)
				else
					child.main.Size = UDim2.new(1, 0, height.Scale, height.Offset)
				end
			end
		end
	end

	function Group:buildChild(handle)
		Container.buildChild(self, handle)
		self:_relayout()
	end

	function Group:reset()
		Container.reset(self)
	end

	function Group:setGap(gap)
		self.gap = gap
		if self.layout then
			self.layout.Padding = UDim.new(0, gap)
		end
		self:_relayout()
	end

	function Group:_destroy()
		if self.main then
			self.main:Destroy()
		end
	end

	setmetatable(Group, { __index = Container })

	return Group

end

__mods["core.Motion"] = function()
	local Variables = __require("core.Variables")

	local Motion = {}

	local DEFAULT_TOKEN = {
		time = 0.25,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	}

	function Motion.resolve(token)
		if token == nil then
			return DEFAULT_TOKEN
		end
		if type(token) == "number" then
			return { time = token, style = DEFAULT_TOKEN.style, direction = DEFAULT_TOKEN.direction }
		end
		if type(token) == "table" then
			return {
				time = token.time or DEFAULT_TOKEN.time,
				style = token.style or DEFAULT_TOKEN.style,
				direction = token.direction or DEFAULT_TOKEN.direction,
			}
		end
		return DEFAULT_TOKEN
	end

	local ACTIVE = setmetatable({}, { __mode = "k" })

	function Motion.tween(target, properties, token)
		local resolved = Motion.resolve(token)
		local tween = Variables.services.TweenService:Create(
			target,
			TweenInfo.new(resolved.time, resolved.style, resolved.direction),
			properties
		)
		ACTIVE[target] = tween
		tween:Play()
		return tween
	end

	function Motion.cancel(target)
		local tween = ACTIVE[target]
		if tween then
			tween:Cancel()
			ACTIVE[target] = nil
		end
	end

	function Motion.tweenColor(target, property, color, token)
		return Motion.tween(target, { [property] = color }, token)
	end

	function Motion.spring(target, properties, token)
		local resolved = Motion.resolve(token)
		return Motion.tween(
			target,
			properties,
			{ time = resolved.time, style = Enum.EasingStyle.Back, direction = Enum.EasingDirection.Out }
		)
	end

	function Motion.delay(seconds, callback)
		task.delay(seconds, callback)
	end

	return Motion

end

__mods["core.Notification"] = function()
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Notification = {}

	function Notification.create(window, props)
		props = props or {}
		local theme = window.theme
		local overlay = window.overlayGui

		local container = Creator.new("Frame", {
			Name = "Notification",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(0, 440, 0, 64),
			BackgroundTransparency = 1,
			Parent = overlay,
		})

		local surface = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.inverseSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = container,
		}, { BackgroundColor3 = "inverseSurface" })

		Creator.new("UICorner", {
			CornerRadius = theme.shape.snackbar,
			Parent = surface,
		})

		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.inverseOnSurface,
			Transparency = 0.85,
			Thickness = 1,
			Parent = surface,
		}, { Color = "inverseOnSurface" })

		local icon = nil
		local left = 16
		if props.Icon then
			icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.inverseOnSurface,
				ScaleType = Enum.ScaleType.Fit,
				Parent = surface,
			}, { ImageColor3 = "inverseOnSurface" })
			left = 16 + 20 + 12
		end

		local title = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, left, 0.5, props.Content and -10 or 0),
			Size = UDim2.new(1, -(left + 24), 0, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.inverseOnSurface,
			TextSize = theme.type.titleSmall.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = surface,
		}, { TextColor3 = "inverseOnSurface" })

		if props.Content then
			local content = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, left, 0.5, 11),
				Size = UDim2.new(1, -(left + 24), 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Content,
				TextColor3 = theme.colors.inverseOnSurface,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = surface,
			}, { TextColor3 = "inverseOnSurface" })
		end

		local action = nil
		if props.Action then
			action = Creator.new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 0, 0, 36),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = props.Action.Title or "OK",
				Font = theme.fonts.bold,
				TextColor3 = theme.colors.inversePrimary,
				TextSize = theme.type.labelLarge.size,
				Parent = surface,
			}, { TextColor3 = "inversePrimary" })

			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				Parent = action,
			})
		end

		local duration = props.Duration or 4
		local timer = nil
		if duration > 0 then
			local bar = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 3),
				BackgroundColor3 = theme.colors.inversePrimary,
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				Parent = surface,
			}, { BackgroundColor3 = "inversePrimary" })
			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = bar,
			})
			timer = Motion.tween(bar, { Size = UDim2.new(0, 0, 0, 3) }, { time = duration, style = Enum.EasingStyle.Linear, direction = Enum.EasingDirection.Out })
		end

		local closed = false
		local function dismiss()
			if closed then
				return
			end
			closed = true
			if timer then
				timer:Cancel()
			end
			Motion.tween(container, { Position = UDim2.new(0.5, 0, 1, 20) }, theme.motion.emphasizedAccelerate)
			Motion.tween(surface, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
			task.delay(theme.motion.emphasizedAccelerate.time, function()
				container:Destroy()
			end)
		end

		if action then
			action.MouseButton1Click:Connect(function()
				if props.Action.Callback then
					task.spawn(props.Action.Callback)
				end
				dismiss()
			end)
		end

		container.Position = UDim2.new(0.5, 0, 1, 24)
		Motion.tween(container, { Position = UDim2.new(0.5, 0, 1, -24) }, theme.motion.emphasizedDecelerate)
		Motion.tween(surface, { BackgroundTransparency = 0 }, theme.motion.emphasizedDecelerate)

		if duration > 0 then
			task.delay(duration, dismiss)
		end

		return {
			Dismiss = dismiss,
			Container = container,
		}
	end

	return Notification

end

__mods["core.Popup"] = function()
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Popup = {}

	local function makeButton(parent, theme, spec, order)
		local variant = spec.Variant or "text"
		local button = Creator.new("TextButton", {
			Size = UDim2.new(0, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = variant == "filled" and theme.colors.primary or theme.colors.surfaceContainerHighest,
			BackgroundTransparency = variant == "filled" and 0 or 0,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = spec.Title or "",
			Font = theme.fonts.bold,
			TextColor3 = variant == "filled" and theme.colors.onPrimary or theme.colors.onSurface,
			TextSize = theme.type.labelLarge.size,
			LayoutOrder = order,
			Parent = parent,
		}, {
			BackgroundColor3 = variant == "filled" and "primary" or "surfaceContainerHighest",
			TextColor3 = variant == "filled" and "onPrimary" or "onSurface",
		})

		Creator.new("UICorner", {
			CornerRadius = theme.shape.button,
			Parent = button,
		})

		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 22),
			PaddingRight = UDim.new(0, 22),
			Parent = button,
		})

		local hover = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = button,
		}, { BackgroundColor3 = "onSurface" })

		button.MouseEnter:Connect(function()
			Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)
		button.MouseLeave:Connect(function()
			Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short)
		end)

		return button
	end

	function Popup.create(window, props)
		props = props or {}
		local theme = window.theme
		local overlay = window.overlayGui

		local scrim = Creator.new("Frame", {
			Name = "Scrim",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.scrim,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = overlay,
		}, { BackgroundColor3 = "scrim" })

		local dialog = Creator.new("CanvasGroup", {
			Name = "Dialog",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = props.Size or UDim2.fromOffset(380, 240),
			BackgroundColor3 = theme.colors.surfaceContainerHigh,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			Parent = scrim,
		}, { BackgroundColor3 = "surfaceContainerHigh" })

		local dialogSurface = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.surfaceContainerHigh,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Parent = dialog,
		}, { BackgroundColor3 = "surfaceContainerHigh" })

		Creator.new("UICorner", {
			CornerRadius = theme.shape.dialog,
			Parent = dialogSurface,
		})

		local stack = Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 14),
			Parent = dialogSurface,
		})

		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 24),
			PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 24),
			Parent = dialogSurface,
		})

		local icon = nil
		if props.Icon then
			icon = Creator.new("ImageLabel", {
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				Parent = dialogSurface,
			}, { ImageColor3 = "onSurfaceVariant" })
		end

		local title = Creator.new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.headlineSmall.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 2,
			Parent = dialogSurface,
		}, { TextColor3 = "onSurface" })

		local content = nil
		if props.Content then
			content = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Content,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodyMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LayoutOrder = 3,
				Parent = dialogSurface,
			}, { TextColor3 = "onSurfaceVariant" })
		end

		local actions = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
			Parent = dialogSurface,
		})

		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = actions,
		})

		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			Motion.tween(scrim, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
			Motion.tween(dialog, { GroupTransparency = 1 }, theme.motion.emphasizedAccelerate)
			task.delay(theme.motion.emphasizedAccelerate.time, function()
				scrim:Destroy()
			end)
		end

		local buttonList = props.Buttons or { { Title = "OK" } }
		for index, spec in ipairs(buttonList) do
			local button = makeButton(actions, theme, spec, index)
			button.MouseButton1Click:Connect(function()
				if spec.Callback then
					task.spawn(spec.Callback)
				end
				if spec.KeepOpen ~= true then
					close()
				end
			end)
		end

		scrim.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and props.Dismissible ~= false then
				close()
			end
		end)

		Motion.tween(scrim, { BackgroundTransparency = 0.6 }, theme.motion.emphasizedDecelerate)
		Motion.tween(dialog, { GroupTransparency = 0 }, theme.motion.emphasizedDecelerate)

		return {
			Close = close,
			Dialog = dialog,
		}
	end

	return Popup

end

__mods["core.Row"] = function()
	local Creator = __require("core.Creator")
	local Icons = __require("icons.Init")

	local Row = {}

	Row.Metrics = {
		padLeft = 16,
		padRight = 16,
		iconSize = 22,
		iconGap = 14,
		gap = 14,
		height = 52,
		heightTall = 68,
		titleSize = 15,
		descSize = 12,
	}

	function Row.build(handle, options)
		local window = handle.window
		local theme = window.theme
		local metrics = Row.Metrics

		local title = options.title
		local description = options.description
		local iconName = options.icon
		local controlWidth = options.controlWidth or 0
		local height = options.height
		if not height then
			height = description and metrics.heightTall or metrics.height
		end

		local main = Creator.new("Frame", {
			Name = handle.__type,
			LayoutOrder = options.order or 0,
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			Parent = options.parent,
		})
		handle.main = main

		local stateLayer = Creator.new("Frame", {
			Name = "StateLayer",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = main,
		}, { BackgroundColor3 = "onSurface" })
		Creator.new("UICorner", {
			CornerRadius = theme.shape.element,
			Parent = stateLayer,
		})
		handle.stateLayer = stateLayer

		local left = metrics.padLeft
		local icon = nil
		if iconName then
			icon = Creator.new("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, metrics.padLeft, 0.5, 0),
				Size = UDim2.fromOffset(metrics.iconSize, metrics.iconSize),
				BackgroundTransparency = 1,
				Image = Icons.image(iconName) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = "onSurfaceVariant" })
			handle.icon = icon
			left = metrics.padLeft + metrics.iconSize + metrics.iconGap
		end

		local reserved = left + metrics.padRight + controlWidth
		if controlWidth > 0 then
			reserved = reserved + metrics.gap
		end
		local textWidth = math.max(40, reserved - left)

		local titleLabel = nil
		if title ~= nil and title ~= "" then
			titleLabel = Creator.new("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, left, 0, description and 12 or 0),
				Size = UDim2.new(0, textWidth, 0, 20),
				BackgroundTransparency = 1,
				Font = theme.fonts.medium,
				Text = title,
				TextColor3 = theme.colors.onSurface,
				TextSize = metrics.titleSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = "onSurface" })
			handle.title = titleLabel
		end

		local descLabel = nil
		if description ~= nil and description ~= "" then
			descLabel = Creator.new("TextLabel", {
				Name = "Description",
				Position = UDim2.new(0, left, 0, 36),
				Size = UDim2.new(0, textWidth, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = metrics.descSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			handle.desc = descLabel
		end

		local content = nil
		if controlWidth > 0 then
			content = Creator.new("Frame", {
				Name = "Content",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -metrics.padRight, 0.5, 0),
				Size = UDim2.fromOffset(controlWidth, math.max(36, height - 8)),
				BackgroundTransparency = 1,
				Parent = main,
			})
			handle.content = content
		end

		return main, content
	end

	function Row.refreshTheme(handle)
		local theme = handle.window.theme
		if handle.title then
			handle.title.TextColor3 = theme.colors.onSurface
		end
		if handle.desc then
			handle.desc.TextColor3 = theme.colors.onSurfaceVariant
		end
		if handle.icon then
			handle.icon.ImageColor3 = theme.colors.onSurfaceVariant
		end
	end

	return Row

end

__mods["core.Scroll"] = function()
	local Scroll = {}

	local function applyCanvas(scroller, width, height)
		local current = scroller.CanvasSize
		if current.X.Offset == width and current.Y.Offset == height then
			return
		end
		scroller.CanvasSize = UDim2.new(0, width, 0, height)
	end

	function Scroll.bindContent(scroller, content, mode, padding)
		padding = padding or 0

		local function update()
			local size = content.AbsoluteSize
			if mode == "X" then
				local width = math.ceil(size.X + padding)
				if width <= 0 then
					return
				end
				applyCanvas(scroller, width, size.Y)
			else
				local height = math.ceil(size.Y + padding)
				if height <= 0 then
					return
				end
				applyCanvas(scroller, size.X, height)
			end
		end

		content:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		update()
		return update
	end

	function Scroll.bindLayout(scroller, layout, mode, padding)
		padding = padding or 0

		local function update()
			local size = layout.AbsoluteContentSize
			if mode == "X" then
				local width = math.ceil(size.X + padding)
				if width <= 0 then
					return
				end
				applyCanvas(scroller, width, scroller.AbsoluteSize.Y)
			else
				local height = math.ceil(size.Y + padding)
				if height <= 0 then
					return
				end
				applyCanvas(scroller, scroller.AbsoluteSize.X, height)
			end
		end

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
		update()
		return update
	end

	return Scroll

end

__mods["core.Section"] = function()
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Container = __require("core.Container")
	local Icons = __require("icons.Init")

	local Section = {}
	Section.__index = Section

	function Section.new(ctx)
		local props = ctx.props or {}
		local window = ctx.window
		Creator.window = window

		local self = setmetatable({
			window = window,
			container = ctx.container,
			props = props,
			expanded = props.Expanded ~= false,
			__type = "Section",
			__built = false,
			connections = {},
		}, Section)

		Container.init(self)
		return self
	end

	function Section:_build(parentFrame, order)
		local theme = self.window.theme
		local props = self.props

		local main = Creator.new("Frame", {
			Name = "Section",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = theme.colors.surfaceContainerHigh,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Parent = parentFrame,
		}, { BackgroundColor3 = "surfaceContainerHigh" })
		self.main = main

		Creator.new("UICorner", {
			CornerRadius = theme.shape.card,
			Parent = main,
		})
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0.75,
			Thickness = 1,
			Parent = main,
		}, { Color = "outlineVariant" })

		local stack = Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
			Parent = main,
		})

		local header = Creator.new("TextButton", {
			Name = "Header",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = main,
		})
		self.header = header

		local state = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = header,
		}, { BackgroundColor3 = "onSurface" })
		self.state = state

		Creator.new("UICorner", {
			CornerRadius = theme.shape.card,
			Parent = header,
		})

		local left = 16
		if props.Icon then
			local icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = header,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.icon = icon
			left = 16 + 20 + 12
		end

		local title = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, left, 0.5, 0),
			Size = UDim2.new(1, -(left + 44), 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = header,
		}, { TextColor3 = "onSurface" })
		self.title = title

		local chevron = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Image = Icons.image("chevron-down") or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = header,
		}, { ImageColor3 = "onSurfaceVariant" })
		self.chevron = chevron

		local content = Creator.new("Frame", {
			Name = "Content",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = main,
		})
		self.contentFrame = content

		Creator.new("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = content,
		})

		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = content,
		})

		self:_wire()
		self.chevron.Rotation = self.expanded and 0 or -90
		if self.expanded then
			self:flush()
		end
		self._heightConnection = self.contentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if self.expanded and not self._animatingHeight then
				self:_applyHeight(false)
			end
		end)
		task.defer(function()
			if self.main and self.main.Parent then
				self:_applyHeight(false)
			end
		end)
	end

	function Section:_wire()
		local theme = self.window.theme

		self.header.MouseButton1Click:Connect(function()
			self:setExpanded(not self.expanded)
		end)

		self.header.MouseEnter:Connect(function()
			Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)

		self.header.MouseLeave:Connect(function()
			Motion.tween(self.state, { BackgroundTransparency = 1 }, theme.motion.short)
		end)

		self.header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)
			end
		end)

		self.header.InputEnded:Connect(function()
			Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		end)
	end

	function Section:setExpanded(expanded)
		local theme = self.window.theme
		if expanded == self.expanded then
			return
		end
		self.expanded = expanded

		if expanded then
			self.contentFrame.Visible = true
			self:flush()
			task.defer(function()
				self:_applyHeight(true)
			end)
		else
			self:_applyHeight(false)
		end

		Motion.tween(self.chevron, { Rotation = expanded and 0 or -90 }, theme.motion.emphasized)
		self.chevron.Rotation = expanded and 0 or -90
	end

	function Section:_applyHeight(animate)
		local theme = self.window.theme
		local headerHeight = 44
		local contentHeight = self.contentFrame.AbsoluteSize.Y
		local target = self.expanded and (headerHeight + contentHeight) or headerHeight

		if not animate then
			self.main.Size = UDim2.new(1, 0, 0, target)
			if not self.expanded then
				self.contentFrame.Visible = false
			end
			return
		end

		self._animatingHeight = true
		Motion.tween(self.main, { Size = UDim2.new(1, 0, 0, target) }, theme.motion.emphasized)
		task.delay(theme.motion.emphasized.time, function()
			self._animatingHeight = false
			if not self.expanded then
				self.contentFrame.Visible = false
			end
		end)
	end

	function Section:toggle()
		self:setExpanded(not self.expanded)
	end

	function Section:setTitle(text)
		self.title.Text = text
	end

	function Section:reset()
		Container.reset(self)
	end

	function Section:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		self.main.BackgroundColor3 = theme.colors.surfaceContainerHigh
		self.title.TextColor3 = theme.colors.onSurface
		if self.icon then
			self.icon.ImageColor3 = theme.colors.onSurfaceVariant
		end
		self.chevron.ImageColor3 = theme.colors.onSurfaceVariant
	end

	function Section:_destroy()
		if self.main then
			self.main:Destroy()
		end
	end

	setmetatable(Section, { __index = Container })

	return Section

end

__mods["core.Tab"] = function()
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Container = __require("core.Container")
	local Icons = __require("icons.Init")

	local Tab = {}
	Tab.__index = Tab

	function Tab.new(ctx)
		local props = ctx.props or {}
		local window = ctx.window
		Creator.window = window

		local self = setmetatable({
			window = window,
			props = props,
			name = props.Title or props.Name or "Tab",
			icon = props.Icon,
			__type = "Tab",
			__built = false,
			connections = {},
			selected = false,
		}, Tab)

		Container.init(self)
		self:_createSelector()
		self:_createPage()
		return self
	end

	function Tab:_connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(self.connections, connection)
		return connection
	end

	function Tab:_createSelector()
		local window = self.window
		local theme = window.theme
		local sidebar = window.layout == "sidebar"

		local item = Creator.new("TextButton", {
			Name = "TabItem",
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = window.navList,
		})
		self.item = item

		if sidebar then
			item.Size = UDim2.new(1, 0, 0, 42)
			item.AutomaticSize = Enum.AutomaticSize.None
		else
			item.Size = UDim2.new(0, 0, 0, 36)
			item.AutomaticSize = Enum.AutomaticSize.X
		end

		local indicator = Creator.new("Frame", {
			Name = "Indicator",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.secondaryContainer,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = item,
		}, { BackgroundColor3 = "secondaryContainer" })
		self.indicator = indicator

		Creator.new("UICorner", {
			CornerRadius = theme.shape.button,
			Parent = indicator,
		})

		local hover = Creator.new("Frame", {
			Name = "Hover",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = item,
		}, { BackgroundColor3 = "onSurface" })
		self.hover = hover

		local row = Creator.new("Frame", {
			Name = "Row",
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = sidebar and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = item,
		})

		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = row,
		})

		local left = 16
		local icon = nil
		if self.icon then
			icon = Creator.new("ImageLabel", {
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Image = Icons.image(self.icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 0,
				Parent = row,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.iconLabel = icon
			left = 16 + 20 + 10
		end

		local label = Creator.new("TextLabel", {
			Size = UDim2.new(1, -(left + 16), 1, 0),
			AutomaticSize = sidebar and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = theme.fonts.medium,
			Text = self.name,
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.labelLarge.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 1,
			Parent = row,
		}, { TextColor3 = "onSurfaceVariant" })
		self.label = label

		if not sidebar then
			local underline = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 0),
				Size = UDim2.new(1, -24, 0, 3),
				BackgroundColor3 = theme.colors.primary,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = item,
			}, { BackgroundColor3 = "primary" })
			self.underline = underline
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = underline })
		end

		local function onEnter()
			Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end
		local function onLeave()
			Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short)
		end
		item.MouseEnter:Connect(onEnter)
		item.MouseLeave:Connect(onLeave)
		item.MouseButton1Click:Connect(function()
			window:selectTab(self)
		end)

		if not sidebar then
			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				Parent = item,
			})
			self.padding = nil
		end
	end

	function Tab:_createPage()
		local window = self.window
		local page = Creator.new("ScrollingFrame", {
			Name = "Page",
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = window.theme.colors.outlineVariant,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Visible = false,
			Parent = window.pages,
		})
		self.page = page

		local layout = Creator.new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = page,
		})
		self.pageLayout = layout

		local padding = Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			Parent = page,
		})
		self.pagePadding = padding

		local function updateCanvas()
			local width = page.AbsoluteSize.X
			if width <= 0 then
				return
			end
			local content = layout.AbsoluteContentSize or Vector2.new(0, 0)
			local height = content.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset
			local current = page.CanvasSize
			if current.X.Offset == width and current.Y.Offset == math.ceil(height) then
				return
			end
			page.CanvasSize = UDim2.new(0, width, 0, math.ceil(height))
		end
		self._updateCanvas = updateCanvas

		self:_connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
		self:_connect(page:GetPropertyChangedSignal("AbsoluteSize"), updateCanvas)

		self.contentFrame = page
	end

	function Tab:select()
		self.window:selectTab(self)
	end

	function Tab:reset()
		Container.reset(self)
	end

	function Tab:deselect()
		local theme = self.window.theme
		self.selected = false
		Motion.tween(self.indicator, { BackgroundTransparency = 1 }, theme.motion.short)
		if self.underline then
			Motion.tween(self.underline, { BackgroundTransparency = 1 }, theme.motion.short)
		end
		Motion.tween(self.label, { TextColor3 = theme.colors.onSurfaceVariant }, theme.motion.short)
		if self.iconLabel then
			Motion.tween(self.iconLabel, { ImageColor3 = theme.colors.onSurfaceVariant }, theme.motion.short)
		end
	end

	function Tab:_applySelected()
		local theme = self.window.theme
		self.selected = true
		if self.window.layout == "sidebar" then
			Motion.tween(self.indicator, { BackgroundTransparency = 0 }, theme.motion.short)
		elseif self.underline then
			Motion.tween(self.underline, { BackgroundTransparency = 0 }, theme.motion.short)
		end
		Motion.tween(self.label, { TextColor3 = theme.colors.onSurface }, theme.motion.short)
		if self.iconLabel then
			Motion.tween(self.iconLabel, { ImageColor3 = theme.colors.onSurface }, theme.motion.short)
		end
	end

	function Tab:setTitle(text)
		self.name = text
		self.label.Text = text
	end

	function Tab:_rebuild()
		if self.item then
			self.item:Destroy()
		end
		if self.page then
			self.page:Destroy()
		end
		self.item = nil
		self.page = nil
		self:_createSelector()
		self:_createPage()
		self.item.LayoutOrder = self._index or 1
		self.page.LayoutOrder = self._index or 1
		self:reset()
		if self.selected then
			self:flush()
			self:_applySelected()
			self.page.Visible = true
			self.page.Position = UDim2.fromScale(0, 0)
		end
	end

	function Tab:_destroy()
		if self.main then
			self.main:Destroy()
		end
		if self.page then
			self.page:Destroy()
		end
		if self.item then
			self.item:Destroy()
		end
	end

	setmetatable(Tab, { __index = Container })

	return Tab

end

__mods["core.TextMetrics"] = function()
	local Variables = __require("core.Variables")

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

end

__mods["core.Ticker"] = function()
	local Variables = __require("core.Variables")

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

end

__mods["core.Variables"] = function()
	local Services = {
		Players = game:GetService("Players"),
		UserInputService = game:GetService("UserInputService"),
		RunService = game:GetService("RunService"),
		TweenService = game:GetService("TweenService"),
		TextService = game:GetService("TextService"),
		HttpService = game:GetService("HttpService"),
		GuiService = game:GetService("GuiService"),
		ContentProvider = game:GetService("ContentProvider"),
		LocalizationService = game:GetService("LocalizationService"),
		Clipboard = nil,
	}

	local Variables = {
		services = Services,
		container = nil,
		displayOrder = 100,
		screenGui = nil,
		activeInput = nil,
		renderScale = 1,
	}

	function Variables.setContainer(container)
		Variables.container = container
	end

	function Variables.getContainer()
		if Variables.container then
			return Variables.container
		end
		local player = Services.Players.LocalPlayer
		if player then
			return player:WaitForChild("PlayerGui")
		end
		return Services.GuiService
	end

	function Variables.isStudio()
		return Services.RunService:IsStudio()
	end

	function Variables.hasWrite()
		return type(writefile) == "function"
	end

	function Variables.hasRead()
		return type(readfile) == "function"
	end

	function Variables.hasIsFile()
		return type(isfile) == "function"
	end

	function Variables.hasMakeDir()
		return type(makedir) == "function"
	end

	function Variables.hasClipboard()
		return type(setclipboard) == "function"
	end

	function Variables.hasGetAsset()
		return type(getasset) == "function"
	end

	function Variables.getClipboard()
		if type(getclipboard) == "function" then
			return getclipboard()
		end
		return nil
	end

	function Variables.setClipboard(value)
		if type(setclipboard) == "function" then
			setclipboard(value)
			return true
		end
		return false
	end

	function Variables.isExploit()
		return type(request) == "function" or type(getgenv) == "function"
	end

	return Variables

end

__mods["core.Window"] = function()
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Theme = __require("theme.Init")
	local Variables = __require("core.Variables")
	local Locale = __require("locale.Init")
	local Config = __require("config.Init")
	local Icons = __require("icons.Init")
	local Tab = __require("core.Tab")
	local Notification = __require("core.Notification")
	local Popup = __require("core.Popup")

	local Window = {}
	Window.__index = Window

	local TOPBAR_HEIGHT = 64
	local RAIL_WIDTH = 216
	local STRIP_HEIGHT = 48

	function Window.new(props)
		props = props or {}

		local themeSpec = {
			name = props.Theme or "Material",
			mode = props.Mode or "dark",
			seed = props.Accent,
		}
		if type(props.Theme) == "table" then
			for key, value in pairs(props.Theme) do
				themeSpec[key] = value
			end
		end

		local self = setmetatable({
			props = props,
			title = props.Title or "Sonar",
			subtitle = props.Subtitle,
			icon = props.Icon,
			theme = Theme.build(themeSpec),
			layout = props.Layout or "sidebar",
			tabs = {},
			selectedTab = nil,
			flags = {},
			connections = {},
			visible = false,
			animating = false,
			unloaded = false,
			size = props.Size or UDim2.fromOffset(780, 540),
			minSize = props.MinSize or UDim2.fromOffset(520, 360),
		}, Window)

		Creator.window = self

		self.configManager = Config.Manager.new(self)
		self.locale = Locale.new(props.Locale or {})
		self.locale:onChange(function()
			self:_refreshLocale()
		end)

		self:_buildScreen()
		self:_buildSurface()
		self:_buildTopbar()
		self:_buildNavigation()
		self:_buildPages()
		self:_enableDrag()

		self.config = self.configManager:create(props.ConfigName or "config", props.AutoSave ~= false)

		if props.AutoSave ~= false then
			task.defer(function()
				if self.unloaded then
					return
				end
				self.config:load()
				self:_restoreSettings()
			end)
		end

		return self
	end

	function Window:_storeSettings()
		local seed = self.theme.seed
		self.config.custom.theme = {
			name = self.theme.name,
			mode = self.theme.mode,
			seed = { r = seed.R, g = seed.G, b = seed.B },
		}
		self.config.custom.language = self.locale.current
		self.config.custom.layout = self.layout
	end

	function Window:_restoreSettings()
		local custom = self.config.custom
		local theme = custom.theme
		if type(theme) == "table" then
			local seed = theme.seed
			self:setTheme({
				name = theme.name or self.theme.name,
				mode = theme.mode or self.theme.mode,
				seed = type(seed) == "table" and Color3.new(seed.r, seed.g, seed.b) or self.theme.seed,
			})
		end
		if type(custom.language) == "string" and custom.language ~= self.locale.current then
			self:setLanguage(custom.language)
		end
		if type(custom.layout) == "string" and custom.layout ~= self.layout then
			self:setLayout(custom.layout)
		end
	end

	function Window:_connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(self.connections, connection)
		return connection
	end

	function Window:_enableDrag()
		local dragging = false
		local offset = Vector2.new(0, 0)

		self.topbar.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if self.minimised then
				return
			end
			local actions = self.actions
			if actions and actions.AbsoluteSize.X > 0 then
				local rect = actions.AbsolutePosition
				if input.Position.X >= rect.X and input.Position.X <= rect.X + actions.AbsoluteSize.X then
					return
				end
			end
			dragging = true
			local root = self.root
			offset = Vector2.new(
				input.Position.X - root.AbsolutePosition.X,
				input.Position.Y - root.AbsolutePosition.Y
			)
		end)

		self:_connect(Variables.services.UserInputService.InputChanged, function(input)
			if not dragging then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local root = self.root
			local size = root.AbsoluteSize
			local x = input.Position.X - offset.X + size.X / 2
			local y = input.Position.Y - offset.Y + size.Y / 2
			root.Position = UDim2.fromOffset(x, y)
		end)

		self:_connect(Variables.services.UserInputService.InputEnded, function()
			dragging = false
		end)
	end

	function Window:_buildScreen()
		local screen = Instance.new("ScreenGui")
		screen.Name = "Sonar"
		screen.ResetOnSpawn = false
		screen.IgnoreGuiInset = true
		screen.DisplayOrder = Variables.displayOrder
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.Enabled = true
		screen.Parent = Variables.getContainer()
		self.screen = screen

		self.overlay = Instance.new("ScreenGui")
		self.overlay.Name = "SonarOverlay"
		self.overlay.ResetOnSpawn = false
		self.overlay.IgnoreGuiInset = true
		self.overlay.DisplayOrder = Variables.displayOrder + 1
		self.overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		self.overlay.Parent = Variables.getContainer()
		self.overlayGui = self.overlay
	end

	function Window:_buildSurface()
		local theme = self.theme

		local root = Creator.new("Frame", {
			Name = "Root",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = self.size,
			BackgroundTransparency = 1,
		})
		self.root = root
		root.Parent = self.screen

		local surface = Creator.new("Frame", {
			Name = "Surface",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.surface,
			BorderSizePixel = 0,
		}, { BackgroundColor3 = "surface" })
		self.surface = surface
		surface.Parent = root

		Creator.new("UICorner", {
			CornerRadius = theme.shape.window,
			Parent = surface,
		})

		local stroke = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0.4,
			Thickness = 1,
			Parent = surface,
		}, { Color = "outlineVariant" })
		self.stroke = stroke

		local divider = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT - 1),
			BackgroundColor3 = theme.colors.outlineVariant,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = surface,
		}, { BackgroundColor3 = "outlineVariant" })
		self.topDivider = divider
	end

	function Window:_buildTopbar()
		local theme = self.theme
		local topbar = Creator.new("Frame", {
			Name = "Topbar",
			Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = self.surface,
		})
		self.topbar = topbar

		local left = 16
		if self.icon then
			local icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(28, 28),
				BackgroundTransparency = 1,
				Image = Icons.image(self.icon) or "",
				ImageColor3 = theme.colors.onSurface,
				ScaleType = Enum.ScaleType.Fit,
				Parent = topbar,
			}, { ImageColor3 = "onSurface" })
			self.iconLabel = icon
			left = 16 + 28 + 14
		end

		local title = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, left, 0.5, self.subtitle and -10 or 0),
			Size = UDim2.new(1, -(left + 140), 0, 24),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = self.title,
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleLarge.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 4,
			Parent = topbar,
		}, { TextColor3 = "onSurface" })
		self.titleLabel = title

		if self.subtitle then
			local subtitle = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, left, 0.5, 11),
				Size = UDim2.new(1, -(left + 140), 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = self.subtitle,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 4,
				Parent = topbar,
			}, { TextColor3 = "onSurfaceVariant" })
			self.subtitleLabel = subtitle
		end

		local actions = Creator.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 88, 0, 40),
			BackgroundTransparency = 1,
			ZIndex = 4,
			Parent = topbar,
		})
		self.actions = actions

		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = actions,
		})

		local minimiseButton, minimiseIcon = self:_createAction("minimize", "minus", function()
			self:toggleMinimise()
		end)
		self.minimiseButton = minimiseButton
		self.minimiseIcon = minimiseIcon
		self:_createAction("close", "x", function()
			self:close()
		end)
	end

	function Window:_createAction(name, iconName, callback)
		local theme = self.theme
		local button = Creator.new("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = name == "minimize" and 1 or 2,
			Parent = self.actions,
		})
		Creator.new("UICorner", {
			CornerRadius = theme.shape.button,
			Parent = button,
		})
		local hover = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = button,
		}, { BackgroundColor3 = "onSurface" })
		local icon = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Image = Icons.image(iconName) or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = button,
		}, { ImageColor3 = "onSurfaceVariant" })
		button.MouseEnter:Connect(function()
			Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
			Motion.tween(icon, { ImageColor3 = theme.colors.onSurface }, theme.motion.short4)
		end)
		button.MouseLeave:Connect(function()
			Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short4)
			Motion.tween(icon, { ImageColor3 = theme.colors.onSurfaceVariant }, theme.motion.short4)
		end)
		button.MouseButton1Click:Connect(callback)
		return button, icon
	end

	function Window:_buildNavigation()
		local theme = self.theme
		local sidebar = self.layout == "sidebar"

		local nav = Creator.new("Frame", {
			Name = "Navigation",
			BackgroundTransparency = 1,
			Parent = self.surface,
		})
		self.nav = nav

		local list = Creator.new("ScrollingFrame", {
			Name = "NavList",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollingDirection = sidebar and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = nav,
		})
		self.navList = list

		local navLayout = Creator.new("UIListLayout", {
			FillDirection = sidebar and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, sidebar and 4 or 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Parent = list,
		})
		self.navLayout = navLayout

		local navPadding = 0
		local function updateNavCanvas()
			local content = navLayout.AbsoluteContentSize or Vector2.new(0, 0)
			local width = list.AbsoluteSize.X
			local height = list.AbsoluteSize.Y
			if sidebar then
				if width <= 0 then
					return
				end
				local target = math.ceil(content.Y + navPadding)
				if list.CanvasSize.Y.Offset == target then
					return
				end
				list.CanvasSize = UDim2.new(0, width, 0, target)
			else
				if height <= 0 then
					return
				end
				local target = math.ceil(content.X)
				if list.CanvasSize.X.Offset == target then
					return
				end
				list.CanvasSize = UDim2.new(0, target, 0, height)
			end
		end
		self:_connect(navLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateNavCanvas)
		self:_connect(list:GetPropertyChangedSignal("AbsoluteSize"), updateNavCanvas)
		self._updateNavCanvas = updateNavCanvas

		if sidebar then
			nav.Size = UDim2.new(0, RAIL_WIDTH, 1, -TOPBAR_HEIGHT)
			nav.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
			list.Size = UDim2.new(1, 0, 1, 0)
			Creator.new("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = list,
			})
			navPadding = 20
			local divider = Creator.new("Frame", {
				Size = UDim2.new(0, 1, 1, -28),
				Position = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = theme.colors.outlineVariant,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Parent = nav,
			}, { BackgroundColor3 = "outlineVariant" })
			self.navDivider = divider
		else
			nav.Size = UDim2.new(1, 0, 0, STRIP_HEIGHT)
			nav.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
			list.Size = UDim2.new(1, 0, 1, 0)
			Creator.new("UIPadding", {
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 7),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				Parent = list,
			})
			local divider = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = theme.colors.outlineVariant,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Parent = nav,
			}, { BackgroundColor3 = "outlineVariant" })
			self.navDivider = divider
		end
	end

	function Window:_buildPages()
		local sidebar = self.layout == "sidebar"
		local inset = 8
		local pages = Creator.new("Frame", {
			Name = "Pages",
			BackgroundColor3 = self.theme.colors.surfaceContainer,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = self.surface,
		}, { BackgroundColor3 = "surfaceContainer" })
		self.pages = pages

		Creator.new("UICorner", {
			CornerRadius = self.theme.shape.card,
			Parent = pages,
		})

		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = self.theme.colors.outlineVariant,
			Transparency = 0.6,
			Thickness = 1,
			Parent = pages,
		}, { Color = "outlineVariant" })

		if sidebar then
			pages.Size = UDim2.new(1, -(RAIL_WIDTH + inset * 2), 1, -(TOPBAR_HEIGHT + inset * 2))
			pages.Position = UDim2.new(0, RAIL_WIDTH + inset, 0, TOPBAR_HEIGHT + inset)
		else
			pages.Size = UDim2.new(1, -(inset * 2), 1, -(TOPBAR_HEIGHT + STRIP_HEIGHT + inset * 2))
			pages.Position = UDim2.new(0, inset, 0, TOPBAR_HEIGHT + STRIP_HEIGHT + inset)
		end

		self.pageLayout = nil
	end

	function Window:createTab(props)
		props = props or {}
		local tab = Tab.new({ window = self, props = props })
		table.insert(self.tabs, tab)
		tab._index = #self.tabs
		tab.item.LayoutOrder = tab._index
		tab.page.LayoutOrder = tab._index
		if self._updateNavCanvas then
			self._updateNavCanvas()
		end
		if not self.selectedTab then
			self:selectTab(tab, true)
		end
		return tab
	end

	function Window:selectTab(tab, instant)
		if self.selectedTab == tab then
			return
		end
		local previous = self.selectedTab
		if previous then
			previous:deselect()
		end
		self.selectedTab = tab
		tab.selected = true
		tab:_applySelected()
		tab:flush()
		self:_swapPages(previous, tab, instant)
	end

	function Window:_swapPages(previous, tab, instant)
		local theme = self.theme
		local vertical = self.layout == "sidebar"
		local rest = UDim2.fromScale(0, 0)
		local enter = vertical and UDim2.new(0, 1, 0, 0) or UDim2.new(1, 0, 0, 0)

		if previous and previous ~= tab and previous.page then
			previous.page.Visible = false
			previous.page.Position = rest
		end

		if not tab.page then
			return
		end

		tab.page.Visible = true
		if instant then
			tab.page.Position = rest
		else
			tab.page.Position = enter
			Motion.tween(tab.page, { Position = rest }, theme.motion.short)
		end
	end

	function Window:setLayout(layout)
		layout = layout or "sidebar"
		if layout == self.layout or (layout ~= "sidebar" and layout ~= "top") then
			return
		end
		self.layout = layout

		if self.nav then
			self.nav:Destroy()
		end
		if self.pages then
			self.pages:Destroy()
		end

		self:_buildNavigation()
		self:_buildPages()

		local current = self.selectedTab
		for _, tab in ipairs(self.tabs) do
			tab:_rebuild()
		end

		self.selectedTab = nil
		if current then
			self:selectTab(current, true)
		end
		self:_storeSettings()
		self:_persist(self)
	end

	function Window:navigate(name)
		for _, tab in ipairs(self.tabs) do
			if tab.name == name then
				self:selectTab(tab)
				return true
			end
		end
		return false
	end

	function Window:setTheme(spec)
		local themeSpec = {
			name = self.theme.name,
			mode = self.theme.mode,
			seed = self.theme.seed,
		}
		if type(spec) == "string" then
			themeSpec.name = spec
		elseif type(spec) == "table" then
			for key, value in pairs(spec) do
				themeSpec[key] = value
			end
			themeSpec.name = themeSpec.name or self.theme.name
			themeSpec.mode = themeSpec.mode or self.theme.mode
			themeSpec.seed = themeSpec.seed or self.theme.seed
		end

		self.theme = Theme.build(themeSpec)
		local previousSurface = self.surface.BackgroundColor3
		Creator.applyTheme(self.theme, false)
		local nextSurface = self.surface.BackgroundColor3
		self.surface.BackgroundColor3 = previousSurface
		Motion.tween(self.surface, { BackgroundColor3 = nextSurface }, self.theme.motion.emphasized)
		if self.selectedTab then
			self.selectedTab:_applySelected()
		end
		self:_refreshElementThemes()
		self:_storeSettings()
		self:_persist(self)
	end

	function Window:setAccent(color)
		self:setTheme({ seed = color })
	end

	function Window:_refreshElementThemes()
		for _, tab in ipairs(self.tabs) do
			for _, child in ipairs(tab.children) do
				if child._refreshTheme then
					child:_refreshTheme()
				end
			end
		end
	end

	function Window:_refreshLocale()
		for _, tab in ipairs(self.tabs) do
			for _, child in ipairs(tab.children) do
				if child._localeRefresh then
					child:_localeRefresh()
				end
			end
		end
	end

	function Window:setLanguage(language)
		self.locale:setLanguage(language)
		self:_storeSettings()
		self:_persist(self)
	end

	function Window:show()
		if self.visible or self.unloaded then
			return
		end
		self.visible = true
		self.root.Visible = true
		self.animating = true
		local target = self.size
		local shrunk = UDim2.new(
			target.X.Scale,
			target.X.Offset,
			target.Y.Scale,
			target.Y.Offset
		)
		local from = UDim2.new(target.X.Scale * 0.96, target.X.Offset, target.Y.Scale * 0.96, target.Y.Offset)
		self.root.Size = from
		Motion.tween(self.root, { Size = shrunk }, self.theme.motion.emphasizedDecelerate)
		Motion.tween(self.surface, { BackgroundTransparency = 0 }, self.theme.motion.emphasizedDecelerate)
		task.delay(self.theme.motion.emphasizedDecelerate.time, function()
			self.animating = false
		end)
	end

	function Window:hide()
		if not self.visible or self.unloaded then
			return
		end
		self.visible = false
		self.animating = true
		local target = self.size
		Motion.tween(self.root, {
			Size = UDim2.new(target.X.Scale * 0.96, target.X.Offset, target.Y.Scale * 0.96, target.Y.Offset),
		}, self.theme.motion.emphasizedAccelerate)
		Motion.tween(self.surface, { BackgroundTransparency = 1 }, self.theme.motion.emphasizedAccelerate)
		task.delay(self.theme.motion.emphasizedAccelerate.time, function()
			self.animating = false
			self.root.Visible = false
		end)
	end

	function Window:toggle()
		if self.visible then
			self:hide()
		else
			self:show()
		end
	end

	function Window:toggleMinimise()
		local theme = self.theme
		if not self.minimised then
			self.minimised = true
			self._restoreSize = self.root.Size
			self._restorePosition = self.root.Position

			self.nav.Visible = false
			self.pages.Visible = false
			if self.topDivider then
				self.topDivider.Visible = false
			end
			if self.navDivider then
				self.navDivider.Visible = false
			end
			if self.subtitleLabel then
				self.subtitleLabel.Visible = false
			end
			self.minimiseIcon.Image = Icons.image("chevron-up") or ""

			local screen = self.screen.AbsoluteSize
			local width = math.min(320, math.max(200, screen.X - 40))
			Motion.tween(self.root, {
				Size = UDim2.fromOffset(width, 52),
				Position = UDim2.fromOffset(screen.X / 2, 44),
			}, theme.motion.emphasizedDecelerate)
		else
			self.minimised = false
			self.nav.Visible = true
			self.pages.Visible = true
			if self.topDivider then
				self.topDivider.Visible = true
			end
			if self.navDivider then
				self.navDivider.Visible = true
			end
			if self.subtitleLabel then
				self.subtitleLabel.Visible = true
			end
			self.minimiseIcon.Image = Icons.image("minus") or ""
			Motion.tween(self.root, {
				Size = self._restoreSize or self.size,
				Position = self._restorePosition or UDim2.fromScale(0.5, 0.5),
			}, theme.motion.emphasizedDecelerate)
		end
	end

	function Window:notify(props)
		return Notification.create(self, props)
	end

	function Window:popup(props)
		return Popup.create(self, props)
	end

	function Window:saveConfig()
		return self.config:save()
	end

	function Window:_persist(element)
		if element ~= self and not element.flag then
			return
		end
		if self.props.AutoSave == false then
			return
		end
		if self._savePending then
			return
		end
		self._savePending = true
		task.delay(0.6, function()
			self._savePending = false
			if self.unloaded or not self.config then
				return
			end
			task.spawn(function()
				self.config:save()
			end)
		end)
	end

	function Window:loadConfig()
		return self.config:load()
	end

	function Window:listConfigs()
		return self.configManager:list()
	end

	function Window:deleteConfig(name)
		return self.configManager:delete(name)
	end

	function Window:close()
		if self.unloaded or self.closing then
			return
		end
		self.closing = true
		self.animating = true
		local theme = self.theme
		local target = self.root.Size
		Motion.tween(self.surface, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
		Motion.tween(self.root, {
			Size = UDim2.new(target.X.Scale * 0.94, target.X.Offset, target.Y.Scale * 0.94, target.Y.Offset),
		}, theme.motion.emphasizedAccelerate)
		task.delay(theme.motion.emphasizedAccelerate.time, function()
			self:unload()
		end)
	end

	function Window:unload()
		if self.unloaded then
			return
		end
		self.unloaded = true
		for _, connection in ipairs(self.connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		self.connections = {}
		if self.root then
			self.root:Destroy()
		end
		if self.screen then
			self.screen:Destroy()
		end
		if self.overlay then
			self.overlay:Destroy()
		end
		Creator.destroyAll()
	end

	return Window

end

__mods["elements.Badge"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Badge = {}

	local VARIANTS = {
		neutral = { fill = "surfaceContainerHighest", text = "onSurfaceVariant" },
		primary = { fill = "primaryContainer", text = "onPrimaryContainer" },
		success = { fill = "tertiaryContainer", text = "onTertiaryContainer" },
		error = { fill = "errorContainer", text = "onErrorContainer" },
	}

	function Badge.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Badge",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local variant = VARIANTS[props.Variant] or VARIANTS.neutral

			local main = Creator.new("Frame", {
				Name = "Badge",
				LayoutOrder = order,
				Size = UDim2.new(0, 0, 0, 26),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = theme.colors[variant.fill],
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Parent = parentFrame,
			}, { BackgroundColor3 = variant.fill })
			self.main = main

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = main,
			})

			local row = Creator.new("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Parent = main,
			})

			Creator.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Parent = row,
			})

			if props.Icon then
				local icon = Creator.new("ImageLabel", {
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Image = Icons.image(props.Icon) or "",
					ImageColor3 = theme.colors[variant.text],
					ScaleType = Enum.ScaleType.Fit,
					LayoutOrder = 0,
					Parent = row,
				}, { ImageColor3 = variant.text })
				self.icon = icon
			end

			local label = Creator.new("TextLabel", {
				Size = UDim2.new(0, 0, 0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Text or "",
				TextColor3 = theme.colors[variant.text],
				TextSize = theme.type.labelMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			}, { TextColor3 = variant.text })
			self.label = label

			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = main,
			})
		end

		function handle:setText(text)
			if self.label then
				self.label.Text = text
			end
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			local variant = VARIANTS[self.props.Variant] or VARIANTS.neutral
			self.main.BackgroundColor3 = theme.colors[variant.fill]
			self.label.TextColor3 = theme.colors[variant.text]
			if self.icon then
				self.icon.ImageColor3 = theme.colors[variant.text]
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Badge.new }

end

__mods["elements.Button"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Button = {}

	local VARIANTS = {
		filled = { fill = "primary", text = "onPrimary" },
		tonal = { fill = "secondaryContainer", text = "onSecondaryContainer" },
		outlined = { fill = "surface", text = "primary", stroke = "outline" },
		text = { fill = "surface", text = "primary" },
		elevated = { fill = "surfaceContainerHigh", text = "primary" },
		danger = { fill = "errorContainer", text = "onErrorContainer" },
	}

	local SIZES = {
		sm = { height = 32, text = "labelMedium", pad = 14, icon = 16 },
		md = { height = 40, text = "labelLarge", pad = 18, icon = 18 },
		lg = { height = 52, text = "labelLarge", pad = 24, icon = 22 },
	}

	function Button.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Button",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local variant = VARIANTS[props.Variant] or VARIANTS.filled
			local size = SIZES[props.Size] or SIZES.md
			local transparent = variant.fill == "surface"

			local main = Creator.new("TextButton", {
				Name = "Button",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, size.height),
				BackgroundColor3 = theme.colors[variant.fill],
				BackgroundTransparency = transparent and 1 or 0,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = parentFrame,
			}, {
				BackgroundColor3 = variant.fill,
				BackgroundTransparency = transparent and 1 or 0,
			})
			self.main = main

			Creator.new("UICorner", {
				CornerRadius = theme.shape.button,
				Parent = main,
			})

			if variant.stroke then
				Creator.new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = theme.colors[variant.stroke],
					Transparency = 0,
					Thickness = 1,
					Parent = main,
				}, { Color = variant.stroke })
			end

			local state = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors[variant.text],
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = main,
			}, { BackgroundColor3 = variant.text })
			self.state = state

			local align = props.IconAlign or "Left"
			local iconSize = size.icon
			local textLeft = size.pad

			local text = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, textLeft, 0.5, 0),
				Size = UDim2.new(1, -(size.pad * 2), 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.medium,
				Text = props.Title or "",
				TextColor3 = theme.colors[variant.text],
				TextSize = theme.type[size.text].size,
				TextXAlignment = align == "Right" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = variant.text })
			self.text = text

			if props.Icon then
				local icon = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = align == "Right"
						and UDim2.new(1, -size.pad - iconSize, 0.5, 0)
						or UDim2.new(0, size.pad, 0.5, 0),
					Size = UDim2.fromOffset(iconSize, iconSize),
					BackgroundTransparency = 1,
					Image = Icons.image(props.Icon) or "",
					ImageColor3 = theme.colors[variant.text],
					ScaleType = Enum.ScaleType.Fit,
					Parent = main,
				}, { ImageColor3 = variant.text })
				self.icon = icon

				if align == "Right" then
					text.Position = UDim2.new(0, size.pad, 0.5, 0)
					text.Size = UDim2.new(1, -(size.pad * 2 + iconSize + 10), 1, 0)
				else
					textLeft = size.pad + iconSize + 10
					text.Position = UDim2.new(0, textLeft, 0.5, 0)
					text.Size = UDim2.new(1, -(textLeft + size.pad), 1, 0)
				end
			end

			Element.connect(self, main.MouseEnter, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, main.MouseLeave, function()
				Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, main.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Motion.tween(state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)
				end
			end)
			Element.connect(self, main.InputEnded, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
			end)
			Element.connect(self, main.MouseButton1Click, function()
				if props.Locked or self.locked then
					return
				end
				if props.Callback then
					task.spawn(props.Callback)
				end
			end)

			if props.Locked then
				Element.setLocked(self, true, props.LockedTitle)
			end
		end

		function handle:SetDisabled(disabled)
			self.disabled = disabled
			if self.main then
				self.main.Active = not disabled
			end
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			local variant = VARIANTS[self.props.Variant] or VARIANTS.filled
			self.main.BackgroundColor3 = theme.colors[variant.fill]
			self.text.TextColor3 = theme.colors[variant.text]
			if self.icon then
				self.icon.ImageColor3 = theme.colors[variant.text]
			end
			self.state.BackgroundColor3 = theme.colors[variant.text]
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Button.new }

end

__mods["elements.Checkbox"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Checkbox = {}

	local SIZES = {
		Checkbox = 20,
		Radio = 20,
	}

	function Checkbox.new(ctx)
		local props = ctx.props or {}
		local radio = props.Variant == "Radio"
		local handle = Element.new({
			typeName = radio and "Radio" or "Checkbox",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Value == true

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local size = SIZES[radio and "Radio" or "Checkbox"]

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = size,
				parent = parentFrame,
				order = order,
			})

			local content = self.content
			local box = Creator.new("TextButton", {
				Name = radio and "Radio" or "Checkbox",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(size, size),
				BackgroundColor3 = theme.colors.surface,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = content,
			}, { BackgroundColor3 = "surface" })
			self.box = box

			Creator.new("UICorner", {
				CornerRadius = radio and UDim.new(1, 0) or UDim.new(0, 3),
				Parent = box,
			})

			local stroke = Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.onSurfaceVariant,
				Transparency = 0,
				Thickness = 2,
				Parent = box,
			}, { Color = "onSurfaceVariant" })
			self.stroke = stroke

			local state = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.onSurface,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = box,
			}, { BackgroundColor3 = "onSurface" })
			self.boxState = state

			local mark
			if radio then
				mark = Creator.new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(10, 10),
					BackgroundColor3 = theme.colors.onPrimary,
					BorderSizePixel = 0,
					Parent = box,
				}, { BackgroundColor3 = "onPrimary" })
				Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })
			else
				mark = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Image = Icons.image("check") or "",
					ImageColor3 = theme.colors.onPrimary,
					ImageTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					Parent = box,
				}, { ImageColor3 = "onPrimary" })
			end
			self.mark = mark

			Element.connect(self, box.MouseEnter, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, box.MouseLeave, function()
				Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, box.MouseButton1Click, function()
				if self.locked then
					return
				end
				self:Set(not self.value, true)
			end)

			self:_render()
		end

		function handle:_render()
			local theme = self.window.theme
			local on = self.value == true
			local token = theme.motion.short

			Motion.tween(self.box, {
				BackgroundColor3 = on and theme.colors.primary or theme.colors.surface,
			}, token)
			Motion.tween(self.stroke, {
				Color = on and theme.colors.primary or theme.colors.onSurfaceVariant,
				Transparency = on and 1 or 0,
			}, token)

			if self.mark:IsA("ImageLabel") then
				Motion.tween(self.mark, {
					ImageTransparency = on and 0 or 1,
					ImageColor3 = on and theme.colors.onPrimary or theme.colors.surface,
				}, token)
			else
				Motion.tween(self.mark, {
					Size = on and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
					BackgroundColor3 = theme.colors.onPrimary,
				}, token)
			end
		end

		function handle:Set(value, skipCallback)
			value = value == true
			if self.value == value and self.main then
				return
			end
			self.value = value
			if self.main then
				self:_render()
			end
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			Row.refreshTheme(self)
			self:_render()
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Checkbox.new }

end

__mods["elements.ChipGroup"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local ChipGroup = {}

	local CHIP_HEIGHT = 32

	local VARIANTS = {
		assist = { fill = "surface", text = "onSurface", stroke = "outline" },
		filter = { fill = "surface", text = "onSurfaceVariant", stroke = "outline" },
		input = { fill = "surface", text = "onSurface", stroke = "outline" },
		suggestion = { fill = "surfaceContainerHigh", text = "onSurface", stroke = nil },
		tonal = { fill = "secondaryContainer", text = "onSecondaryContainer", stroke = nil },
	}

	function ChipGroup.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "ChipGroup",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.options = props.Options or {}
		handle.multi = props.Multi == true
		handle.value = props.Value
		if handle.multi and type(handle.value) ~= "table" then
			handle.value = handle.value and { handle.value } or {}
		end

		local function label(option)
			if type(option) == "string" then
				return option
			end
			return option.Title or ""
		end

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local main = Creator.new("Frame", {
				Name = "ChipGroup",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main

			Creator.new("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Parent = main,
			})

			if props.Title then
				local title = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Font = theme.fonts.bold,
					Text = props.Title,
					TextColor3 = theme.colors.onSurface,
					TextSize = theme.type.titleMedium.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = main,
				}, { TextColor3 = "onSurface" })
				title.LayoutOrder = 1
				self.title = title
			end

			if props.Description then
				local desc = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Font = theme.fonts.regular,
					Text = props.Description,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.bodySmall.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				desc.LayoutOrder = 2
				self.desc = desc
			end

			local inner = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = main,
			})
			inner.LayoutOrder = 3
			self.inner = inner

			Creator.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Wraps = true,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Parent = inner,
			})

			self.chips = {}
			for index, option in ipairs(self.options) do
				self:_buildChip(option, index)
			end

			self:_renderSelection()
		end

		function handle:_buildChip(option, index)
			local theme = self.window.theme
			local variant = VARIANTS[self.props.Variant] or VARIANTS.assist

			local chip = Creator.new("TextButton", {
				Name = "Chip",
				Size = UDim2.new(0, 0, 0, CHIP_HEIGHT),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = theme.colors[variant.fill],
				BackgroundTransparency = variant.fill == "surface" and 1 or 0,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = self.inner,
			}, {
				BackgroundColor3 = variant.fill,
				BackgroundTransparency = variant.fill == "surface" and 1 or 0,
			})
			Creator.new("UICorner", {
				CornerRadius = theme.shape.chip,
				Parent = chip,
			})

			if variant.stroke then
				Creator.new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = theme.colors[variant.stroke],
					Transparency = 0,
					Thickness = 1,
					Parent = chip,
				}, { Color = variant.stroke })
			end

			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = chip,
			})

			local text = ""
			local iconName = nil
			if type(option) == "string" then
				text = option
			else
				text = option.Title or ""
				iconName = option.Icon
			end

			local row = Creator.new("Frame", {
				Name = "Row",
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Parent = chip,
			})

			Creator.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Parent = row,
			})

			local label = Creator.new("TextLabel", {
				Size = UDim2.new(0, 0, 0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = text,
				TextColor3 = theme.colors[variant.text],
				TextSize = theme.type.labelLarge.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			}, { TextColor3 = variant.text })

			if iconName then
				local icon = Creator.new("ImageLabel", {
					Size = UDim2.fromOffset(16, 16),
					BackgroundTransparency = 1,
					Image = Icons.image(iconName) or "",
					ImageColor3 = theme.colors[variant.text],
					ScaleType = Enum.ScaleType.Fit,
					LayoutOrder = 0,
					Parent = row,
				}, { ImageColor3 = variant.text })
				self.chipIcon = icon
			end

			local check = nil
			if self.multi or self.props.Variant == "filter" then
				check = Creator.new("ImageLabel", {
					Size = UDim2.fromOffset(16, 16),
					BackgroundTransparency = 1,
					Image = Icons.image("check") or "",
					ImageColor3 = theme.colors.primary,
					ImageTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					LayoutOrder = 2,
					Parent = row,
				}, { ImageColor3 = "primary" })
			end

			Element.connect(self, chip.MouseButton1Click, function()
				if self.locked then
					return
				end
				if type(option) == "table" and option.Disabled then
					return
				end
				if self.multi then
					local existing = nil
					for index, entry in ipairs(self.value or {}) do
						if (type(entry) == "string" and entry == text) or (type(entry) == "table" and entry.Title == text) then
							existing = index
							break
						end
					end
					if existing then
						table.remove(self.value, existing)
					else
						table.insert(self.value, option)
					end
					self:_renderSelection()
					if props.Callback then
						task.spawn(props.Callback, self.value)
					end
				else
					self:Set(option, true)
					if props.Callback then
						task.spawn(props.Callback, option)
					end
				end
				if self.window and self.flag then
					self.window:_persist(self)
				end
			end)

			self.chips[index] = { chip = chip, label = label, check = check, option = option, text = text }
		end

		function handle:_renderSelection()
			local theme = self.window.theme
			for _, data in ipairs(self.chips) do
				local selected = false
				if self.multi then
					for _, entry in ipairs(self.value or {}) do
						local entryText = type(entry) == "string" and entry or (entry.Title or "")
						if entryText == data.text then
							selected = true
							break
						end
					end
				else
					local current = self.value
					local currentText = type(current) == "string" and current or (current and current.Title or "")
					selected = currentText == data.text
				end

				local variant = VARIANTS[self.props.Variant] or VARIANTS.assist
				if selected then
					Motion.tween(data.chip, { BackgroundTransparency = 0 }, theme.motion.short4)
					Motion.tween(data.chip, { BackgroundColor3 = theme.colors.secondaryContainer }, theme.motion.short4)
					Motion.tween(data.label, { TextColor3 = theme.colors.onSecondaryContainer }, theme.motion.short4)
					if data.check then
						Motion.tween(data.check, { ImageTransparency = 0 }, theme.motion.short4)
					end
				else
					Motion.tween(data.chip, { BackgroundTransparency = variant.fill == "surface" and 1 or 0 }, theme.motion.short4)
					Motion.tween(data.chip, { BackgroundColor3 = theme.colors[variant.fill] }, theme.motion.short4)
					Motion.tween(data.label, { TextColor3 = theme.colors[variant.text] }, theme.motion.short4)
					if data.check then
						Motion.tween(data.check, { ImageTransparency = 1 }, theme.motion.short4)
					end
				end
			end
		end

		function handle:Set(value, skipCallback)
			if self.multi then
				self.value = value or {}
			else
				self.value = value
			end
			self:_renderSelection()
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, self.value)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			if self.title then
				self.title.TextColor3 = theme.colors.onSurface
			end
			if self.desc then
				self.desc.TextColor3 = theme.colors.onSurfaceVariant
			end
			self:_renderSelection()
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = ChipGroup.new }

end

__mods["elements.Code"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")
	local Scroll = __require("core.Scroll")
	local Variables = __require("core.Variables")

	local Code = {}

	local KEYWORDS = {
		["and"] = true,
		["break"] = true,
		["do"] = true,
		["else"] = true,
		["elseif"] = true,
		["end"] = true,
		["false"] = true,
		["for"] = true,
		["function"] = true,
		["if"] = true,
		["in"] = true,
		["local"] = true,
		["nil"] = true,
		["not"] = true,
		["or"] = true,
		["repeat"] = true,
		["return"] = true,
		["then"] = true,
		["true"] = true,
		["until"] = true,
		["while"] = true,
		["continue"] = true,
		["export"] = true,
		["type"] = true,
	}

	local function highlight(source, palette)
		local result = {}
		local index = 1
		local length = #source

		while index <= length do
			local char = source:sub(index, index)
			local two = source:sub(index, index + 1)

			if source:sub(index, index + 1) == "--" then
				local stop = source:find("\n", index) or (length + 1)
				table.insert(result, string.format('<font color="%s">%s</font>', palette.comment, source:sub(index, stop - 1)))
				index = stop
			elseif char == '"' or char == "'" then
				local stop = index + 1
				while stop <= length do
					if source:sub(stop, stop) == "\\" then
						stop = stop + 2
					elseif source:sub(stop, stop) == char then
						break
					else
						stop = stop + 1
					end
				end
				local text = source:sub(index, math.min(stop, length))
				table.insert(result, string.format('<font color="%s">%s</font>', palette.string, text))
				index = math.min(stop + 1, length + 1)
			elseif char:match("%d") then
				local stop = index
				while stop <= length and source:sub(stop, stop):match("[%d%.xXa-fA-F]") do
					stop = stop + 1
				end
				table.insert(result, string.format('<font color="%s">%s</font>', palette.number, source:sub(index, stop - 1)))
				index = stop
			elseif char:match("[%a_]") then
				local stop = index
				while stop <= length and source:sub(stop, stop):match("[%w_]") do
					stop = stop + 1
				end
				local word = source:sub(index, stop - 1)
				if KEYWORDS[word] then
					table.insert(result, string.format('<font color="%s">%s</font>', palette.keyword, word))
				else
					table.insert(result, word)
				end
				index = stop
			elseif two == "==" or two == "~=" or two == "<=" or two == ">=" or two == ".." or two == "->" or two == "::" then
				table.insert(result, string.format('<font color="%s">%s</font>', palette.operator, tostring(two)))
				index = index + 2
			else
				table.insert(result, char)
				index = index + 1
			end
		end

		return table.concat(result)
	end

	function Code.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Code",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local palette = {
				comment = theme.colors.onSurfaceVariant:ToHex(),
				string = theme.colors.tertiary:ToHex(),
				number = theme.colors.primary:ToHex(),
				keyword = theme.colors.secondary:ToHex(),
				operator = theme.colors.onSurfaceVariant:ToHex(),
			}

			local main = Creator.new("Frame", {
				Name = "Code",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, props.Height or 0),
				AutomaticSize = props.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
				BackgroundColor3 = theme.colors.surfaceContainerLow,
				BorderSizePixel = 0,
				Parent = parentFrame,
			}, { BackgroundColor3 = "surfaceContainerLow" })
			self.main = main

			Creator.new("UICorner", {
				CornerRadius = theme.shape.card,
				Parent = main,
			})

			local header = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				Parent = main,
			})

			local title = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 14, 0.5, 0),
				Size = UDim2.new(1, -70, 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Title or "code",
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.labelMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = header,
			}, { TextColor3 = "onSurfaceVariant" })
			self.title = title

			local copy = Creator.new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Parent = header,
			})

			local copyIcon = Creator.new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = Icons.image("copy") or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = copy,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.copyIcon = copyIcon

			Element.connect(self, copy.MouseButton1Click, function()
				Variables.setClipboard(props.Code or "")
				Motion.tween(copyIcon, { Image = Icons.image("check") or "" }, theme.motion.short4)
				task.delay(1.2, function()
					if copyIcon.Parent then
						Motion.tween(copyIcon, { Image = Icons.image("copy") or "" }, theme.motion.short4)
					end
				end)
			end)

			local scroller = Creator.new("ScrollingFrame", {
				Size = UDim2.new(1, 0, props.Height and 1 or 0, props.Height and 0 or 0),
				AutomaticSize = props.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = theme.colors.outlineVariant,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ElasticBehavior = Enum.ElasticBehavior.Never,
				Parent = main,
			})
			self.scroller = scroller

			local code = Creator.new("TextLabel", {
				Size = UDim2.new(1, -24, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = theme.fonts.mono,
				RichText = true,
				Text = "",
				TextColor3 = theme.colors.onSurface,
				TextSize = props.CodeSize or 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = props.Wrap ~= false,
				Parent = scroller,
			}, { TextColor3 = "onSurface" })
			self.code = code

			Creator.new("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				Parent = scroller,
			})

			Scroll.bindContent(scroller, code, "Y", 20)

			self:Set(props.Code or "")
		end

		function handle:Set(source)
			self.source = source
			if not self.code then
				return
			end
			local theme = self.window.theme
			local palette = {
				comment = theme.colors.onSurfaceVariant:ToHex(),
				string = theme.colors.tertiary:ToHex(),
				number = theme.colors.primary:ToHex(),
				keyword = theme.colors.secondary:ToHex(),
				operator = theme.colors.onSurfaceVariant:ToHex(),
			}
			self.code.Text = highlight(source or "", palette)
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			self.main.BackgroundColor3 = theme.colors.surfaceContainerLow
			self.title.TextColor3 = theme.colors.onSurfaceVariant
			self.code.TextColor3 = theme.colors.onSurface
			self:Set(self.source or "")
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Code.new }

end

__mods["elements.ColorPicker"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Variables = __require("core.Variables")
	local Icons = __require("icons.Init")

	local ColorPicker = {}

	local function rgbToHsv(color)
		local r, g, b = color.R, color.G, color.B
		local max = math.max(r, g, b)
		local min = math.min(r, g, b)
		local delta = max - min
		local h = 0
		if delta > 0 then
			if max == r then
				h = (60 * ((g - b) / delta)) % 360
			elseif max == g then
				h = (60 * ((b - r) / delta) + 120) % 360
			else
				h = (60 * ((r - g) / delta) + 240) % 360
			end
		end
		local s = 0
		if max > 0 then
			s = delta / max
		end
		return h / 360, s, max
	end

	local function hsvToRgb(h, s, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p = v * (1 - s)
		local q = v * (1 - f * s)
		local t = v * (1 - (1 - f) * s)
		local r, g, b = 0, 0, 0
		if i % 6 == 0 then
			r, g, b = v, t, p
		elseif i % 6 == 1 then
			r, g, b = q, v, p
		elseif i % 6 == 2 then
			r, g, b = p, v, t
		elseif i % 6 == 3 then
			r, g, b = p, q, v
		elseif i % 6 == 4 then
			r, g, b = t, p, v
		else
			r, g, b = v, p, q
		end
		return Color3.new(r, g, b)
	end

	local function hueGradient()
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
	end

	function ColorPicker.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "ColorPicker",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Color or Color3.fromRGB(255, 255, 255)
		handle.alpha = props.Alpha or 0

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = 44,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local swatch = Creator.new("TextButton", {
				Name = "Swatch",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(44, 44),
				BackgroundColor3 = self.value,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = content,
			}, { BackgroundColor3 = "surface" })
			self.swatch = swatch

			Creator.new("UICorner", {
				CornerRadius = theme.shape.field,
				Parent = swatch,
			})
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = swatch,
			}, { Color = "outlineVariant" })

			local hover = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.onSurface,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = swatch,
			}, { BackgroundColor3 = "onSurface" })
			self.state = hover

			Element.connect(self, swatch.MouseEnter, function()
				Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, swatch.MouseLeave, function()
				Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, swatch.MouseButton1Click, function()
				if self.locked then
					return
				end
				self:open()
			end)
		end

		function handle:_render()
			if not self.swatch then
				return
			end
			self.swatch.BackgroundColor3 = self.value
		end

		function handle:open()
			if self.dialog then
				return
			end
			local window = self.window
			local theme = window.theme
			local overlay = window.overlayGui

			local scrim = Creator.new("Frame", {
				Name = "ColorScrim",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.scrim,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = overlay,
			}, { BackgroundColor3 = "scrim" })

			local dialog = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(324, 400),
				BackgroundColor3 = theme.colors.surfaceContainerHigh,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = scrim,
			}, { BackgroundColor3 = "surfaceContainerHigh" })
			self.dialog = dialog

			Creator.new("UICorner", {
				CornerRadius = theme.shape.dialog,
				Parent = dialog,
			})

			local stack = Creator.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				Parent = dialog,
			})

			Creator.new("UIPadding", {
				PaddingTop = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				Parent = dialog,
			})

			local heading = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Title or "Colour",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.titleLarge.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = dialog,
			}, { TextColor3 = "onSurface" })
			heading.LayoutOrder = 1

			local previewRow = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 56),
				BackgroundTransparency = 1,
				Parent = dialog,
			})
			previewRow.LayoutOrder = 2

			local preview = Creator.new("Frame", {
				Size = UDim2.fromOffset(56, 56),
				BackgroundColor3 = self.value,
				BorderSizePixel = 0,
				Parent = previewRow,
			}, { BackgroundColor3 = "surface" })
			Creator.new("UICorner", {
				CornerRadius = UDim.new(0, 12),
				Parent = preview,
			})
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = preview,
			}, { Color = "outlineVariant" })
			self.preview = preview

			local previewText = Creator.new("TextLabel", {
				Position = UDim2.new(0, 72, 0, 4),
				Size = UDim2.new(1, -72, 0, 20),
				BackgroundTransparency = 1,
				Font = theme.fonts.mono,
				Text = "",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = previewRow,
			}, { TextColor3 = "onSurface" })
			self.previewText = previewText

			local plane = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 150),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = dialog,
			}, { BackgroundColor3 = "surface" })
			plane.LayoutOrder = 3
			self.plane = plane

			Creator.new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = plane })

			Creator.new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0)),
				Parent = plane,
			})

			local sat = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 0, 0),
				BorderSizePixel = 0,
				Parent = plane,
			})
			Creator.new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = sat })
			Creator.new("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new(Color3.new(1, 1, 1)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Parent = sat,
			})
			self.sat = sat

			local cursor = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = plane,
			})
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cursor })
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(0, 0, 0),
				Transparency = 0.15,
				Thickness = 3,
				Parent = cursor,
			})
			self.cursor = cursor

			local hueTrack = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = dialog,
			}, { BackgroundColor3 = "surface" })
			hueTrack.LayoutOrder = 4
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueTrack })
			Creator.new("UIGradient", {
				Color = hueGradient(),
				Parent = hueTrack,
			})

			local hueCursor = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(14, 22),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = hueTrack,
			})
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueCursor })
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(0, 0, 0),
				Transparency = 0.2,
				Thickness = 2,
				Parent = hueCursor,
			})
			self.hueCursor = hueCursor

			local alphaTrack = nil
			local alphaCursor = nil
			if props.Alpha ~= nil then
				alphaTrack = Creator.new("Frame", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundColor3 = self.value,
					BorderSizePixel = 0,
					Parent = dialog,
				}, { BackgroundColor3 = "surface" })
				alphaTrack.LayoutOrder = 5
				Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = alphaTrack })
				Creator.new("UIGradient", {
					Rotation = 0,
					Color = ColorSequence.new(self.value),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					}),
					Parent = alphaTrack,
				})
				alphaCursor = Creator.new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(14, 22),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Parent = alphaTrack,
				})
				Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = alphaCursor })
				Creator.new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.new(0, 0, 0),
					Transparency = 0.2,
					Thickness = 2,
					Parent = alphaCursor,
				})
			end

			local hexBox = Creator.new("TextBox", {
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				Text = "",
				PlaceholderText = "#RRGGBB",
				PlaceholderColor3 = theme.colors.onSurfaceVariant,
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyMedium.size,
				Font = theme.fonts.mono,
				ClearTextOnFocus = false,
				Parent = dialog,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			hexBox.LayoutOrder = 6
			Creator.new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = hexBox })
			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = hexBox,
			})
			self.hexBox = hexBox

			local actions = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				Parent = dialog,
			})
			actions.LayoutOrder = 7
			Creator.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = actions,
			})

			local state = { h = 0, s = 0, v = 1, a = self.alpha }
			local dragging = nil
			local moveConnection = nil
			local endConnection = nil

			local function applyColor()
				self.value = hsvToRgb(state.h, state.s, state.v)
				self.alpha = state.a
				self:_render()
				preview.BackgroundColor3 = self.value
				previewText.Text = string.format("%s  %d%%", self.value:ToHex(), math.floor(state.a * 100))
				if alphaTrack then
					alphaTrack.BackgroundColor3 = self.value
				end
				hexBox.Text = self.value:ToHex()
			end

			local function updateFromPlane(position)
				local size = plane.AbsoluteSize
				if size.X <= 0 or size.Y <= 0 then
					return
				end
				state.s = math.clamp((position.X - plane.AbsolutePosition.X) / size.X, 0, 1)
				state.v = math.clamp(1 - (position.Y - plane.AbsolutePosition.Y) / size.Y, 0, 1)
				applyColor()
			end

			local function updateFromHue(position)
				local size = hueTrack.AbsoluteSize
				if size.X <= 0 then
					return
				end
				state.h = math.clamp((position.X - hueTrack.AbsolutePosition.X) / size.X, 0, 1)
				sat.BackgroundColor3 = hsvToRgb(state.h, 1, 1)
				applyColor()
			end

			local function updateFromAlpha(position)
				local size = alphaTrack.AbsoluteSize
				if size.X <= 0 then
					return
				end
				state.a = math.clamp((position.X - alphaTrack.AbsolutePosition.X) / size.X, 0, 1)
				applyColor()
			end

			local function stopDrag()
				dragging = nil
				if moveConnection then
					moveConnection:Disconnect()
					moveConnection = nil
				end
				if endConnection then
					endConnection:Disconnect()
					endConnection = nil
				end
			end

			local function beginDrag(kind)
				dragging = kind
				if moveConnection then
					moveConnection:Disconnect()
				end
				if endConnection then
					endConnection:Disconnect()
				end
				moveConnection = Variables.services.UserInputService.InputChanged:Connect(function(changed)
					if dragging ~= kind then
						return
					end
					if changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
						if kind == "plane" then
							updateFromPlane(changed.Position)
						elseif kind == "hue" then
							updateFromHue(changed.Position)
						elseif kind == "alpha" then
							updateFromAlpha(changed.Position)
						end
					end
				end)
				endConnection = Variables.services.UserInputService.InputEnded:Connect(function()
					stopDrag()
				end)
			end

			plane.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					beginDrag("plane")
					updateFromPlane(input.Position)
				end
			end)
			hueTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					beginDrag("hue")
					updateFromHue(input.Position)
				end
			end)
			if alphaTrack then
				alphaTrack.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						beginDrag("alpha")
						updateFromAlpha(input.Position)
					end
				end)
			end

			hexBox.FocusLost:Connect(function()
				local text = hexBox.Text:gsub("#", "")
				if #text == 6 then
					local ok, color = pcall(Color3.fromHex, text)
					if ok then
						local h, s, v = rgbToHsv(color)
						state.h = h
						state.s = s
						state.v = v
						sat.BackgroundColor3 = hsvToRgb(state.h, 1, 1)
						applyColor()
					end
				end
			end)

			local function makeButton(text, order, primary)
				local button = Creator.new("TextButton", {
					Size = UDim2.new(0, 0, 0, 40),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = primary and theme.colors.primary or theme.colors.surfaceContainerHighest,
					BackgroundTransparency = primary and 0 or 0,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = text,
					Font = theme.fonts.bold,
					TextColor3 = primary and theme.colors.onPrimary or theme.colors.onSurface,
					TextSize = theme.type.labelLarge.size,
					LayoutOrder = order,
					Parent = actions,
				}, {
					BackgroundColor3 = primary and "primary" or "surfaceContainerHighest",
					TextColor3 = primary and "onPrimary" or "onSurface",
				})
				Creator.new("UICorner", {
					CornerRadius = theme.shape.button,
					Parent = button,
				})
				Creator.new("UIPadding", {
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 20),
					Parent = button,
				})
				return button
			end

			local cancel = makeButton("Cancel", 1, false)
			local apply = makeButton("Apply", 2, true)

			local function close()
				stopDrag()
				self.dialog = nil
				Motion.tween(scrim, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
				Motion.tween(dialog, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
				task.delay(theme.motion.emphasizedAccelerate.time, function()
					scrim:Destroy()
				end)
			end

			cancel.MouseButton1Click:Connect(function()
				close()
			end)
			apply.MouseButton1Click:Connect(function()
				self:Set(self.value, self.alpha, true)
				close()
			end)

			local h, s, v = rgbToHsv(self.value)
			state.h = h
			state.s = s
			state.v = v
			state.a = self.alpha
			sat.BackgroundColor3 = hsvToRgb(state.h, 1, 1)
			applyColor()

			local function placeCursors()
				cursor.Position = UDim2.new(state.s, 0, 1 - state.v, 0)
				hueCursor.Position = UDim2.new(state.h, 0, 0.5, 0)
				if alphaCursor then
					alphaCursor.Position = UDim2.new(state.a, 0, 0.5, 0)
				end
			end
			placeCursors()
			Element.connect(self, plane:GetPropertyChangedSignal("AbsoluteSize"), placeCursors)
			Element.connect(self, hueTrack:GetPropertyChangedSignal("AbsoluteSize"), placeCursors)

			Motion.tween(scrim, { BackgroundTransparency = 0.6 }, theme.motion.emphasizedDecelerate)
			Motion.tween(dialog, { BackgroundTransparency = 0 }, theme.motion.emphasizedDecelerate)
		end

		function handle:Set(color, alpha, skipCallback)
			self.value = color
			if alpha ~= nil then
				self.alpha = alpha
			end
			self:_render()
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, self.value, self.alpha)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			self.title.TextColor3 = theme.colors.onSurface
			if self.desc then
				self.desc.TextColor3 = theme.colors.onSurfaceVariant
			end
		end

		function handle:_destroy()
			if self.dialog then
				self.dialog:Destroy()
				self.dialog = nil
			end
			Element.destroy(self)
		end

		return handle
	end

	return { new = ColorPicker.new }

end

__mods["elements.Console"] = function()
	local Element = __require("core.Element")
	local Scroll = __require("core.Scroll")
	local Creator = __require("core.Creator")

	local Console = {}

	local LEVELS = {
		info = "onSurface",
		warn = "tertiary",
		error = "error",
		success = "primary",
	}

	function Console.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Console",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.lines = {}
		handle.labels = {}
		handle.head = 1
		handle.order = 0

		function handle:write(text, level)
			level = level or "info"
			text = tostring(text)

			local maxLines = props.MaxLines or 60

			if #self.lines >= maxLines then
				table.move(self.lines, 2, #self.lines, 1)
				self.lines[#self.lines] = text
			else
				table.insert(self.lines, text)
			end

			if not self.scroller then
				if props.Callback then
					task.spawn(props.Callback, text, level)
				end
				return
			end

			local theme = self.window.theme
			local color = theme.colors[LEVELS[level] or "onSurface"]
			self.order = self.order + 1

			local label
			if #self.lines <= maxLines and #self.labels < #self.lines then
				local index = #self.lines
				label = self.labels[index]
				if not label then
					label = Creator.new("TextLabel", {
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						Font = theme.fonts.mono,
						Text = "",
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextWrapped = true,
						Parent = self.scroller,
					})
					self.labels[index] = label
				end
			else
				label = self.labels[self.head]
				self.head = (self.head % maxLines) + 1
			end

			if label then
				label.LayoutOrder = self.order
				label.Text = text
				label.TextColor3 = color
				label.Visible = true
			end

			if props.Follow ~= false then
				task.defer(function()
					if self.scroller and self.scroller.Parent then
						self.scroller.CanvasPosition = Vector2.new(0, self.scroller.AbsoluteCanvasSize.Y)
					end
				end)
			end

			if props.Callback then
				task.spawn(props.Callback, text, level)
			end
		end

		function handle:clear()
			self.lines = {}
			self.head = 1
			self.order = 0
			for _, label in ipairs(self.labels) do
				label.Visible = false
			end
		end

		function handle:getText()
			return table.concat(self.lines, "\n")
		end

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local height = props.Height or 160

			local main = Creator.new("Frame", {
				Name = "Console",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, height),
				BackgroundColor3 = theme.colors.surfaceContainerLow,
				BorderSizePixel = 0,
				Parent = parentFrame,
			}, { BackgroundColor3 = "surfaceContainerLow" })
			self.main = main

			Creator.new("UICorner", {
				CornerRadius = theme.shape.card,
				Parent = main,
			})

			local scroller = Creator.new("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = theme.colors.outlineVariant,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ElasticBehavior = Enum.ElasticBehavior.Never,
				Parent = main,
			})
			self.scroller = scroller

			local listLayout = Creator.new("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = scroller,
			})

			Creator.new("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = scroller,
			})

			Scroll.bindLayout(scroller, listLayout, "Y", 20)

			for _, text in ipairs(self.lines) do
				self:write(text, "info")
			end
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			self.main.BackgroundColor3 = self.window.theme.colors.surfaceContainerLow
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Console.new }

end

__mods["elements.Divider"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")

	local Divider = {}

	function Divider.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Divider",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local main = Creator.new("Frame", {
				Name = "Divider",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, props.Text and 26 or 10),
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main

			local line = Creator.new("Frame", {
				Position = UDim2.new(0, 0, 0, props.Text and 13 or 5),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = theme.colors.outlineVariant,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Parent = main,
			}, { BackgroundColor3 = "outlineVariant" })
			self.line = line

			if props.Text then
				local label = Creator.new("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0, 13),
					Size = UDim2.new(0, 0, 0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = theme.colors.surfaceContainerHigh,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					Font = theme.fonts.bold,
					Text = props.Text,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.labelSmall.size,
					TextXAlignment = Enum.TextXAlignment.Center,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				self.label = label
			end
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			self.line.BackgroundColor3 = theme.colors.outlineVariant
			if self.label then
				self.label.TextColor3 = theme.colors.onSurfaceVariant
				self.label.BackgroundColor3 = theme.colors.surfaceContainerHigh
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Divider.new }

end

__mods["elements.Dropdown"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")
	local Scroll = __require("core.Scroll")
	local Variables = __require("core.Variables")

	local Dropdown = {}

	local function normalize(options)
		local result = {}
		for _, option in ipairs(options or {}) do
			if type(option) == "string" then
				table.insert(result, { Title = option })
			elseif type(option) == "table" then
				table.insert(result, option)
			end
		end
		return result
	end

	function Dropdown.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Dropdown",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.options = normalize(props.Options)
		handle.value = props.Value
		handle.multi = props.Multi == true
		if handle.multi and type(handle.value) ~= "table" then
			handle.value = handle.value and { handle.value } or {}
		end

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = 170,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local trigger = Creator.new("TextButton", {
				Name = "Trigger",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(170, 40),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = content,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.trigger = trigger

			Creator.new("UICorner", {
				CornerRadius = theme.shape.field,
				Parent = trigger,
			})

			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = trigger,
			}, { Color = "outlineVariant" })

			local state = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.onSurface,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = trigger,
			}, { BackgroundColor3 = "onSurface" })
			self.state = state

			local display = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 14, 0.5, 0),
				Size = UDim2.new(1, -46, 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = "",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyLarge.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = trigger,
			}, { TextColor3 = "onSurface" })
			self.display = display

			local chevron = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Image = Icons.image("chevron-down") or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = trigger,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.chevron = chevron

			if props.Description then
				local desc = Creator.new("TextLabel", {
					Position = UDim2.new(0, 0, 1, -20),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Font = theme.fonts.regular,
					Text = props.Description,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.bodySmall.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				self.desc = desc
			end

			Element.connect(self, trigger.MouseEnter, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, trigger.MouseLeave, function()
				Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, trigger.MouseButton1Click, function()
				if self.locked then
					return
				end
				if self.menu then
					self:close()
				else
					self:open()
				end
			end)

			Motion.tween(self.chevron, { Rotation = 0 }, theme.motion.standard)

			self:_updateDisplay()
		end

		function handle:_updateDisplay()
			if not self.display then
				return
			end
			local value = self.value
			if self.multi then
				local names = {}
				for _, entry in ipairs(value or {}) do
					table.insert(names, entry.Title or tostring(entry))
				end
				self.display.Text = #names > 0 and table.concat(names, ", ") or (props.Placeholder or "Select")
			elseif type(value) == "table" then
				self.display.Text = value.Title or ""
			elseif value == nil then
				self.display.Text = props.Placeholder or "Select"
			else
				self.display.Text = tostring(value)
			end
		end

		function handle:open()
			if self.menu then
				return
			end
			local window = self.window
			local theme = window.theme
			local overlay = window.overlayGui

			local menu = Creator.new("CanvasGroup", {
				Name = "DropdownMenu",
				AnchorPoint = Vector2.new(1, 0),
				Size = UDim2.fromOffset(self.trigger.AbsoluteSize.X, 0),
				BackgroundColor3 = theme.colors.surfaceContainerHigh,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				GroupTransparency = 1,
				Parent = overlay,
			}, { BackgroundColor3 = "surfaceContainerHigh" })
			self.menu = menu

			local menuSurface = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.surfaceContainerHigh,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Parent = menu,
			}, { BackgroundColor3 = "surfaceContainerHigh" })
			self.menuSurface = menuSurface

			Creator.new("UICorner", {
				CornerRadius = theme.shape.menu,
				Parent = menuSurface,
			})
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = menuSurface,
			}, { Color = "outlineVariant" })

			local list = Creator.new("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = theme.colors.outlineVariant,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ElasticBehavior = Enum.ElasticBehavior.Never,
				Parent = menuSurface,
			})
			self.menuList = list

			local listLayout = Creator.new("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = list,
			})

			Creator.new("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				Parent = list,
			})

			Scroll.bindLayout(list, listLayout, "Y", 12)

			self.rows = {}
			for index, option in ipairs(self.options) do
				self:_buildRow(option, index)
			end

			local rows = math.max(1, #self.options)
			local height = math.min(rows * 40 + 12, 260)
			menu.Size = UDim2.fromOffset(self.trigger.AbsoluteSize.X, height)

			local anchor = self.trigger.AbsolutePosition
			local screen = overlay.AbsoluteSize
			local y = anchor.Y + self.trigger.AbsoluteSize.Y + 4
			local flip = false
			if y + height > screen.Y - 8 then
				y = anchor.Y - height - 4
				flip = true
			end
			menu.AnchorPoint = Vector2.new(1, flip and 1 or 0)
			menu.Position = UDim2.fromOffset(anchor.X + self.trigger.AbsoluteSize.X, y + (flip and 6 or -6))

			Motion.tween(menu, {
				GroupTransparency = 0,
				Position = UDim2.fromOffset(anchor.X + self.trigger.AbsoluteSize.X, y),
			}, theme.motion.emphasizedDecelerate)

			self._closeConn = Variables.services.UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local inside = self.menu and (input.Position.X >= self.menu.AbsolutePosition.X
						and input.Position.X <= self.menu.AbsolutePosition.X + self.menu.AbsoluteSize.X
						and input.Position.Y >= self.menu.AbsolutePosition.Y
						and input.Position.Y <= self.menu.AbsolutePosition.Y + self.menu.AbsoluteSize.Y)
					local onTrigger = input.Position.X >= self.trigger.AbsolutePosition.X
						and input.Position.X <= self.trigger.AbsolutePosition.X + self.trigger.AbsoluteSize.X
						and input.Position.Y >= self.trigger.AbsolutePosition.Y
						and input.Position.Y <= self.trigger.AbsolutePosition.Y + self.trigger.AbsoluteSize.Y
					if not inside and not onTrigger then
						self:close()
					end
				end
			end)
		end

		function handle:_buildRow(option, index)
			local theme = self.window.theme
			local list = self.menuList
			local row = Creator.new("TextButton", {
				Size = UDim2.new(1, -8, 0, 36),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = list,
			})

			Creator.new("UICorner", {
				CornerRadius = theme.shape.menu,
				Parent = row,
			})

			local hover = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.onSurface,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = row,
			}, { BackgroundColor3 = "onSurface" })

			local check = nil
			if self.multi then
				check = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					BackgroundTransparency = 1,
					Image = Icons.image("check") or "",
					ImageColor3 = theme.colors.primary,
					ImageTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					Parent = row,
				}, { ImageColor3 = "primary" })
			end

			local label = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, self.multi and 32 or 12, 0.5, 0),
				Size = UDim2.new(1, -(self.multi and 44 or 24), 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = option.Title or "",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			}, { TextColor3 = "onSurface" })

			row.MouseEnter:Connect(function()
				Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
			end)
			row.MouseLeave:Connect(function()
				Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short4)
			end)

			row.MouseButton1Click:Connect(function()
				if option.Disabled then
					return
				end
				if option.Callback and not self.multi then
					task.spawn(option.Callback, option)
					self:close()
					return
				end
				if self.multi then
					local exists = false
					for _, entry in ipairs(self.value or {}) do
						if entry.Title == option.Title then
							exists = true
							break
						end
					end
					if exists then
						for index, entry in ipairs(self.value) do
							if entry.Title == option.Title then
								table.remove(self.value, index)
								break
							end
						end
					else
						table.insert(self.value, option)
					end
					if check then
						local selected = false
						for _, entry in ipairs(self.value) do
							if entry.Title == option.Title then
								selected = true
								break
							end
						end
						Motion.tween(check, { ImageTransparency = selected and 0 or 1 }, theme.motion.short)
					end
					self:_updateDisplay()
					if props.Callback then
						task.spawn(props.Callback, self.value)
					end
				else
					self:Set(option.Title or tostring(option), true)
					self:close()
				end
			end)

			self.rows[index] = { row = row, label = label, check = check, option = option }
		end

		function handle:close()
			if not self.menu then
				return
			end
			local theme = self.window.theme
			Motion.tween(self.menu, { GroupTransparency = 1 }, theme.motion.emphasizedAccelerate)
			Motion.tween(self.chevron, { Rotation = 0 }, theme.motion.standard)
			local menu = self.menu
			self.menu = nil
			if self._closeConn then
				self._closeConn:Disconnect()
				self._closeConn = nil
			end
			task.delay(theme.motion.emphasizedAccelerate.time, function()
				menu:Destroy()
			end)
		end

		function handle:Set(value, skipCallback)
			if self.multi then
				self.value = value or {}
			else
				self.value = value
			end
			self:_updateDisplay()
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, self.value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:refresh(options)
			self.options = normalize(options)
			if self.menu then
				self:close()
			end
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			self.trigger.BackgroundColor3 = theme.colors.surfaceContainerHighest
			self.display.TextColor3 = theme.colors.onSurface
			self.chevron.ImageColor3 = theme.colors.onSurfaceVariant
		end

		function handle:_destroy()
			if self._closeConn then
				self._closeConn:Disconnect()
				self._closeConn = nil
			end
			if self.menu then
				self.menu:Destroy()
				self.menu = nil
			end
			Element.destroy(self)
		end

		return handle
	end

	return { new = Dropdown.new }

end

__mods["elements.Image"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Image = {}

	local function parseAspect(value)
		if type(value) == "number" then
			return value
		end
		if type(value) == "string" then
			local width, height = value:match("^(%d+):(%d+)$")
			if width and height then
				return tonumber(width) / tonumber(height)
			end
		end
		return 16 / 9
	end

	function Image.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Image",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local ratio = parseAspect(props.AspectRatio)
			local width = props.Width or 320
			local height = props.Height or math.floor(width / ratio)

			local main = Creator.new("Frame", {
				Name = "Image",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, height + (props.Caption and 24 or 0)),
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main

			local holder = Creator.new("Frame", {
				Size = UDim2.fromOffset(width, height),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				Parent = main,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.holder = holder

			Creator.new("UICorner", {
				CornerRadius = props.Radius and UDim.new(0, props.Radius) or theme.shape.card,
				Parent = holder,
			})
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = holder,
			}, { Color = "outlineVariant" })

			local image = Creator.new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = props.Image or "",
				ScaleType = Enum.ScaleType.Crop,
				Parent = holder,
			})
			self.image = image

			local caption = nil
			if props.Caption then
				caption = Creator.new("TextLabel", {
					Position = UDim2.new(0, 2, 1, -20),
					Size = UDim2.new(1, -4, 0, 18),
					BackgroundTransparency = 1,
					Font = theme.fonts.regular,
					Text = props.Caption,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.bodySmall.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				self.caption = caption
			end
		end

		function handle:SetImage(url)
			if self.image then
				self.image.Image = url or ""
			end
			self.props.Image = url
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			self.holder.BackgroundColor3 = theme.colors.surfaceContainerHighest
			if self.caption then
				self.caption.TextColor3 = theme.colors.onSurfaceVariant
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Image.new }

end

__mods["elements.ImageUploader"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local ImageUploader = {}

	local PREVIEW_HEIGHT = 150

	function ImageUploader.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "ImageUploader",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.variant = props.Variant or "input"
		handle.value = props.Image or nil

		local function normalize(source)
			if type(source) == "number" then
				return "rbxassetid://" .. tostring(source)
			end
			if type(source) ~= "string" then
				return nil
			end
			local trimmed = source:gsub("%s", "")
			if trimmed == "" then
				return nil
			end
			if trimmed:match("^%d+$") then
				return "rbxassetid://" .. trimmed
			end
			return trimmed
		end

		handle.setSource = function(self, source)
			local normalized = normalize(source)
			self.value = normalized
			if self.preview then
				self.preview.Image = normalized or ""
			end
			if self.emptyState then
				self.emptyState.Visible = normalized == nil
			end
			if self.urlBox then
				self.urlBox.Text = normalized or ""
			end
			if props.Callback and normalized ~= nil then
				task.spawn(props.Callback, normalized)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local preset = self.variant == "preset"

			local main = Creator.new("Frame", {
				Name = "ImageUploader",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main

			Creator.new("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Parent = main,
			})

			if props.Title then
				local title = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Font = theme.fonts.bold,
					Text = props.Title,
					TextColor3 = theme.colors.onSurface,
					TextSize = theme.type.titleMedium.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
					Parent = main,
				}, { TextColor3 = "onSurface" })
				self.title = title
			end

			if not preset then
				local field = Creator.new("Frame", {
					Name = "Field",
					Size = UDim2.new(1, 0, 0, 56),
					BackgroundColor3 = theme.colors.surfaceContainerHighest,
					BorderSizePixel = 0,
					LayoutOrder = 2,
					Parent = main,
				}, { BackgroundColor3 = "surfaceContainerHighest" })
				self.field = field

				Creator.new("UICorner", {
					CornerRadius = theme.shape.field,
					Parent = field,
				})

				local indicator = Creator.new("Frame", {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, 0),
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = theme.colors.onSurfaceVariant,
					BackgroundTransparency = 0.7,
					BorderSizePixel = 0,
					Parent = field,
				}, { BackgroundColor3 = "onSurfaceVariant" })
				self.indicator = indicator

				local label = Creator.new("TextLabel", {
					Position = UDim2.new(0, 16, 0, 6),
					Size = UDim2.new(1, -32, 0, 16),
					BackgroundTransparency = 1,
					Font = theme.fonts.bold,
					Text = props.Placeholder or "Image id or link",
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.labelMedium.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = field,
				}, { TextColor3 = "onSurfaceVariant" })
				self.label = label

				local urlBox = Creator.new("TextBox", {
					Name = "TextBox",
					Position = UDim2.new(0, 16, 0, 24),
					Size = UDim2.new(1, -32, 1, -28),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					PlaceholderText = "",
					TextColor3 = theme.colors.onSurface,
					TextSize = theme.type.bodyLarge.size,
					Font = theme.fonts.regular,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					ClearTextOnFocus = false,
					Parent = field,
				}, { TextColor3 = "onSurface" })
				self.urlBox = urlBox

				Element.connect(self, urlBox.Focused, function()
					Motion.tween(indicator, {
						BackgroundColor3 = theme.colors.primary,
						BackgroundTransparency = 0,
					}, theme.motion.standard)
				end)

				Element.connect(self, urlBox.FocusLost, function()
					Motion.tween(indicator, {
						BackgroundColor3 = theme.colors.onSurfaceVariant,
						BackgroundTransparency = 0.7,
					}, theme.motion.standard)
					self:setSource(urlBox.Text)
				end)

				Element.connect(self, urlBox:GetPropertyChangedSignal("Text"), function()
					if urlBox.Text == "" then
						self:setSource(nil)
					end
				end)
			end

			local previewFrame = Creator.new("Frame", {
				Name = "Preview",
				Size = UDim2.new(1, 0, 0, PREVIEW_HEIGHT),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				LayoutOrder = preset and 2 or 3,
				Parent = main,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.previewFrame = previewFrame

			Creator.new("UICorner", {
				CornerRadius = theme.shape.card,
				Parent = previewFrame,
			})
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = previewFrame,
			}, { Color = "outlineVariant" })

			local preview = Creator.new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = self.value or "",
				ScaleType = Enum.ScaleType.Fit,
				Parent = previewFrame,
			})
			self.preview = preview

			local emptyState = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = self.value == nil,
				Parent = previewFrame,
			})
			self.emptyState = emptyState

			local emptyIcon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -10),
				Size = UDim2.fromOffset(28, 28),
				BackgroundTransparency = 1,
				Image = Icons.image("image") or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = emptyState,
			}, { ImageColor3 = "onSurfaceVariant" })

			local emptyText = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 18),
				Size = UDim2.new(0.8, 0, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.EmptyText or "Preview appears here",
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = emptyState,
			}, { TextColor3 = "onSurfaceVariant" })

			if props.Description then
				local desc = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Font = theme.fonts.regular,
					Text = props.Description,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.bodySmall.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					LayoutOrder = 4,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				self.desc = desc
			end
		end

		function handle:Set(value, skipCallback)
			local normalized = value
			if type(value) == "number" then
				normalized = "rbxassetid://" .. tostring(value)
			end
			self.value = normalized
			if self.preview then
				self.preview.Image = normalized or ""
			end
			if self.emptyState then
				self.emptyState.Visible = normalized == nil
			end
			if self.urlBox then
				self.urlBox.Text = normalized or ""
			end
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, normalized)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			if self.title then
				self.title.TextColor3 = theme.colors.onSurface
			end
			if self.field then
				self.field.BackgroundColor3 = theme.colors.surfaceContainerHighest
			end
			if self.previewFrame then
				self.previewFrame.BackgroundColor3 = theme.colors.surfaceContainerHighest
			end
			if self.desc then
				self.desc.TextColor3 = theme.colors.onSurfaceVariant
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = ImageUploader.new }

end

__mods["elements.Init"] = function()
	local Elements = {}

	local MODULES = {
		Badge = "Badge",
		Button = "Button",
		Checkbox = "Checkbox",
		ChipGroup = "ChipGroup",
		Code = "Code",
		ColorPicker = "ColorPicker",
		Console = "Console",
		Divider = "Divider",
		Dropdown = "Dropdown",
		Image = "Image",
		ImageUploader = "ImageUploader",
		Input = "Input",
		Keybind = "Keybind",
		Paragraph = "Paragraph",
		ProgressBar = "ProgressBar",
		Radio = "Radio",
		Rating = "Rating",
		Slider = "Slider",
		Space = "Space",
		Stat = "Stat",
		TextArea = "TextArea",
		Toggle = "Toggle",
	}

	local cache = {}

	function Elements.get(name)
		if cache[name] then
			return cache[name]
		end
		local file = MODULES[name]
		if not file then
			return nil
		end
		local module = __require("elements." .. file)
		cache[name] = module
		return module
	end

	function Elements.names()
		local names = {}
		for name in pairs(MODULES) do
			table.insert(names, name)
		end
		table.sort(names)
		return names
	end

	return Elements

end

__mods["elements.Input"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Input = {}

	function Input.new(ctx)
		local props = ctx.props or {}
		local typeName = ctx.typeName or "Input"
		local handle = Element.new({
			typeName = typeName,
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Value or ""

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local multiline = typeName == "TextArea"
			local fieldHeight = multiline and 108 or 56

			local main = Creator.new("Frame", {
				Name = typeName,
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, fieldHeight + (props.Description and 24 or 0)),
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main

			local field = Creator.new("Frame", {
				Name = "Field",
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, fieldHeight),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				Parent = main,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.field = field

			Creator.new("UICorner", {
				CornerRadius = theme.shape.field,
				Parent = field,
			})

			local indicator = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = theme.colors.onSurfaceVariant,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Parent = field,
			}, { BackgroundColor3 = "onSurfaceVariant" })
			self.indicator = indicator

			local fieldLeft = 16
			if props.Icon then
				local fieldIcon = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 16, 0.5, 0),
					Size = UDim2.fromOffset(18, 18),
					BackgroundTransparency = 1,
					Image = Icons.image(props.Icon) or "",
					ImageColor3 = theme.colors.onSurfaceVariant,
					ScaleType = Enum.ScaleType.Fit,
					Parent = field,
				}, { ImageColor3 = "onSurfaceVariant" })
				self.fieldIcon = fieldIcon
				fieldLeft = 16 + 18 + 12
			end

			local label = Creator.new("TextLabel", {
				Position = UDim2.new(0, fieldLeft, 0, 18),
				Size = UDim2.new(1, -(fieldLeft + 16), 0, 20),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Placeholder or props.Title or "",
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodyLarge.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = field,
			}, { TextColor3 = "onSurfaceVariant" })
			self.label = label

			local textbox = Creator.new("TextBox", {
				Name = "TextBox",
				Position = UDim2.new(0, fieldLeft, 0, multiline and 34 or 24),
				Size = UDim2.new(1, -(fieldLeft + 16), 1, multiline and -42 or -28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				PlaceholderText = "",
				PlaceholderColor3 = theme.colors.onSurfaceVariant,
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyLarge.size,
				Font = theme.fonts.regular,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				TextWrapped = multiline,
				MultiLine = multiline,
				ClearTextOnFocus = props.ClearOnFocus == true,
				TextEditable = props.Disabled ~= true,
				Parent = field,
			}, { TextColor3 = "onSurface" })
			self.textbox = textbox

			if props.Description then
				local desc = Creator.new("TextLabel", {
					Position = UDim2.new(0, 2, 0, fieldHeight + 6),
					Size = UDim2.new(1, -4, 0, 18),
					BackgroundTransparency = 1,
					Font = theme.fonts.regular,
					Text = props.Description,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.bodySmall.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				self.desc = desc
			end

			local function applyLabel(floating, focused)
				local theme = self.window.theme
				local size = floating and theme.type.labelMedium.size or theme.type.bodyLarge.size
				local top = floating and 6 or (multiline and 12 or 18)
				local text = floating and (props.Title or props.Placeholder or "") or (props.Placeholder or props.Title or "")

				self.label.Text = text
				self.label.TextSize = size
				self.label.TextColor3 = focused and theme.colors.primary or theme.colors.onSurfaceVariant
				self.label.Font = floating and theme.fonts.bold or theme.fonts.regular
				Motion.tween(self.label, {
					Position = UDim2.new(0, fieldLeft, 0, top),
				}, theme.motion.standard)
				self.label.Position = UDim2.new(0, fieldLeft, 0, top)
			end

			Element.connect(self, textbox.Focused, function()
				applyLabel(true, true)
				Motion.tween(indicator, {
					BackgroundColor3 = theme.colors.primary,
					BackgroundTransparency = 0,
				}, theme.motion.standard)
			end)

			Element.connect(self, textbox.FocusLost, function()
				if textbox.Text == "" then
					applyLabel(false, false)
				else
					applyLabel(true, false)
				end
				Motion.tween(indicator, {
					BackgroundColor3 = theme.colors.onSurfaceVariant,
					BackgroundTransparency = 0.7,
				}, theme.motion.standard)
				self:_commit()
			end)

			Element.connect(self, textbox:GetPropertyChangedSignal("Text"), function()
				local text = textbox.Text
				if props.Numeric and text ~= "" then
					local cleaned = text:gsub("[^%d%.%-]", "")
					if cleaned ~= text then
						textbox.Text = cleaned
						text = cleaned
					end
				end
				if props.MaxLength and #text > props.MaxLength then
					textbox.Text = string.sub(text, 1, props.MaxLength)
					text = textbox.Text
				end
				if text ~= "" then
					applyLabel(true, false)
				end
				self.value = text
				if props.OnChange then
					task.spawn(props.OnChange, text)
				end
			end)

			applyLabel(self.value ~= "", false)
			self:Set(self.value, true)
		end

		function handle:_commit()
			if self.props.Callback then
				task.spawn(self.props.Callback, self.value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Set(value, skipCallback)
			value = tostring(value or "")
			self.value = value
			if self.textbox then
				self.textbox.Text = value
				local floating = value ~= ""
				local theme = self.window.theme
				self.label.Text = floating and (self.props.Title or self.props.Placeholder or "")
					or (self.props.Placeholder or self.props.Title or "")
				self.label.TextSize = floating and theme.type.labelMedium.size or theme.type.bodyLarge.size
				self.label.Font = floating and theme.fonts.bold or theme.fonts.regular
				self.label.Position = UDim2.new(0, 16 + (self.props.Icon and 30 or 0), 0, floating and 6 or 18)
			end
			if not skipCallback and self.props.Callback then
				task.spawn(self.props.Callback, value)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			self.field.BackgroundColor3 = theme.colors.surfaceContainerHighest
			self.textbox.TextColor3 = theme.colors.onSurface
			self.label.TextColor3 = theme.colors.onSurfaceVariant
			self.indicator.BackgroundColor3 = theme.colors.onSurfaceVariant
			if self.fieldIcon then
				self.fieldIcon.ImageColor3 = theme.colors.onSurfaceVariant
			end
			if self.desc then
				self.desc.TextColor3 = theme.colors.onSurfaceVariant
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Input.new }

end

__mods["elements.Keybind"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Variables = __require("core.Variables")

	local Keybind = {}

	local PILL_WIDTH = 120
	local PILL_HEIGHT = 40

	local function keyName(key)
		if key == nil then
			return "None"
		end
		if type(key) == "string" then
			return key
		end
		if typeof(key) == "EnumItem" then
			return key.Name
		end
		return tostring(key)
	end

	function Keybind.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Keybind",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Value

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = PILL_WIDTH,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local trigger = Creator.new("TextButton", {
				Name = "Trigger",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(PILL_WIDTH, PILL_HEIGHT),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = content,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.trigger = trigger

			Creator.new("UICorner", {
				CornerRadius = theme.shape.field,
				Parent = trigger,
			})
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = trigger,
			}, { Color = "outlineVariant" })

			local state = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.onSurface,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = trigger,
			}, { BackgroundColor3 = "onSurface" })
			self.state = state

			local label = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.medium,
				Text = "None",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyMedium.size,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = trigger,
			}, { TextColor3 = "onSurface" })
			self.label = label

			Element.connect(self, trigger.MouseEnter, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, trigger.MouseLeave, function()
				Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, trigger.MouseButton1Click, function()
				if self.locked then
					return
				end
				self:_beginRecording()
			end)

			self:_updateDisplay()
		end

		function handle:_updateDisplay()
			if not self.label then
				return
			end
			if self.recording then
				self.label.Text = "..."
				self.label.TextColor3 = self.window.theme.colors.primary
			else
				self.label.Text = keyName(self.value)
				self.label.TextColor3 = self.window.theme.colors.onSurface
			end
		end

		function handle:_beginRecording()
			local theme = self.window.theme
			self.recording = true
			self:_updateDisplay()
			Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short)

			self._recorder = Variables.services.UserInputService.InputBegan:Connect(function(input, processed)
				if processed then
					return
				end
				if input.KeyCode == Enum.KeyCode.Escape then
					self:_stopRecording()
					return
				end
				if input.UserInputType == Enum.UserInputType.Keyboard then
					self:Set(input.KeyCode, true)
					self:_stopRecording()
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					self:Set(Enum.UserInputType.MouseButton1, true)
					self:_stopRecording()
				elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
					self:Set(Enum.UserInputType.MouseButton2, true)
					self:_stopRecording()
				end
			end)
		end

		function handle:_stopRecording()
			self.recording = false
			if self._recorder then
				self._recorder:Disconnect()
				self._recorder = nil
			end
			self:_updateDisplay()
			if self.state then
				Motion.tween(self.state, { BackgroundTransparency = 1 }, self.window.theme.motion.short)
			end
		end

		function handle:Set(value, skipCallback)
			self.value = value
			self:_updateDisplay()
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			Row.refreshTheme(self)
			self.trigger.BackgroundColor3 = theme.colors.surfaceContainerHighest
			self.label.TextColor3 = theme.colors.onSurface
		end

		function handle:_destroy()
			if self._recorder then
				self._recorder:Disconnect()
				self._recorder = nil
			end
			Element.destroy(self)
		end

		return handle
	end

	return { new = Keybind.new }

end

__mods["elements.Paragraph"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Paragraph = {}

	local VARIANTS = {
		filled = { fill = "primary", text = "onPrimary" },
		tonal = { fill = "secondaryContainer", text = "onSecondaryContainer" },
		outlined = { fill = "surface", text = "primary", stroke = "outline" },
		text = { fill = "surface", text = "primary" },
	}

	function Paragraph.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Paragraph",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local buttons = props.Buttons or {}

			local main = Creator.new("Frame", {
				Name = "Paragraph",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main

			local layout = Creator.new("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Parent = main,
			})

			if props.Icon then
				local icon = Creator.new("ImageLabel", {
					Size = UDim2.fromOffset(24, 24),
					BackgroundTransparency = 1,
					Image = Icons.image(props.Icon) or "",
					ImageColor3 = theme.colors.onSurfaceVariant,
					ScaleType = Enum.ScaleType.Fit,
					LayoutOrder = 1,
					Parent = main,
				}, { ImageColor3 = "onSurfaceVariant" })
				self.icon = icon
			end

			if props.Title then
				local title = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Font = theme.fonts.medium,
					Text = props.Title,
					TextColor3 = theme.colors.onSurface,
					TextSize = theme.type.titleMedium.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					LayoutOrder = 2,
					Parent = main,
				}, { TextColor3 = "onSurface" })
				self.title = title
			end

			if props.Description then
				local desc = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Font = theme.fonts.regular,
					Text = props.Description,
					TextColor3 = theme.colors.onSurfaceVariant,
					TextSize = theme.type.bodyMedium.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					LayoutOrder = 3,
					Parent = main,
				}, { TextColor3 = "onSurfaceVariant" })
				self.desc = desc
			end

			for index, spec in ipairs(buttons) do
				local variant = VARIANTS[spec.Variant] or VARIANTS.filled
				local transparent = variant.fill == "surface"
				local button = Creator.new("TextButton", {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundColor3 = theme.colors[variant.fill],
					BackgroundTransparency = transparent and 1 or 0,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = spec.Title or "",
					Font = theme.fonts.medium,
					TextColor3 = theme.colors[variant.text],
					TextSize = theme.type.labelLarge.size,
					LayoutOrder = 10 + index,
					Parent = main,
				}, {
					BackgroundColor3 = variant.fill,
					BackgroundTransparency = transparent and 1 or 0,
					TextColor3 = variant.text,
				})

				Creator.new("UICorner", {
					CornerRadius = theme.shape.button,
					Parent = button,
				})

				if variant.stroke then
					Creator.new("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = theme.colors[variant.stroke],
						Transparency = 0,
						Thickness = 1,
						Parent = button,
					}, { Color = variant.stroke })
				end

				local state = Creator.new("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = theme.colors[variant.text],
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = button,
				}, { BackgroundColor3 = variant.text })

				Element.connect(self, button.MouseEnter, function()
					Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
				end)
				Element.connect(self, button.MouseLeave, function()
					Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
				end)
				Element.connect(self, button.MouseButton1Click, function()
					if spec.Callback then
						task.spawn(spec.Callback)
					end
				end)
			end
		end

		function handle:setTitle(text)
			if self.title then
				self.title.Text = text
			end
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			if self.title then
				self.title.TextColor3 = theme.colors.onSurface
			end
			if self.desc then
				self.desc.TextColor3 = theme.colors.onSurfaceVariant
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Paragraph.new }

end

__mods["elements.ProgressBar"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")

	local ProgressBar = {}

	local TRACK_HEIGHT = 8

	function ProgressBar.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "ProgressBar",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Value or 0
		handle.min = props.Min or 0
		handle.max = props.Max or 100

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = 64,
				parent = parentFrame,
				order = order,
				height = 72,
			})

			local content = self.content

			local valueLabel = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(58, 20),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = "",
				TextColor3 = theme.colors.primary,
				TextSize = theme.type.labelLarge.size,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = content,
			}, { TextColor3 = "primary" })
			self.valueLabel = valueLabel

			local track = Creator.new("Frame", {
				Position = UDim2.new(0, 0, 1, -18),
				Size = UDim2.new(1, 0, 0, TRACK_HEIGHT),
				BackgroundColor3 = theme.colors.surfaceVariant,
				BorderSizePixel = 0,
				Parent = self.main,
			}, { BackgroundColor3 = "surfaceVariant" })
			self.track = track

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = track,
			})

			local indicator = Creator.new("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = theme.colors.primary,
				BorderSizePixel = 0,
				Parent = track,
			}, { BackgroundColor3 = "primary" })
			self.indicator = indicator

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = indicator,
			})

			self:_render()
		end

		function handle:_ratio()
			local span = self.max - self.min
			if span <= 0 then
				return 0
			end
			return math.clamp((self.value - self.min) / span, 0, 1)
		end

		function handle:_render(animate)
			if not self.main then
				return
			end
			local ratio = self:_ratio()
			local theme = self.window.theme
			local target = UDim2.new(ratio, 0, 1, 0)
			if animate then
				Motion.tween(self.indicator, { Size = target }, theme.motion.standard)
			else
				self.indicator.Size = target
			end
			self.valueLabel.Text = props.Format and props.Format(self.value, ratio)
				or string.format("%d%%", math.floor(ratio * 100))
		end

		function handle:Set(value, skipCallback)
			self.value = value
			if self.main then
				self:_render(true)
			end
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			Row.refreshTheme(self)
			self.indicator.BackgroundColor3 = theme.colors.primary
			if self.track then
				self.track.BackgroundColor3 = theme.colors.surfaceVariant
			end
			self.valueLabel.TextColor3 = theme.colors.primary
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = ProgressBar.new }

end

__mods["elements.Radio"] = function()
	local Checkbox = __require("elements.Checkbox")

	return {
		new = function(ctx)
			ctx.props = ctx.props or {}
			ctx.props.Variant = "Radio"
			return Checkbox.new(ctx)
		end,
	}

end

__mods["elements.Rating"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Rating = {}

	local STAR = 26
	local GAP = 4

	function Rating.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Rating",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.max = props.Max or 5
		handle.value = props.Value or 0

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			local width = self.max * STAR + (self.max - 1) * GAP

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = width,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local row = Creator.new("Frame", {
				Name = "Stars",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(width, STAR),
				BackgroundTransparency = 1,
				Parent = content,
			})
			self.row = row

			Creator.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Parent = row,
			})

			self.stars = {}
			for index = 1, self.max do
				local star = Creator.new("TextButton", {
					Size = UDim2.fromOffset(STAR, STAR),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					LayoutOrder = index,
					Parent = row,
				})
				local icon = Creator.new("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = Icons.image(props.Icon or "star") or "",
					ImageColor3 = theme.colors.onSurfaceVariant,
					ScaleType = Enum.ScaleType.Fit,
					Parent = star,
				}, { ImageColor3 = "onSurfaceVariant" })
				self.stars[index] = { star = star, icon = icon }

				Element.connect(self, star.MouseEnter, function()
					Motion.tween(icon, { ImageColor3 = theme.colors.primary }, theme.motion.short)
				end)
				Element.connect(self, star.MouseLeave, function()
					self:_render()
				end)
				Element.connect(self, star.MouseButton1Click, function()
					if self.locked or props.ReadOnly then
						return
					end
					self:Set(index, true)
					if props.Callback then
						task.spawn(props.Callback, index)
					end
				end)
			end

			self:_render()
		end

		function handle:_render()
			local theme = self.window.theme
			for index, data in ipairs(self.stars) do
				local filled = index <= self.value
				Motion.tween(data.icon, {
					ImageColor3 = filled and theme.colors.primary or theme.colors.onSurfaceVariant,
				}, theme.motion.short)
			end
		end

		function handle:Set(value, skipCallback)
			self.value = math.clamp(math.floor(value or 0), 0, self.max)
			if self.main then
				self:_render()
			end
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, self.value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			Row.refreshTheme(self)
			self:_render()
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Rating.new }

end

__mods["elements.Slider"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Variables = __require("core.Variables")

	local Slider = {}

	local TRACK_HEIGHT = 4
	local HANDLE = 20

	function Slider.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Slider",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.min = props.Min or 0
		handle.max = props.Max or 100
		handle.step = props.Step or 1
		handle.value = props.Value or props.Default or handle.min

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = 70,
				parent = parentFrame,
				order = order,
				height = 76,
			})

			local content = self.content

			local valueLabel = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(64, 22),
				BackgroundTransparency = 1,
				Font = theme.fonts.medium,
				Text = "",
				TextColor3 = theme.colors.primary,
				TextSize = theme.type.labelLarge.size,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = content,
			}, { TextColor3 = "primary" })
			self.valueLabel = valueLabel

			local trackArea = Creator.new("Frame", {
				Name = "TrackArea",
				Position = UDim2.new(0, 0, 1, -20),
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Parent = self.main,
			})
			self.trackArea = trackArea

			local track = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, TRACK_HEIGHT),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				Parent = trackArea,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.track = track

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = track,
			})

			local fill = Creator.new("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = theme.colors.primary,
				BorderSizePixel = 0,
				Parent = track,
			}, { BackgroundColor3 = "primary" })
			self.fill = fill

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = fill,
			})

			local knob = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(HANDLE, HANDLE),
				BackgroundColor3 = theme.colors.primary,
				BorderSizePixel = 0,
				Parent = trackArea,
			}, { BackgroundColor3 = "primary" })
			self.knob = knob

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = knob,
			})

			local knobRing = Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.primary,
				Transparency = 1,
				Thickness = 8,
				Parent = knob,
			}, { Color = "primary" })
			self.knobRing = knobRing

			local dragging = false

			local function applyMouse(input)
				local position = trackArea.AbsolutePosition.X
				local width = trackArea.AbsoluteSize.X
				if width <= 0 then
					return
				end
				local ratio = (input.Position.X - position) / width
				ratio = math.clamp(ratio, 0, 1)
				local raw = self.min + ratio * (self.max - self.min)
				local stepped = self.min + math.floor((raw - self.min) / self.step + 0.5) * self.step
				stepped = math.clamp(stepped, self.min, self.max)
				self:Set(stepped, false, true)
			end

			Element.connect(self, trackArea.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					Motion.tween(knobRing, { Transparency = 0.55 }, theme.motion.short)
					Motion.tween(knob, { Size = UDim2.fromOffset(26, 26) }, theme.motion.short)
					applyMouse(input)
				end
			end)

			Element.connect(self, trackArea.InputEnded, function()
				if not dragging then
					return
				end
				dragging = false
				Motion.tween(knobRing, { Transparency = 1 }, theme.motion.short)
				Motion.tween(knob, { Size = UDim2.fromOffset(HANDLE, HANDLE) }, theme.motion.short)
				if props.Callback then
					task.spawn(props.Callback, self.value, false)
				end
			end)

			self._inputConnection = Element.connect(self, Variables.services.UserInputService.InputChanged, function(input)
				if not dragging then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					applyMouse(input)
				end
			end)

			self:_render()
		end

		function handle:_format(value)
			local step = self.step
			if step >= 1 then
				return string.format("%d%s", math.floor(value + 0.5), self.props.Suffix or "")
			end
			return string.format("%.2f%s", value, self.props.Suffix or "")
		end

		function handle:_render()
			if not self.main then
				return
			end
			local ratio = (self.value - self.min) / (self.max - self.min)
			ratio = math.clamp(ratio, 0, 1)
			self.fill.Size = UDim2.new(ratio, 0, 1, 0)
			self.knob.Position = UDim2.new(ratio, 0, 0.5, 0)
			self.valueLabel.Text = self:_format(self.value)
		end

		function handle:Set(value, skipCallback, dragging)
			value = math.clamp(tonumber(value) or self.min, self.min, self.max)
			local changed = value ~= self.value
			self.value = value
			if self.main then
				self:_render()
			end
			if changed and not skipCallback and props.Callback then
				task.spawn(props.Callback, value, dragging == true)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			Row.refreshTheme(self)
			self.fill.BackgroundColor3 = theme.colors.primary
			self.knob.BackgroundColor3 = theme.colors.primary
			self.knobRing.Color = theme.colors.primary
			self.valueLabel.TextColor3 = theme.colors.primary
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Slider.new }

end

__mods["elements.Space"] = function()
	local Element = __require("core.Element")
	local Creator = __require("core.Creator")

	local Space = {}

	function Space.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Space",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})

		function handle:_build(parentFrame, order)
			local window = self.window
			Creator.window = window

			local amount = props.Size or props.Height or 12
			local main = Creator.new("Frame", {
				Name = "Space",
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, amount),
				BackgroundTransparency = 1,
				Parent = parentFrame,
			})
			self.main = main
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Space.new }

end

__mods["elements.Stat"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Stat = {}

	function Stat.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Stat",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Value or 0

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = 110,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local value = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(110, 28),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = "",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.headlineSmall.size,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = content,
			}, { TextColor3 = "onSurface" })
			self.valueLabel = value

			if props.Change ~= nil then
				local positive = props.Change >= 0
				local changeIcon = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -86, 0.5, 14),
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Image = Icons.image(positive and "trending-up" or "trending-down") or "",
					ImageColor3 = positive and theme.colors.primary or theme.colors.error,
					ScaleType = Enum.ScaleType.Fit,
					Parent = content,
				}, { ImageColor3 = positive and "primary" or "error" })
				self.changeIcon = changeIcon

				local changeLabel = Creator.new("TextLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -20, 0.5, 14),
					Size = UDim2.fromOffset(62, 18),
					BackgroundTransparency = 1,
					Font = theme.fonts.bold,
					Text = "",
					TextColor3 = positive and theme.colors.primary or theme.colors.error,
					TextSize = theme.type.labelMedium.size,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = content,
				}, { TextColor3 = positive and "primary" or "error" })
				self.changeLabel = changeLabel
			end

			self:_render()
		end

		function handle:_render()
			if not self.valueLabel then
				return
			end
			local props = self.props
			local value = self.value
			local text
			if type(value) == "number" then
				text = string.format("%d", value)
				if props.Precision and props.Precision > 0 then
					text = string.format("%." .. props.Precision .. "f", value)
				end
			else
				text = tostring(value)
			end
			self.valueLabel.Text = (props.Prefix or "") .. text .. (props.Suffix or "")

			if self.changeLabel then
				local change = self.props.Change or 0
				local sign = change >= 0 and "+" or "-"
				self.changeLabel.Text = sign .. tostring(math.abs(change)) .. (self.props.ChangeSuffix or "")
			end
		end

		function handle:Set(value, skipCallback)
			self.value = value
			if self.main then
				self:_render()
			end
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, value)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			local theme = self.window.theme
			Row.refreshTheme(self)
			self.valueLabel.TextColor3 = theme.colors.onSurface
			if self.changeLabel then
				local positive = (self.props.Change or 0) >= 0
				self.changeLabel.TextColor3 = positive and theme.colors.primary or theme.colors.error
				self.changeIcon.ImageColor3 = positive and theme.colors.primary or theme.colors.error
			end
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Stat.new }

end

__mods["elements.TextArea"] = function()
	local Input = __require("elements.Input")

	return {
		new = function(ctx)
			ctx.typeName = "TextArea"
			return Input.new(ctx)
		end,
	}

end

__mods["elements.Toggle"] = function()
	local Element = __require("core.Element")
	local Row = __require("core.Row")
	local Creator = __require("core.Creator")
	local Motion = __require("core.Motion")
	local Icons = __require("icons.Init")

	local Toggle = {}

	local TRACK_WIDTH = 52
	local TRACK_HEIGHT = 32

	function Toggle.new(ctx)
		local props = ctx.props or {}
		local handle = Element.new({
			typeName = "Toggle",
			window = ctx.window,
			container = ctx.container,
			props = props,
		})
		handle.value = props.Value == true

		function handle:_build(parentFrame, order)
			local window = self.window
			local theme = window.theme
			Creator.window = window

			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = TRACK_WIDTH,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local track = Creator.new("TextButton", {
				Name = "Switch",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = content,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.track = track

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = track,
			})

			local state = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors.onSurface,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = track,
			}, { BackgroundColor3 = "onSurface" })
			self.state = state

			local stroke = Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outline,
				Transparency = 0,
				Thickness = 2,
				Parent = track,
			}, { Color = "outline" })
			self.stroke = stroke

			local knob = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = theme.colors.outline,
				BorderSizePixel = 0,
				Parent = track,
			}, { BackgroundColor3 = "outline" })
			self.knob = knob

			Creator.new("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = knob,
			})

			local knobIcon = nil
			if props.Icon then
				knobIcon = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Image = Icons.image(props.Icon) or "",
					ImageColor3 = theme.colors.surfaceContainerHighest,
					ScaleType = Enum.ScaleType.Fit,
					Parent = knob,
				}, { ImageColor3 = "surfaceContainerHighest" })
				self.knobIcon = knobIcon
			end

			Element.connect(self, track.MouseEnter, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, track.MouseLeave, function()
				Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, track.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Motion.tween(state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)
				end
			end)
			Element.connect(self, track.InputEnded, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
			end)
			Element.connect(self, track.MouseButton1Click, function()
				if self.locked then
					return
				end
				self:Set(not self.value, true)
			end)

			self:_render()
		end

		function handle:_render(animate)
			local theme = self.window.theme
			local on = self.value == true
			local token = animate and theme.motion.standard or theme.motion.short

			Motion.tween(self.track, {
				BackgroundColor3 = on and theme.colors.primary or theme.colors.surfaceContainerHighest,
			}, token)
			Motion.tween(self.stroke, {
				Color = on and theme.colors.primary or theme.colors.outline,
				Transparency = on and 1 or 0,
			}, token)
			Motion.tween(self.knob, {
				Position = UDim2.new(0, on and 4 or 8, 0.5, 0),
				Size = UDim2.fromOffset(on and 24 or 16, on and 24 or 16),
				BackgroundColor3 = on and theme.colors.onPrimary or theme.colors.outline,
			}, token)
			if self.knobIcon then
				Motion.tween(self.knobIcon, {
					ImageColor3 = on and theme.colors.primary or theme.colors.surfaceContainerHighest,
				}, token)
			end
		end

		function handle:Set(value, skipCallback)
			value = value == true
			if self.value == value and self.main then
				return
			end
			self.value = value
			if self.main then
				self:_render(true)
			end
			if not skipCallback and props.Callback then
				task.spawn(props.Callback, value)
			end
			if self.window and self.flag then
				self.window:_persist(self)
			end
		end

		function handle:Get()
			return self.value
		end

		function handle:_refreshTheme()
			if not self.main then
				return
			end
			Row.refreshTheme(self)
			self:_render(false)
		end

		function handle:_destroy()
			Element.destroy(self)
		end

		return handle
	end

	return { new = Toggle.new }

end

__mods["icons.Init"] = function()
	local Lucide = __require("icons.Lucide")

	local Icons = {}

	Icons.packs = {
		lucide = Lucide,
	}

	Icons.defaultPack = "lucide"

	local function splitName(name)
		local separator = name:find(":", 1, true)
		if separator then
			return name:sub(1, separator - 1), name:sub(separator + 1)
		end
		return nil, name
	end

	function Icons.register(packName, data)
		Icons.packs[packName] = data
	end

	function Icons.setDefaultPack(packName)
		Icons.defaultPack = packName
	end

	function Icons.exists(name)
		if type(name) ~= "string" then
			return false
		end
		if name:sub(1, 10) == "rbxassetid:" or name:sub(1, 7) == "rbxasset:" then
			return true
		end
		if name:sub(1, 4) == "http" then
			return true
		end
		local pack, key = splitName(name)
		pack = pack or Icons.defaultPack
		local data = Icons.packs[pack]
		return data ~= nil and data[key] ~= nil
	end

	function Icons.image(name)
		if type(name) == "number" then
			return "rbxassetid://" .. tostring(name)
		end
		if type(name) ~= "string" then
			return nil
		end
		if name:sub(1, 10) == "rbxassetid:" or name:sub(1, 7) == "rbxasset:" or name:sub(1, 4) == "http" then
			return name
		end
		local pack, key = splitName(name)
		pack = pack or Icons.defaultPack
		local data = Icons.packs[pack]
		if not data then
			return nil
		end
		return data[key]
	end

	function Icons.names()
		local names = {}
		for key in pairs(Lucide) do
			table.insert(names, key)
		end
		table.sort(names)
		return names
	end

	function Icons.label(parent, name, size, color)
		local image = Icons.image(name)
		local label = Instance.new("ImageLabel")
		label.Name = "Icon"
		label.BackgroundTransparency = 1
		label.Size = typeof(size) == "number" and UDim2.fromOffset(size, size) or (size or UDim2.fromOffset(20, 20))
		label.Image = image or ""
		label.ImageColor3 = color or Color3.fromRGB(255, 255, 255)
		label.ScaleType = Enum.ScaleType.Fit
		label.Parent = parent
		return label
	end

	return Icons

end

__mods["icons.Lucide"] = function()
	return {
		["activity"] = "rbxassetid://94212016861936",
		["antenna"] = "rbxassetid://99628923540956",
		["arrow-down"] = "rbxassetid://98764963621439",
		["arrow-down-right"] = "rbxassetid://123109928624974",
		["arrow-left"] = "rbxassetid://102531941843733",
		["arrow-right"] = "rbxassetid://113692007244654",
		["arrow-up"] = "rbxassetid://89282378235317",
		["arrow-up-right"] = "rbxassetid://129280608535523",
		["at-sign"] = "rbxassetid://79059152889146",
		["award"] = "rbxassetid://132740088158419",
		["badge-alert"] = "rbxassetid://101829200081951",
		["badge-check"] = "rbxassetid://76078495178149",
		["badge-info"] = "rbxassetid://131995373201472",
		["battery"] = "rbxassetid://70765800346189",
		["bell"] = "rbxassetid://97392696311902",
		["bell-off"] = "rbxassetid://78560046118930",
		["bell-plus"] = "rbxassetid://77014333795836",
		["bold"] = "rbxassetid://116141470019166",
		["bolt"] = "rbxassetid://102881251417484",
		["book"] = "rbxassetid://125383279695672",
		["bookmark"] = "rbxassetid://121093149326239",
		["book-open"] = "rbxassetid://129845326810392",
		["box"] = "rbxassetid://101768155599700",
		["calendar"] = "rbxassetid://114792700814035",
		["calendar-check"] = "rbxassetid://71551019465748",
		["calendar-clock"] = "rbxassetid://119132152594595",
		["calendar-days"] = "rbxassetid://99072017568595",
		["camera"] = "rbxassetid://79950339943067",
		["chart-pie"] = "rbxassetid://113412261630136",
		["check"] = "rbxassetid://93898873302694",
		["check-check"] = "rbxassetid://95183312173858",
		["chevron-down"] = "rbxassetid://134243273101015",
		["chevron-left"] = "rbxassetid://73780377692148",
		["chevron-right"] = "rbxassetid://92473583511724",
		["chevrons-down"] = "rbxassetid://100524612205956",
		["chevrons-up"] = "rbxassetid://100467452364672",
		["chevrons-up-down"] = "rbxassetid://131833120209646",
		["chevron-up"] = "rbxassetid://122444883127455",
		["circle"] = "rbxassetid://130359823580534",
		["circle-alert"] = "rbxassetid://83898160590116",
		["circle-check"] = "rbxassetid://85262178816537",
		["circle-dot"] = "rbxassetid://82947033619201",
		["circle-minus"] = "rbxassetid://133556159576809",
		["circle-plus"] = "rbxassetid://113157136350384",
		["circle-slash"] = "rbxassetid://125206439913049",
		["circle-x"] = "rbxassetid://76821953846248",
		["clipboard"] = "rbxassetid://89601995828423",
		["clipboard-check"] = "rbxassetid://92649798577170",
		["clipboard-list"] = "rbxassetid://96460215958908",
		["clock"] = "rbxassetid://121808839832144",
		["cloud"] = "rbxassetid://121226497050352",
		["cloud-download"] = "rbxassetid://121435581993566",
		["cloud-upload"] = "rbxassetid://93307473217005",
		["code"] = "rbxassetid://107380207681249",
		["columns-2"] = "rbxassetid://113004100221850",
		["columns-3"] = "rbxassetid://115223357399375",
		["compass"] = "rbxassetid://115123411028382",
		["copy"] = "rbxassetid://78979572434545",
		["corner-down-right"] = "rbxassetid://86512767702085",
		["cpu"] = "rbxassetid://77549309870247",
		["credit-card"] = "rbxassetid://99163352872346",
		["crop"] = "rbxassetid://116344601101413",
		["crosshair"] = "rbxassetid://134242818164054",
		["crown"] = "rbxassetid://127843403295538",
		["database"] = "rbxassetid://126791525623846",
		["dollar-sign"] = "rbxassetid://127320961224019",
		["dot"] = "rbxassetid://137321056643916",
		["download"] = "rbxassetid://134814648082393",
		["droplet"] = "rbxassetid://100597455015098",
		["ellipsis"] = "rbxassetid://140019550645825",
		["eraser"] = "rbxassetid://133957773112410",
		["external-link"] = "rbxassetid://129331830773832",
		["eye"] = "rbxassetid://100033680381365",
		["eye-off"] = "rbxassetid://135928786788378",
		["file"] = "rbxassetid://74748492079329",
		["file-code"] = "rbxassetid://130978036895504",
		["file-image"] = "rbxassetid://123334057511782",
		["file-lock"] = "rbxassetid://72170228691242",
		["file-text"] = "rbxassetid://90496405707281",
		["flag"] = "rbxassetid://78183383236196",
		["flame"] = "rbxassetid://98218034436456",
		["folder"] = "rbxassetid://80846616596607",
		["folder-open"] = "rbxassetid://76018996254888",
		["frown"] = "rbxassetid://124407301067982",
		["gauge"] = "rbxassetid://110273524101447",
		["gift"] = "rbxassetid://109855212076373",
		["globe"] = "rbxassetid://114238209622913",
		["grid-3x3"] = "rbxassetid://70419024781206",
		["grip-horizontal"] = "rbxassetid://136255899715930",
		["grip-vertical"] = "rbxassetid://137183678565296",
		["hard-drive"] = "rbxassetid://88183305858463",
		["hash"] = "rbxassetid://82890331678520",
		["heart"] = "rbxassetid://116559368303288",
		["highlighter"] = "rbxassetid://77411555641113",
		["house"] = "rbxassetid://98755624629571",
		["image"] = "rbxassetid://112751259236831",
		["info"] = "rbxassetid://124560466474914",
		["italic"] = "rbxassetid://96220378864282",
		["key"] = "rbxassetid://96510194465420",
		["languages"] = "rbxassetid://90816903776498",
		["layers"] = "rbxassetid://81973586053257",
		["layout-dashboard"] = "rbxassetid://139929981863901",
		["layout-grid"] = "rbxassetid://81344910161871",
		["layout-list"] = "rbxassetid://87462136296578",
		["link"] = "rbxassetid://131607023382430",
		["list"] = "rbxassetid://113179976918783",
		["list-ordered"] = "rbxassetid://83212528113913",
		["list-todo"] = "rbxassetid://132980603752108",
		["lock"] = "rbxassetid://134724289526879",
		["lock-open"] = "rbxassetid://93597915325122",
		["log-in"] = "rbxassetid://103768533135201",
		["log-out"] = "rbxassetid://84895399304975",
		["mail"] = "rbxassetid://103945161245599",
		["map-pin"] = "rbxassetid://84279202219901",
		["maximize"] = "rbxassetid://76045941763188",
		["meh"] = "rbxassetid://132197867028557",
		["menu"] = "rbxassetid://77021539815611",
		["message-circle"] = "rbxassetid://127255077587058",
		["message-square"] = "rbxassetid://83881670383280",
		["message-square-plus"] = "rbxassetid://76934450256199",
		["mic"] = "rbxassetid://89640799126523",
		["minimize"] = "rbxassetid://121304296213645",
		["minus"] = "rbxassetid://118026365011536",
		["monitor"] = "rbxassetid://72664649203050",
		["moon"] = "rbxassetid://83380517901735",
		["moon-star"] = "rbxassetid://82782200506348",
		["navigation"] = "rbxassetid://79308213542922",
		["notebook"] = "rbxassetid://136132108664987",
		["notebook-pen"] = "rbxassetid://140380614761023",
		["orbit"] = "rbxassetid://108926136860562",
		["package"] = "rbxassetid://97261141732706",
		["paintbrush"] = "rbxassetid://125572663700289",
		["palette"] = "rbxassetid://86350350950064",
		["panel-bottom"] = "rbxassetid://132127145048511",
		["panel-bottom-open"] = "rbxassetid://107768659586540",
		["panel-left"] = "rbxassetid://97419752870313",
		["panel-right"] = "rbxassetid://116365035443156",
		["panel-right-open"] = "rbxassetid://118114419142794",
		["panel-top"] = "rbxassetid://75838479462875",
		["pause"] = "rbxassetid://74873705394436",
		["pencil"] = "rbxassetid://137986121120732",
		["percent"] = "rbxassetid://130155041032013",
		["phone"] = "rbxassetid://128804946640049",
		["play"] = "rbxassetid://135609604299893",
		["plus"] = "rbxassetid://111774323017047",
		["power"] = "rbxassetid://96479131758775",
		["printer"] = "rbxassetid://76080649734247",
		["radar"] = "rbxassetid://138528222906635",
		["redo"] = "rbxassetid://116150342119054",
		["refresh-cw"] = "rbxassetid://138133190015277",
		["repeat"] = "rbxassetid://121886242955173",
		["rocket"] = "rbxassetid://87412317685854",
		["rotate-ccw"] = "rbxassetid://110116685948665",
		["rows-2"] = "rbxassetid://112556185960101",
		["rows-3"] = "rbxassetid://117215586961375",
		["satellite"] = "rbxassetid://134967053164645",
		["save"] = "rbxassetid://126116963775616",
		["scan"] = "rbxassetid://123104789658180",
		["scan-line"] = "rbxassetid://126544908146540",
		["search"] = "rbxassetid://121018724060431",
		["send"] = "rbxassetid://127751956873796",
		["server"] = "rbxassetid://92188766517878",
		["settings"] = "rbxassetid://80758916183665",
		["settings-2"] = "rbxassetid://135684703553372",
		["share-2"] = "rbxassetid://71210767962065",
		["shield"] = "rbxassetid://110987169760162",
		["shield-alert"] = "rbxassetid://114995877719925",
		["shield-check"] = "rbxassetid://87354736164608",
		["shuffle"] = "rbxassetid://132382786975101",
		["signal"] = "rbxassetid://78424889355261",
		["slash"] = "rbxassetid://117792185664263",
		["sliders-horizontal"] = "rbxassetid://85538382643347",
		["sliders-vertical"] = "rbxassetid://101190569086853",
		["smartphone"] = "rbxassetid://96623008834511",
		["smile"] = "rbxassetid://105880397565283",
		["sparkles"] = "rbxassetid://138635884129147",
		["square"] = "rbxassetid://86304921356806",
		["square-check-big"] = "rbxassetid://115320390907184",
		["square-pen"] = "rbxassetid://120239476110475",
		["star"] = "rbxassetid://136141469398409",
		["strikethrough"] = "rbxassetid://103417324549613",
		["sun"] = "rbxassetid://110150589884127",
		["sunrise"] = "rbxassetid://134705665494098",
		["sunset"] = "rbxassetid://75904872203588",
		["table"] = "rbxassetid://109109148250737",
		["tablet"] = "rbxassetid://128403991264386",
		["target"] = "rbxassetid://87563802520297",
		["terminal"] = "rbxassetid://106783148545356",
		["thumbs-up"] = "rbxassetid://111137070767020",
		["timer"] = "rbxassetid://85473888890506",
		["trash-2"] = "rbxassetid://109843431391323",
		["trending-down"] = "rbxassetid://139309232226438",
		["trending-up"] = "rbxassetid://81819858538839",
		["triangle-alert"] = "rbxassetid://125920361880643",
		["type"] = "rbxassetid://133543553793564",
		["underline"] = "rbxassetid://123709229216544",
		["undo"] = "rbxassetid://111258459077271",
		["upload"] = "rbxassetid://138212042425501",
		["user"] = "rbxassetid://81589895647169",
		["user-check"] = "rbxassetid://81775205032725",
		["user-minus"] = "rbxassetid://126976941957511",
		["user-plus"] = "rbxassetid://118514469915884",
		["users"] = "rbxassetid://115398113982385",
		["video"] = "rbxassetid://107587444636945",
		["volume-2"] = "rbxassetid://89344380902620",
		["volume-x"] = "rbxassetid://139252359189540",
		["wand"] = "rbxassetid://114580617777835",
		["wand-sparkles"] = "rbxassetid://82546429942392",
		["waves"] = "rbxassetid://96340135183647",
		["waypoints"] = "rbxassetid://102450133666017",
		["wifi"] = "rbxassetid://104669375183960",
		["wifi-off"] = "rbxassetid://74113634330106",
		["x"] = "rbxassetid://110786993356448",
		["zap"] = "rbxassetid://130551565616516",
	}

end

__mods["init"] = function()
	local Window = __require("core.Window")
	local Theme = __require("theme.Init")
	local Schemes = __require("theme.Schemes")
	local Palette = __require("theme.Palette")
	local Tokens = __require("theme.Tokens")
	local Icons = __require("icons.Init")
	local Variables = __require("core.Variables")

	local Sonar = {}

	Sonar.version = "1.0.0"
	Sonar.name = "Sonar UI"

	Sonar.Theme = Theme
	Sonar.Tokens = Tokens
	Sonar.Schemes = Schemes
	Sonar.Palette = Palette
	Sonar.Icons = Icons

	local activeWindows = {}

	function Sonar.createWindow(props)
		local window = Window.new(props or {})
		table.insert(activeWindows, window)
		return window
	end

	function Sonar.buildTheme(spec)
		return Theme.build(spec or {})
	end

	function Sonar.palette(seed, mode)
		return Theme.palette(seed, mode)
	end

	function Sonar.schemes()
		return Schemes.list()
	end

	function Sonar.materials()
		return Palette
	end

	function Sonar.setIconsPack(pack)
		Icons.setDefaultPack(pack)
	end

	function Sonar.icons()
		return Icons.names()
	end

	function Sonar.windows()
		local list = {}
		for _, window in ipairs(activeWindows) do
			if not window.unloaded then
				table.insert(list, window)
			end
		end
		return list
	end

	function Sonar.destroyAll()
		for _, window in ipairs(activeWindows) do
			if not window.unloaded then
				window:unload()
			end
		end
		activeWindows = {}
	end

	Sonar.Variables = Variables

	return Sonar

end

__mods["locale.Init"] = function()
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

end

__mods["theme.Init"] = function()
	local Tokens = __require("theme.Tokens")
	local Schemes = __require("theme.Schemes")
	local Palette = __require("theme.Palette")

	local Theme = {}

	local SHAPE_ROLES = {
		window = "extraLarge",
		sheet = "largeIncreased",
		dialog = "extraLarge",
		card = "large",
		element = "medium",
		menu = "small",
		field = "small",
		chip = "small",
		button = "full",
		toggle = "full",
		badge = "full",
		nav = "full",
		progress = "full",
		tab = "full",
		snackbar = "extraSmall",
	}

	local function copy(source)
		local result = {}
		for key, value in pairs(source) do
			if type(value) == "table" and getmetatable(value) == nil then
				result[key] = copy(value)
			else
				result[key] = value
			end
		end
		return result
	end

	local function resolveColor(value)
		if type(value) == "string" then
			return Palette.seedFromHex(value)
		end
		return value
	end

	function Theme.build(spec)
		spec = spec or {}

		local scheme = Schemes.resolve(spec.name or "Material", spec.mode or "dark", spec.seed)
		local colors = copy(scheme.colors)

		if spec.colors then
			for role, value in pairs(spec.colors) do
				local resolved = resolveColor(value)
				if resolved ~= nil then
					colors[role] = resolved
				end
			end
		end

		local shape = {}
		for role, token in pairs(SHAPE_ROLES) do
			shape[role] = Tokens.shapeRadius(token)
		end
		if spec.shape then
			for role, value in pairs(spec.shape) do
				if type(value) == "number" then
					shape[role] = UDim.new(0, math.round(value * (Tokens.Density.radiusScale or 1)))
				elseif type(value) == "UDim" then
					shape[role] = value
				end
			end
		end

		local fonts = {}
		for key, value in pairs(Tokens.Fonts) do
			fonts[key] = value
		end
		if spec.fonts then
			for key, value in pairs(spec.fonts) do
				fonts[key] = value
			end
		end

		local typeScale = {}
		for key, value in pairs(Tokens.Type) do
			typeScale[key] = {
				size = value.size,
				lineHeight = value.lineHeight,
				tracking = value.tracking,
				weight = value.weight,
				font = fonts[value.weight] or fonts.regular,
			}
		end
		if spec.type then
			for key, value in pairs(spec.type) do
				local current = typeScale[key] or {
					size = 14,
					lineHeight = 20,
					tracking = 0,
					weight = "regular",
				}
				if type(value) == "number" then
					current.size = value
				elseif type(value) == "table" then
					current.size = value.size or current.size
					current.lineHeight = value.lineHeight or current.lineHeight
					current.tracking = value.tracking or current.tracking
					current.weight = value.weight or current.weight
				end
				current.font = fonts[current.weight] or fonts.regular
				typeScale[key] = current
			end
		end

		local motion = {}
		for key, value in pairs(Tokens.Motion) do
			motion[key] = {
				time = value.time,
				style = value.style,
				direction = value.direction,
			}
		end
		if spec.motion then
			for key, value in pairs(spec.motion) do
				if type(value) == "number" then
					motion[key] = { time = value, style = motion.standard.style, direction = motion.standard.direction }
				elseif type(value) == "table" then
					motion[key] = {
						time = value.time or motion.standard.time,
						style = value.style or motion.standard.style,
						direction = value.direction or motion.standard.direction,
					}
				end
			end
		end

		local state = {
			hover = colors.stateHover or 0.08,
			focus = colors.stateFocus or 0.1,
			pressed = colors.statePressed or 0.1,
			dragged = colors.stateDragged or 0.16,
			disabled = colors.stateDisabled or 0.38,
			disabledContent = colors.stateDisabledContent or 0.38,
		}
		if spec.state then
			for key, value in pairs(spec.state) do
				if type(value) == "number" then
					state[key] = value
				end
			end
		end

		local elevation = {}
		for level, entry in pairs(Tokens.Elevation) do
			elevation[level] = {
				color = colors[entry.surface] or colors.surface,
				shadowTransparency = entry.shadow,
			}
		end
		if spec.elevation then
			for level, value in pairs(spec.elevation) do
				if type(value) == "number" then
					elevation[level] = {
						color = colors.surface,
						shadowTransparency = value,
					}
				elseif type(value) == "table" then
					local current = elevation[level] or { color = colors.surface, shadowTransparency = 0 }
					current.shadowTransparency = value.shadow or current.shadowTransparency
					current.color = resolveColor(value.surface) or current.color
					elevation[level] = current
				end
			end
		end

		return {
			name = scheme.name,
			mode = scheme.mode,
			seed = scheme.seed,
			colors = colors,
			shape = shape,
			motion = motion,
			type = typeScale,
			fonts = fonts,
			spacing = Tokens.Spacing,
			elevation = elevation,
			state = state,
		}
	end

	function Theme.schemes()
		return Schemes.list()
	end

	function Theme.palette(seed, mode)
		if type(seed) == "string" then
			seed = Palette.seedFromHex(seed)
		end
		return Palette.scheme(seed or Color3.fromRGB(103, 80, 164), mode == "light")
	end

	function Theme.contrast(color)
		local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
		if luminance > 0.55 then
			return Color3.fromRGB(20, 20, 20)
		end
		return Color3.fromRGB(255, 255, 255)
	end

	function Theme.withAlpha(color, alpha)
		return Color3.new(color.R, color.G, color.B), alpha
	end

	Theme.copy = copy

	return Theme

end

__mods["theme.Palette"] = function()
	local Palette = {}

	local function clamp(value, min, max)
		if value < min then
			return min
		elseif value > max then
			return max
		end
		return value
	end

	local function srgbToLinear(channel)
		if channel <= 0.04045 then
			return channel / 12.92
		end
		return ((channel + 0.055) / 1.055) ^ 2.4
	end

	local function linearToSrgb(channel)
		if channel <= 0.0031308 then
			return channel * 12.92
		end
		return 1.055 * (channel ^ (1 / 2.4)) - 0.055
	end

	local function cbrt(value)
		if value < 0 then
			return -((-value) ^ (1 / 3))
		end
		return value ^ (1 / 3)
	end

	function Palette.rgbToOklab(color)
		local red = srgbToLinear(color.R)
		local green = srgbToLinear(color.G)
		local blue = srgbToLinear(color.B)

		local long = 0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue
		local medium = 0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue
		local short = 0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue

		local longRoot = cbrt(long)
		local mediumRoot = cbrt(medium)
		local shortRoot = cbrt(short)

		local lightness = 0.2104542553 * longRoot + 0.793617785 * mediumRoot - 0.0040720468 * shortRoot
		local a = 1.9779984951 * longRoot - 2.428592205 * mediumRoot + 0.4505937099 * shortRoot
		local b = 0.0259040371 * longRoot + 0.7827717662 * mediumRoot - 0.808675766 * shortRoot

		return lightness, a, b
	end

	function Palette.oklabToLinear(lightness, a, b)
		local longRoot = lightness + 0.3963377774 * a + 0.2158037573 * b
		local mediumRoot = lightness - 0.1055613458 * a - 0.0638541728 * b
		local shortRoot = lightness - 0.0894841775 * a - 1.291485548 * b

		local long = longRoot * longRoot * longRoot
		local medium = mediumRoot * mediumRoot * mediumRoot
		local short = shortRoot * shortRoot * shortRoot

		local red = 4.0767416621 * long - 3.3077115913 * medium + 0.2309699292 * short
		local green = -1.2684380046 * long + 2.6097574011 * medium - 0.3413193965 * short
		local blue = -0.0041960863 * long - 0.7034186147 * medium + 1.707614701 * short

		return red, green, blue
	end

	local function inGamut(red, green, blue)
		return red >= -0.0001 and red <= 1.0001 and green >= -0.0001 and green <= 1.0001 and blue >= -0.0001 and blue <= 1.0001
	end

	function Palette.oklabToColor(lightness, a, b)
		local low = 0
		local high = 1
		local red, green, blue

		for _ = 1, 16 do
			local mid = (low + high) / 2
			red, green, blue = Palette.oklabToLinear(lightness, a * mid, b * mid)
			if inGamut(red, green, blue) then
				low = mid
			else
				high = mid
			end
		end

		red, green, blue = Palette.oklabToLinear(lightness, a * low, b * low)

		return Color3.new(clamp(linearToSrgb(red), 0, 1), clamp(linearToSrgb(green), 0, 1), clamp(linearToSrgb(blue), 0, 1))
	end

	local BOOST = {
		primary = 1,
		secondary = 0.42,
		tertiary = 0.58,
		neutral = 0.08,
		neutralVariant = 0.14,
		error = 1,
	}

	local PALETTE_CACHE = {}

	local function buildPalettes(seed)
		local lightness, a, b = Palette.rgbToOklab(seed)
		local chroma = math.sqrt(a * a + b * b)

		local palettes = {}
		for name, boost in BOOST do
			palettes[name] = { a = a * boost, b = b * boost, chroma = chroma * boost }
		end
		palettes.primary.lightness = lightness
		return palettes
	end

	function Palette.palettes(seed)
		local key = string.format("%.4f|%.4f|%.4f", seed.R, seed.G, seed.B)
		local cached = PALETTE_CACHE[key]
		if cached then
			return cached
		end
		local built = buildPalettes(seed)
		PALETTE_CACHE[key] = built
		return built
	end

	function Palette.toneColor(palettes, family, tone)
		tone = clamp(math.round(tone), 0, 100)
		local palette = palettes[family]
		if not palette then
			return Color3.new(0, 0, 0)
		end
		local cache = palette.cache
		if not cache then
			cache = {}
			palette.cache = cache
		end
		local key = family .. ":" .. tone
		local cached = cache[key]
		if cached then
			return cached
		end
		local color = Palette.oklabToColor(tone / 100, palette.a, palette.b)
		cache[key] = color
		return color
	end

	function Palette.errorPalettes()
		local cached = PALETTE_CACHE["__error"]
		if cached then
			return cached
		end
		local built = buildPalettes(Color3.fromRGB(179, 38, 30))
		built.primary = built.error
		PALETTE_CACHE["__error"] = built
		return built
	end

	function Palette.scheme(seed, dark)
		local palettes = Palette.palettes(seed)
		local errors = Palette.errorPalettes()
		local function tone(family, value)
			return Palette.toneColor(palettes, family, value)
		end
		local function errorTone(value)
			return Palette.toneColor(errors, "error", value)
		end

		local scheme

		if dark then
			scheme = {
				mode = "dark",
				primary = tone("primary", 80),
				onPrimary = tone("primary", 20),
				primaryContainer = tone("primary", 30),
				onPrimaryContainer = tone("primary", 90),
				secondary = tone("secondary", 80),
				onSecondary = tone("secondary", 20),
				secondaryContainer = tone("secondary", 30),
				onSecondaryContainer = tone("secondary", 90),
				tertiary = tone("tertiary", 80),
				onTertiary = tone("tertiary", 20),
				tertiaryContainer = tone("tertiary", 30),
				onTertiaryContainer = tone("tertiary", 90),
				error = errorTone(80),
				onError = errorTone(20),
				errorContainer = errorTone(30),
				onErrorContainer = errorTone(90),
				background = tone("neutral", 6),
				onBackground = tone("neutral", 90),
				surface = tone("neutral", 6),
				onSurface = tone("neutral", 90),
				surfaceVariant = tone("neutralVariant", 30),
				onSurfaceVariant = tone("neutralVariant", 80),
				outline = tone("neutralVariant", 60),
				outlineVariant = tone("neutralVariant", 30),
				surfaceDim = tone("neutral", 6),
				surfaceBright = tone("neutral", 24),
				surfaceContainerLowest = tone("neutral", 4),
				surfaceContainerLow = tone("neutral", 10),
				surfaceContainer = tone("neutral", 12),
				surfaceContainerHigh = tone("neutral", 17),
				surfaceContainerHighest = tone("neutral", 22),
				inverseSurface = tone("neutral", 90),
				inverseOnSurface = tone("neutral", 20),
				inversePrimary = tone("primary", 40),
				shadow = Color3.new(0, 0, 0),
				scrim = Color3.new(0, 0, 0),
			}
		else
			scheme = {
				mode = "light",
				primary = tone("primary", 40),
				onPrimary = tone("primary", 100),
				primaryContainer = tone("primary", 90),
				onPrimaryContainer = tone("primary", 10),
				secondary = tone("secondary", 40),
				onSecondary = tone("secondary", 100),
				secondaryContainer = tone("secondary", 90),
				onSecondaryContainer = tone("secondary", 10),
				tertiary = tone("tertiary", 40),
				onTertiary = tone("tertiary", 100),
				tertiaryContainer = tone("tertiary", 90),
				onTertiaryContainer = tone("tertiary", 10),
				error = errorTone(40),
				onError = errorTone(100),
				errorContainer = errorTone(90),
				onErrorContainer = errorTone(10),
				background = tone("neutral", 98),
				onBackground = tone("neutral", 10),
				surface = tone("neutral", 98),
				onSurface = tone("neutral", 10),
				surfaceVariant = tone("neutralVariant", 90),
				onSurfaceVariant = tone("neutralVariant", 30),
				outline = tone("neutralVariant", 50),
				outlineVariant = tone("neutralVariant", 80),
				surfaceDim = tone("neutral", 87),
				surfaceBright = tone("neutral", 98),
				surfaceContainerLowest = tone("neutral", 100),
				surfaceContainerLow = tone("neutral", 96),
				surfaceContainer = tone("neutral", 94),
				surfaceContainerHigh = tone("neutral", 92),
				surfaceContainerHighest = tone("neutral", 90),
				inverseSurface = tone("neutral", 20),
				inverseOnSurface = tone("neutral", 95),
				inversePrimary = tone("primary", 80),
				shadow = Color3.new(0, 0, 0),
				scrim = Color3.new(0, 0, 0),
			}
		end

		scheme.stateHover = 0.08
		scheme.stateFocus = 0.1
		scheme.statePressed = 0.1
		scheme.stateDragged = 0.16
		scheme.stateDisabled = 0.38
		scheme.stateDisabledContent = 0.38

		return scheme
	end

	function Palette.seedFromHex(hex)
		hex = hex:gsub("#", "")
		if #hex == 3 then
			hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
		end
		return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
	end

	function Palette.toHex(color)
		return string.format("#%02X%02X%02X", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
	end

	return Palette

end

__mods["theme.Schemes"] = function()
	local Palette = __require("theme.Palette")

	local Schemes = {}

	local SEEDS = {
		Material = Color3.fromRGB(103, 80, 164),
		Blue = Color3.fromRGB(21, 101, 192),
		Green = Color3.fromRGB(46, 125, 50),
		Red = Color3.fromRGB(179, 38, 30),
		Orange = Color3.fromRGB(232, 113, 10),
		Teal = Color3.fromRGB(0, 106, 106),
		Pink = Color3.fromRGB(179, 38, 126),
		Monochrome = Color3.fromRGB(120, 120, 124),
		Mint = Color3.fromRGB(0, 137, 123),
		Crimson = Color3.fromRGB(191, 45, 55),
		Violet = Color3.fromRGB(124, 58, 191),
	}

	Schemes.seeds = SEEDS

	local function cloneDeep(source)
		local result = {}
		for key, value in pairs(source) do
			if type(value) == "table" then
				result[key] = cloneDeep(value)
			else
				result[key] = value
			end
		end
		return result
	end

	function Schemes.resolve(name, mode, seed)
		if seed == nil then
			local found = SEEDS[name]
			if found == nil then
				for key, value in pairs(SEEDS) do
					if key:lower() == tostring(name):lower() then
						found = value
						break
					end
				end
			end
			seed = found or SEEDS.Material
		end

		mode = mode or "dark"
		local colors = Palette.scheme(seed, mode == "dark")

		return {
			name = name,
			mode = mode,
			seed = seed,
			colors = colors,
		}
	end

	function Schemes.register(name, spec)
		SEEDS[name] = spec.seed
	end

	function Schemes.list()
		local names = {}
		for key in pairs(SEEDS) do
			table.insert(names, key)
		end
		table.sort(names)
		return names
	end

	Schemes.cloneDeep = cloneDeep

	return Schemes

end

__mods["theme.Tokens"] = function()
	local Tokens = {}

	Tokens.Shape = {
		none = 0,
		extraSmall = 4,
		small = 8,
		medium = 12,
		large = 16,
		largeIncreased = 20,
		extraLarge = 28,
		extraLargeIncreased = 32,
		extraExtraLarge = 48,
		full = 999,
	}

	Tokens.Elevation = {
		level0 = { surface = "surface", shadow = 0 },
		level1 = { surface = "surfaceContainerLow", shadow = 0.25 },
		level2 = { surface = "surfaceContainer", shadow = 0.3 },
		level3 = { surface = "surfaceContainerHigh", shadow = 0.35 },
		level4 = { surface = "surfaceContainerHighest", shadow = 0.38 },
		level5 = { surface = "surfaceContainerHighest", shadow = 0.42 },
	}

	Tokens.Motion = {
		emphasized = { time = 0.55, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
		emphasizedDecelerate = { time = 0.45, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
		emphasizedAccelerate = { time = 0.25, style = Enum.EasingStyle.Quart, direction = Enum.EasingDirection.Out },
		standard = { time = 0.35, style = Enum.EasingStyle.Quart, direction = Enum.EasingDirection.Out },
		standardDecelerate = { time = 0.3, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
		standardAccelerate = { time = 0.22, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
		short = { time = 0.2, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
		short4 = { time = 0.11, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
		slow = { time = 0.8, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
	}

	Tokens.Type = {
		displayLarge = { size = 52, lineHeight = 60, tracking = -0.25, weight = "regular" },
		displayMedium = { size = 42, lineHeight = 52, tracking = 0, weight = "regular" },
		displaySmall = { size = 34, lineHeight = 44, tracking = 0, weight = "regular" },
		headlineLarge = { size = 30, lineHeight = 38, tracking = 0, weight = "regular" },
		headlineMedium = { size = 26, lineHeight = 34, tracking = 0, weight = "regular" },
		headlineSmall = { size = 22, lineHeight = 30, tracking = 0, weight = "regular" },
		titleLarge = { size = 20, lineHeight = 26, tracking = 0, weight = "bold" },
		titleMedium = { size = 16, lineHeight = 24, tracking = 0.15, weight = "bold" },
		titleSmall = { size = 14, lineHeight = 20, tracking = 0.1, weight = "bold" },
		bodyLarge = { size = 16, lineHeight = 24, tracking = 0.5, weight = "regular" },
		bodyMedium = { size = 14, lineHeight = 20, tracking = 0.25, weight = "regular" },
		bodySmall = { size = 12, lineHeight = 16, tracking = 0.4, weight = "regular" },
		labelLarge = { size = 14, lineHeight = 20, tracking = 0.1, weight = "bold" },
		labelMedium = { size = 12, lineHeight = 16, tracking = 0.5, weight = "bold" },
		labelSmall = { size = 11, lineHeight = 16, tracking = 0.5, weight = "bold" },
	}

	Tokens.Fonts = {
		regular = Enum.Font.Gotham,
		medium = Enum.Font.GothamMedium,
		bold = Enum.Font.GothamBold,
		black = Enum.Font.GothamBlack,
		mono = Enum.Font.RobotoMono,
	}

	Tokens.Spacing = {
		xxs = 2,
		xs = 4,
		sm = 8,
		md = 12,
		lg = 16,
		xl = 24,
		xxl = 32,
		xxxl = 48,
	}

	Tokens.Density = {
		scale = 1,
		radiusScale = 1,
	}

	function Tokens.shapeRadius(name)
		local base = Tokens.Shape[name] or Tokens.Shape.medium
		return UDim.new(0, math.round(base * Tokens.Density.radiusScale))
	end

	function Tokens.typeScale(name)
		return Tokens.Type[name] or Tokens.Type.bodyMedium
	end

	function Tokens.motion(name)
		return Tokens.Motion[name] or Tokens.Motion.standard
	end

	return Tokens

end

return __require("init")
