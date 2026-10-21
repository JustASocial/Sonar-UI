local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

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
