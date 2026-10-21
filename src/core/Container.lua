local Creator = require(script.Parent.Creator)

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
	for index, handle in ipairs(children) do
		self:buildChild(handle)
	end
	self:_reveal(children)
end

function Container:_reveal(children)
	local Element = require(script.Parent.Element)
	local index = 0
	for _, handle in ipairs(children) do
		index = index + 1
		if handle.main then
			Element.reveal(handle, (index - 1) * 0.035)
		end
	end
end

function Container.createElement(self, typeName, props)
	local Elements = require(script.Parent.Parent.elements.Init)
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
	local Section = require(script.Parent.Section)
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
	local Group = require(script.Parent.Group)
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
		local Elements = require(script.Parent.Parent.elements.Init)
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
