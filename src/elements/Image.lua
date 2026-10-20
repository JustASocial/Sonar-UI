local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)

local Image = {}

local function parseAspect(value)
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		local width, height = value:match("^(%d+):(%d+)$")
		if width and height then
			return tonumber(width) / tonumber(height)
		end
	end
	return 16 / 9
end

function Image.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Image",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local ratio = parseAspect(props.AspectRatio)
		local width = props.Width or 320
		local height = props.Height or math.floor(width / ratio)

		local main = Creator.new("Frame", {
			Name = "Image",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, height + (props.Caption and 24 or 0)),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local holder = Creator.new("Frame", {
			Size = UDim2.fromOffset(width, height),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.holder = holder

		Creator.new("UICorner", {
			CornerRadius = props.Radius and UDim.new(0, props.Radius) or theme.shape.card,
			Parent = holder,
		})

		local image = Creator.new("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = props.Image or "",
			ScaleType = Enum.ScaleType.Crop,
			Parent = holder,
		})
		self.image = image

		local caption = nil
		if props.Caption then
			caption = Creator.new("TextLabel", {
				Position = UDim2.new(0, 0, 1, -20),
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Caption,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.caption = caption
		end
	end

	function handle:SetImage(url)
		if self.image then
			self.image.Image = url or ""
		end
		self.props.Image = url
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		self.holder.BackgroundColor3 = theme.colors.surfaceContainerHighest
		if self.caption then
			self.caption.TextColor3 = theme.colors.onSurfaceVariant
		end
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Image.new }
