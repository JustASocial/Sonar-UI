local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)

local ProgressBar = {}

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
	handle.circular = props.Variant == "Circular"

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "ProgressBar",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 68 or 52),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local title = Creator.new("TextLabel", {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -70, 0, 20),
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

		local valueLabel = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(62, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = "",
			TextColor3 = theme.colors.primary,
			TextSize = theme.type.labelLarge.size,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = main,
		}, { TextColor3 = "primary" })
		self.valueLabel = valueLabel

		if props.Description then
			local desc = Creator.new("TextLabel", {
				Position = UDim2.new(0, 0, 0, 20),
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

		if self.circular then
			local circle = Creator.new("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(44, 44),
				BackgroundTransparency = 1,
				Parent = main,
			})
			self.circle = circle

			local track = Creator.new("Frame", {
				Size = UDim2.fromOffset(40, 40),
				BackgroundColor3 = theme.colors.surfaceVariant,
				BorderSizePixel = 0,
				Parent = circle,
			}, { BackgroundColor3 = "surfaceVariant" })
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

			local indicator = Creator.new("Frame", {
				Size = UDim2.fromOffset(40, 40),
				BackgroundColor3 = theme.colors.primary,
				BorderSizePixel = 0,
				Parent = circle,
			}, { BackgroundColor3 = "primary" })
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = theme.colors.surface,
				Thickness = 6,
				Transparency = 1,
				Parent = indicator,
			})
			self.indicator = indicator
			self.indicatorStroke = indicator:GetChildren()[1]
		else
			local track = Creator.new("Frame", {
				Position = UDim2.new(0, 0, 1, -8),
				Size = UDim2.new(1, 0, 0, 6),
				BackgroundColor3 = theme.colors.surfaceVariant,
				BorderSizePixel = 0,
				Parent = main,
			}, { BackgroundColor3 = "surfaceVariant" })
			self.track = track
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

			local indicator = Creator.new("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = theme.colors.primary,
				BorderSizePixel = 0,
				Parent = track,
			}, { BackgroundColor3 = "primary" })
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })
			self.indicator = indicator
		end

		self:_render()
	end

	function handle:_ratio()
		local span = self.max - self.min
		if span <= 0 then
			return 0
		end
		return math.clamp((self.value - self.min) / span, 0, 1)
	end

	function handle:_render()
		if not self.main then
			return
		end
		local ratio = self:_ratio()
		if self.circular then
			self.indicatorStroke.Transparency = 1 - ratio
			self.valueLabel.Text = string.format("%d%%", math.floor(ratio * 100))
		else
			self.indicator.Size = UDim2.new(ratio, 0, 1, 0)
			self.valueLabel.Text = props.Format and props.Format(self.value, ratio) or string.format("%d%%", math.floor(ratio * 100))
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
