param(
	[string]$Luau = "luau",
	[string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$out = Join-Path $env:TEMP "sonar-harness.lua"

& $Python (Join-Path $PSScriptRoot "bundle.py") (Join-Path $root "src") (Join-Path $PSScriptRoot "mock.lua") (Join-Path $PSScriptRoot "scenario.lua") $out
if ($LASTEXITCODE -ne 0) { throw "bundling failed" }

& $Luau $out
exit $LASTEXITCODE
