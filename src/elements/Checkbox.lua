local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Checkbox = {}

local SIZES = {
	Checkbox = 20,
	Radio = 20,
}

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

		local size = SIZES[radio and "Radio" or "Checkbox"]

		Row.build(self, {
			title = props.Title,
			description = props.Description,
			icon = props.Icon,
			controlWidth = size,
			parent = parentFrame,
			order = order,
		})

		local content = self.content
		local box = Creator.new("TextButton", {
			Name = radio and "Radio" or "Checkbox",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = theme.colors.surface,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = content,
		}, { BackgroundColor3 = "surface" })
		self.box = box

		Creator.new("UICorner", {
			CornerRadius = radio and UDim.new(1, 0) or UDim.new(0, 3),
			Parent = box,
		})

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
		self.boxState = state

		local mark
		if radio then
			mark = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(10, 10),
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
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = box,
			}, { ImageColor3 = "onPrimary" })
		end
		self.mark = mark

		Element.connect(self, box.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)
		Element.connect(self, box.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
		end)
		Element.connect(self, box.MouseButton1Click, function()
			if self.locked then
				return
			end
			self:Set(not self.value, true)
		end)

		self:_render()
	end

	function handle:_render()
		local theme = self.window.theme
		local on = self.value == true
		local token = theme.motion.short

		Motion.tween(self.box, {
			BackgroundColor3 = on and theme.colors.primary or theme.colors.surface,
		}, token)
		Motion.tween(self.stroke, {
			Color = on and theme.colors.primary or theme.colors.onSurfaceVariant,
			Transparency = on and 1 or 0,
		}, token)

		if self.mark:IsA("ImageLabel") then
			Motion.tween(self.mark, {
				ImageTransparency = on and 0 or 1,
				ImageColor3 = on and theme.colors.onPrimary or theme.colors.surface,
			}, token)
		else
			Motion.tween(self.mark, {
				Size = on and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
				BackgroundColor3 = theme.colors.onPrimary,
			}, token)
		end
	end

	function handle:Set(value, skipCallback)
		value = value == true
		if self.value == value and self.main then
			return
		end
		self.value = value
		if self.main then
			self:_render()
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
		Row.refreshTheme(self)
		self:_render()
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Checkbox.new }
