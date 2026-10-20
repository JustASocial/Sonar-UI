local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Checkbox = {}

function Checkbox.new(ctx)
	local props = ctx.props or {}
	local radio = props.Variant == "Radio"
	local handle = Element.new({
		typeName = radio and "Radio" or "Checkbox",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.value = props.Value == true

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local row = Creator.new("Frame", {
			Name = radio and "Radio" or "Checkbox",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 64 or 48),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = row

		local box = Creator.new("TextButton", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, props.Description and -10 or 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = theme.colors.surface,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = row,
		}, { BackgroundColor3 = "surface" })
		self.box = box

		local radius = radio and UDim.new(1, 0) or UDim.new(0, 2)
		Creator.new("UICorner", { CornerRadius = radius, Parent = box })

		local stroke = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.onSurfaceVariant,
			Transparency = 0,
			Thickness = 2,
			Parent = box,
		}, { Color = "onSurfaceVariant" })
		self.stroke = stroke

		local state = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = box,
		}, { BackgroundColor3 = "onSurface" })
		self.state = state

		local mark = nil
		if radio then
			mark = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(8, 8),
				BackgroundColor3 = theme.colors.onPrimary,
				BorderSizePixel = 0,
				Parent = box,
			}, { BackgroundColor3 = "onPrimary" })
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })
		else
			mark = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = Icons.image("check") or "",
				ImageColor3 = theme.colors.onPrimary,
				ScaleType = Enum.ScaleType.Fit,
				Parent = box,
			}, { ImageColor3 = "onPrimary" })
		end
		self.mark = mark

		local title = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 30, 0.5, props.Description and -10 or 0),
			Size = UDim2.new(1, -46, 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		}, { TextColor3 = "onSurface" })
		self.title = title

		if props.Description then
			local desc = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 30, 0.5, 12),
				Size = UDim2.new(1, -46, 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			}, { TextColor3 = "onSurfaceVariant" })
			self.desc = desc
		end

		Element.connect(self, box.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		end)
		Element.connect(self, box.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short4)
		end)
		Element.connect(self, box.MouseButton1Click, function()
			if self.locked then
				return
			end
			self:Set(not self.value, true)
		end)

		self:_render()
	end

	function handle:_render(animate)
		local theme = self.window.theme
		local on = self.value == true
		local token = animate and theme.motion.short or theme.motion.short4

		if self.mark:IsA("ImageLabel") then
			Motion.tween(self.mark, { ImageColor3 = on and theme.colors.onPrimary or theme.colors.surface }, token)
		end
		Motion.tween(self.box, {
			BackgroundColor3 = on and theme.colors.primary or theme.colors.surface,
		}, token)
		Motion.tween(self.stroke, {
			Color = on and theme.colors.primary or theme.colors.onSurfaceVariant,
			Transparency = on and 1 or 0,
		}, token)
		if self.mark:IsA("ImageLabel") then
			Motion.tween(self.mark, { ImageTransparency = on and 0 or 1 }, token)
		else
			Motion.tween(self.mark, { Size = on and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0) }, token)
		end
	end

	function handle:Set(value, skipCallback)
		value = value == true
		if self.value == value and self.main then
			return
		end
		self.value = value
		if self.main then
			self:_render(true)
		end
		if not skipCallback and self.props.Callback then
			task.spawn(self.props.Callback, value)
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
		self:_render(false)
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Checkbox.new }
