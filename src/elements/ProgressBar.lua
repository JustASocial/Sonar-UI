local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)

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
