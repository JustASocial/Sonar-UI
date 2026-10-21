local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)
local Scroll = require(script.Parent.Parent.core.Scroll)
local Variables = require(script.Parent.Parent.core.Variables)

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
			BackgroundTransparency = 1,
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
