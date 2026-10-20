local Creator = require(script.Parent.Creator)
local Container = require(script.Parent.Container)

local Group = {}
Group.__index = Group

function Group.new(ctx)
	local props = ctx.props or {}
	local window = ctx.window
	Creator.window = window

	local direction = props.Direction or props.FillDirection or "row"
	if direction == "horizontal" then
		direction = "row"
	elseif direction == "vertical" then
		direction = "column"
	end

	local self = setmetatable({
		window = window,
		container = ctx.container,
		props = props,
		direction = direction,
		gap = props.Gap or 8,
		__type = "Group",
		__built = false,
		connections = {},
	}, Group)

	Container.init(self)
	return self
end

function Group:_build(parentFrame, order)
	local theme = self.window.theme
	local main = Creator.new("Frame", {
		Name = "Group",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = self.direction == "row" and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parentFrame,
	})
	self.main = main
	self.contentFrame = main

	Creator.new("UIListLayout", {
		FillDirection = self.direction == "row" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, self.gap),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Parent = main,
	})

	self:_relayout()
end

function Group:_relayout()
	if not self.main then
		return
	end
	local count = #self.children
	if count == 0 then
		return
	end
	local gap = self.gap
	for _, child in ipairs(self.children) do
		if child.main then
			local height = child.main.Size.Y
			if self.direction == "row" then
				local share = 1 / count
				local offset = -(gap * (count - 1) / count)
				child.main.Size = UDim2.new(share, offset, height.Scale, height.Offset)
			else
				child.main.Size = UDim2.new(1, 0, height.Scale, height.Offset)
			end
		end
	end
end

function Group:buildChild(handle)
	Container.buildChild(self, handle)
	self:_relayout()
end

function Group:reset()
	Container.reset(self)
end

function Group:setGap(gap)
	self.gap = gap
	if self.layout then
		self.layout.Padding = UDim.new(0, gap)
	end
	self:_relayout()
end

function Group:_destroy()
	if self.main then
		self.main:Destroy()
	end
end

setmetatable(Group, { __index = Container })

return Group
