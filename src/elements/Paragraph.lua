local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Paragraph = {}

local VARIANTS = {
	filled = { fill = "primary", text = "onPrimary" },
	tonal = { fill = "secondaryContainer", text = "onSecondaryContainer" },
	outlined = { fill = "surface", text = "primary", stroke = "outline" },
	text = { fill = "surface", text = "primary" },
}

function Paragraph.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Paragraph",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local buttons = props.Buttons or {}

		local main = Creator.new("Frame", {
			Name = "Paragraph",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local layout = Creator.new("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = main,
		})

		if props.Icon then
			local icon = Creator.new("ImageLabel", {
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				Parent = main,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.icon = icon
		end

		if props.Title then
			local title = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = theme.fonts.medium,
				Text = props.Title,
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.titleMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LayoutOrder = 2,
				Parent = main,
			}, { TextColor3 = "onSurface" })
			self.title = title
		end

		if props.Description then
			local desc = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodyMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LayoutOrder = 3,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.desc = desc
		end

		for index, spec in ipairs(buttons) do
			local variant = VARIANTS[spec.Variant] or VARIANTS.filled
			local transparent = variant.fill == "surface"
			local button = Creator.new("TextButton", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = theme.colors[variant.fill],
				BackgroundTransparency = transparent and 1 or 0,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = spec.Title or "",
				Font = theme.fonts.medium,
				TextColor3 = theme.colors[variant.text],
				TextSize = theme.type.labelLarge.size,
				LayoutOrder = 10 + index,
				Parent = main,
			}, {
				BackgroundColor3 = variant.fill,
				BackgroundTransparency = transparent and 1 or 0,
				TextColor3 = variant.text,
			})

			Creator.new("UICorner", {
				CornerRadius = theme.shape.button,
				Parent = button,
			})

			if variant.stroke then
				Creator.new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = theme.colors[variant.stroke],
					Transparency = 0,
					Thickness = 1,
					Parent = button,
				}, { Color = variant.stroke })
			end

			local state = Creator.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme.colors[variant.text],
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = button,
			}, { BackgroundColor3 = variant.text })

			Element.connect(self, button.MouseEnter, function()
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
			end)
			Element.connect(self, button.MouseLeave, function()
				Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
			end)
			Element.connect(self, button.MouseButton1Click, function()
				if spec.Callback then
					task.spawn(spec.Callback)
				end
			end)
		end
	end

	function handle:setTitle(text)
		if self.title then
			self.title.Text = text
		end
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
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Paragraph.new }
