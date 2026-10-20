local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Rating = {}

local STAR = 24

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

		local main = Creator.new("Frame", {
			Name = "Rating",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 68 or 48),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local title = Creator.new("TextLabel", {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -140, 0, 22),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = "onSurface" })
		self.title = title

		if props.Description then
			local desc = Creator.new("TextLabel", {
				Position = UDim2.new(0, 0, 0, 22),
				Size = UDim2.new(1, -140, 0, 18),
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

		local valueLabel = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = "",
			TextColor3 = theme.colors.primary,
			TextSize = theme.type.labelLarge.size,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = main,
		}, { TextColor3 = "primary" })
		self.valueLabel = valueLabel

		local row = Creator.new("Frame", {
			Position = UDim2.new(0, 0, 0, props.Description and 42 or 22),
			Size = UDim2.new(1, 0, 0, STAR),
			BackgroundTransparency = 1,
			Parent = main,
		})
		self.row = row

		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
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
				Motion.tween(icon, { ImageColor3 = theme.colors.primary }, theme.motion.short4)
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
		if not self.row then
			return
		end
		local theme = self.window.theme
		for index, data in ipairs(self.stars) do
			local filled = index <= self.value
			Motion.tween(data.icon, {
				ImageColor3 = filled and theme.colors.primary or theme.colors.onSurfaceVariant,
			}, theme.motion.short4)
		end
		self.valueLabel.Text = string.format("%d/%d", self.value, self.max)
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
		local theme = self.window.theme
		self.title.TextColor3 = theme.colors.onSurface
		self.valueLabel.TextColor3 = theme.colors.primary
		self:_render()
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Rating.new }
