local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Icons = require(script.Parent.Parent.icons.Init)

local Paragraph = {}

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
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = "onSurfaceVariant" })
			icon.LayoutOrder = 1
			self.icon = icon
		end

		if props.Title then
			local title = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Title,
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.titleMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				Parent = main,
			}, { TextColor3 = "onSurface" })
			title.LayoutOrder = 2
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
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			desc.LayoutOrder = 3
			self.desc = desc
		end

		for index, spec in ipairs(buttons) do
			local variant = spec.Variant or "filled"
			local button = Creator.new("TextButton", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = variant == "filled" and theme.colors.primary or theme.colors.surfaceContainerHighest,
				BackgroundTransparency = variant == "filled" and 0 or 0,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = spec.Title or "",
				Font = theme.fonts.bold,
				TextColor3 = variant == "filled" and theme.colors.onPrimary or theme.colors.onSurface,
				TextSize = theme.type.labelLarge.size,
				LayoutOrder = 10 + index,
				Parent = main,
			}, {
				BackgroundColor3 = variant == "filled" and "primary" or "surfaceContainerHighest",
				TextColor3 = variant == "filled" and "onPrimary" or "onSurface",
			})
			Creator.new("UICorner", {
				CornerRadius = theme.shape.button,
				Parent = button,
			})
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
