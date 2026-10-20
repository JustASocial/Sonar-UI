local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
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

		local main = Creator.new("Frame", {
			Name = "Stat",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 68 or 52),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local title = Creator.new("TextLabel", {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -120, 0, 22),
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
				Size = UDim2.new(1, -120, 0, 18),
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

		local value = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, props.Description and -8 or 0),
			Size = UDim2.fromOffset(140, 30),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.headlineSmall.size,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = main,
		}, { TextColor3 = "onSurface" })
		self.valueLabel = value

		local changeIcon = nil
		local changeLabel = nil
		if props.Change ~= nil then
			local positive = props.Change >= 0
			changeIcon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, -6),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = Icons.image(positive and "trending-up" or "trending-down") or "",
				ImageColor3 = positive and theme.colors.primary or theme.colors.error,
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = positive and "primary" or "error" })
			changeLabel = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -20, 0.5, -6),
				Size = UDim2.fromOffset(70, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = "",
				TextColor3 = positive and theme.colors.primary or theme.colors.error,
				TextSize = theme.type.labelMedium.size,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = main,
			}, { TextColor3 = positive and "primary" or "error" })
			self.changeIcon = changeIcon
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
