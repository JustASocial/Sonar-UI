local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Button = {}

local VARIANTS = {
	filled = { fill = "primary", text = "onPrimary" },
	tonal = { fill = "secondaryContainer", text = "onSecondaryContainer" },
	outlined = { fill = "surface", text = "primary", stroke = "outline" },
	text = { fill = "surface", text = "primary" },
	elevated = { fill = "surfaceContainerLow", text = "primary" },
}

local SIZES = {
	sm = { height = 32, text = "labelMedium", pad = 14 },
	md = { height = 40, text = "labelLarge", pad = 20 },
	lg = { height = 56, text = "labelLarge", pad = 24 },
}

function Button.new(ctx)
	local handle = Element.new({
		typeName = "Button",
		window = ctx.window,
		container = ctx.container,
		props = ctx.props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local props = self.props
		local variant = VARIANTS[props.Variant] or VARIANTS.filled
		local size = SIZES[props.Size] or SIZES.md

		local main = Creator.new("TextButton", {
			Name = "Button",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, size.height),
			BackgroundColor3 = theme.colors[variant.fill],
			BackgroundTransparency = variant.fill == "surface" and 1 or 0,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = parentFrame,
		}, {
			BackgroundColor3 = variant.fill,
			BackgroundTransparency = variant.fill == "surface" and 1 or 0,
			TextColor3 = variant.text,
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

		local iconName = props.Icon
		local align = props.IconAlign or "Left"
		local textX = align == "Right" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
		local iconSize = size.height - 16

		local text = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, size.pad, 0.5, 0),
			Size = UDim2.new(1, -(size.pad * 2), 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors[variant.text],
			TextSize = theme.type[size.text].size,
			TextXAlignment = textX,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = variant.text })
		self.text = text

		if iconName then
			local icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = align == "Right" and UDim2.new(1, -size.pad - iconSize, 0.5, 0) or UDim2.new(0, size.pad, 0.5, 0),
				Size = UDim2.fromOffset(iconSize, iconSize),
				BackgroundTransparency = 1,
				Image = Icons.image(iconName) or "",
				ImageColor3 = theme.colors[variant.text],
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = variant.text })
			self.icon = icon
			if align == "Right" then
				text.Position = UDim2.new(0, size.pad, 0.5, 0)
				text.Size = UDim2.new(1, -(size.pad * 2 + iconSize + 8), 1, 0)
			else
				text.Position = UDim2.new(0, size.pad + iconSize + 10, 0.5, 0)
				text.Size = UDim2.new(1, -(size.pad * 2 + iconSize + 10), 1, 0)
			end
		end

		Element.connect(self, main.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		end)
		Element.connect(self, main.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short4)
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
