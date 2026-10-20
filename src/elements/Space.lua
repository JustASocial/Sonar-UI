local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)

local Space = {}

function Space.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Space",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		Creator.window = window

		local amount = props.Size or props.Height or 12
		local main = Creator.new("Frame", {
			Name = "Space",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, amount),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Space.new }
