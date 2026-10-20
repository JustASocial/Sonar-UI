import os
import re
import sys

src = sys.argv[1]
mock = sys.argv[2]
scenario = sys.argv[3]
out = sys.argv[4]

modules = {}

for root, dirs, files in os.walk(src):
    for name in files:
        if not name.endswith(".lua"):
            continue
        path = os.path.join(root, name)
        rel = os.path.relpath(path, src).replace("\\", "/")
        key = rel[:-4].replace("/", ".")
        modules[key] = path


def resolve(current_key, expr):
    parts = current_key.split(".")
    folder = parts[:-1]
    segs = expr.split(".")
    i = 0
    if segs and segs[0] == "script":
        i = 1
    parents = 0
    while i < len(segs) and segs[i] == "Parent":
        parents += 1
        i += 1
    up = parents - 1
    if up > 0:
        folder = folder[: len(folder) - up]
    rest = segs[i:]
    if not rest:
        return None
    candidate = ".".join(folder + rest)
    if candidate in modules:
        return candidate
    return None


pattern = re.compile(r"require\((script(?:\.Parent)*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\)")
dynamic = re.compile(r"require\(script\[file\]\)")

chunks = []

with open(mock, "r", encoding="utf-8") as handle:
    chunks.append(handle.read())

chunks.append("local __mods = {}\nlocal __cache = {}\n")
chunks.append("""
local function __require(key)
	if __cache[key] ~= nil then
		return __cache[key]
	end
	local loader = __mods[key]
	if not loader then
		error("module not found: " .. tostring(key))
	end
	local result = loader()
	__cache[key] = result
	return result
end
""")

for key in sorted(modules):
    path = modules[key]
    with open(path, "r", encoding="utf-8") as handle:
        body = handle.read()

    def repl_static(match):
        target = resolve(key, match.group(1))
        if target is None:
            raise SystemExit("cannot resolve " + match.group(1) + " in " + key)
        return '__require("%s")' % target

    body = pattern.sub(repl_static, body)
    body = dynamic.sub('__require("elements." .. file)', body)
    indented = "\n".join("\t" + line if line.strip() else line for line in body.split("\n"))
    chunks.append('__mods["%s"] = function()\n%s\nend\n' % (key, indented))

with open(scenario, "r", encoding="utf-8") as handle:
    body = handle.read().replace("__SONAR__", '__require("init")')
    chunks.append(body)

with open(out, "w", encoding="utf-8") as handle:
    handle.write("\n".join(chunks))

print("bundled %d modules -> %s" % (len(modules), out))
