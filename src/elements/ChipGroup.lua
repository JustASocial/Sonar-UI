local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

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
