local Checkbox = require(script.Parent.Checkbox)

return {
	new = function(ctx)
		ctx.props = ctx.props or {}
		ctx.props.Variant = "Radio"
		return Checkbox.new(ctx)
	end,
}
