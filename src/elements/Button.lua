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
	elevated = { fill = "surfaceContainerHigh", text = "primary" },
	danger = { fill = "errorContainer", text = "onErrorContainer" },
}

local SIZES = {
	sm = { height = 32, text = "labelMedium", pad = 14, icon = 16 },
	md = { height = 40, text = "labelLarge", pad = 18, icon = 18 },
	lg = { height = 52, text = "labelLarge", pad = 24, icon = 22 },
}

function Button.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Button",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local variant = VARIANTS[props.Variant] or VARIANTS.filled
		local size = SIZES[props.Size] or SIZES.md
		local transparent = variant.fill == "surface"

		local main = Creator.new("TextButton", {
			Name = "Button",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, size.height),
			BackgroundColor3 = theme.colors[variant.fill],
			BackgroundTransparency = transparent and 1 or 0,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = parentFrame,
		}, {
			BackgroundColor3 = variant.fill,
			BackgroundTransparency = transparent and 1 or 0,
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

		local align = props.IconAlign or "Left"
		local iconSize = size.icon
		local textLeft = size.pad

		local text = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, textLeft, 0.5, 0),
			Size = UDim2.new(1, -(size.pad * 2), 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.medium,
			Text = props.Title or "",
			TextColor3 = theme.colors[variant.text],
			TextSize = theme.type[size.text].size,
			TextXAlignment = align == "Right" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = variant.text })
		self.text = text

		if props.Icon then
			local icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = align == "Right"
					and UDim2.new(1, -size.pad - iconSize, 0.5, 0)
					or UDim2.new(0, size.pad, 0.5, 0),
				Size = UDim2.fromOffset(iconSize, iconSize),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors[variant.text],
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = variant.text })
			self.icon = icon

			if align == "Right" then
				text.Position = UDim2.new(0, size.pad, 0.5, 0)
				text.Size = UDim2.new(1, -(size.pad * 2 + iconSize + 10), 1, 0)
			else
				textLeft = size.pad + iconSize + 10
				text.Position = UDim2.new(0, textLeft, 0.5, 0)
				text.Size = UDim2.new(1, -(textLeft + size.pad), 1, 0)
			end
		end

		Element.connect(self, main.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)
		Element.connect(self, main.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
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
