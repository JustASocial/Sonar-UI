local Input = require(script.Parent.Input)

return {
	new = function(ctx)
		ctx.typeName = "TextArea"
		return Input.new(ctx)
	end,
}
