import os
import sys

mock = sys.argv[1]
dist = sys.argv[2]
scenario = sys.argv[3]
out = sys.argv[4]

with open(mock, "r", encoding="utf-8") as handle:
    mock_text = handle.read()

with open(dist, "r", encoding="utf-8") as handle:
    dist_text = handle.read()

with open(scenario, "r", encoding="utf-8") as handle:
    scenario_text = handle.read()

marker = 'return __require("init")'
if marker not in dist_text:
    raise SystemExit("dist bundle marker not found")

dist_text = dist_text.replace(marker, '__SONAR_LIB__ = __require("init")')
scenario_text = scenario_text.replace("__SONAR__", "__SONAR__")

with open(out, "w", encoding="utf-8", newline="\n") as handle:
    handle.write(mock_text)
    handle.write("\n")
    handle.write(dist_text)
    handle.write("\n")
    handle.write(scenario_text)

print("dist harness -> %s" % out)
