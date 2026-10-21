local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)

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

		if self.circular then
			Row.build(self, {
				title = props.Title,
				description = props.Description,
				icon = props.Icon,
				controlWidth = 48,
				parent = parentFrame,
				order = order,
			})

			local content = self.content

			local circle = Creator.new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(44, 44),
				BackgroundTransparency = 1,
				Parent = content,
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
			local indicatorStroke = Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = theme.colors.surface,
				Thickness = 6,
				Transparency = 1,
				Parent = indicator,
			})
			self.indicator = indicator
			self.indicatorStroke = indicatorStroke
		else
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

			local track = Creator.new("Frame", {
				Position = UDim2.new(0, 0, 1, -20),
				Size = UDim2.new(1, 0, 0, 6),
				BackgroundColor3 = theme.colors.surfaceVariant,
				BorderSizePixel = 0,
				Parent = self.main,
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
		else
			self.indicator.Size = UDim2.new(ratio, 0, 1, 0)
			self.valueLabel.Text = props.Format and props.Format(self.value, ratio)
				or string.format("%d%%", math.floor(ratio * 100))
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
		Row.refreshTheme(self)
		self.indicator.BackgroundColor3 = theme.colors.primary
		if self.track then
			self.track.BackgroundColor3 = theme.colors.surfaceVariant
		end
		if self.valueLabel then
			self.valueLabel.TextColor3 = theme.colors.primary
		end
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = ProgressBar.new }
