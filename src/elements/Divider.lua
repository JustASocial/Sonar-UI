local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)

local Divider = {}

function Divider.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Divider",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "Divider",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Text and 24 or 9),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local line = Creator.new("Frame", {
			Position = UDim2.new(0, 0, 0, props.Text and 12 or 4),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme.colors.outlineVariant,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Parent = main,
		}, { BackgroundColor3 = "outlineVariant" })
		self.line = line

		if props.Text then
			local label = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 12),
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Text,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.labelSmall.size,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.label = label
		end
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		self.line.BackgroundColor3 = theme.colors.outlineVariant
		if self.label then
			self.label.TextColor3 = theme.colors.onSurfaceVariant
		end
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Divider.new }
