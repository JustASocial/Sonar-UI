param(
	[string]$Source = "C:\Users\nikit\AppData\Local\Temp\opencode\research\icons\lucide\dist\Icons.lua",
	[string]$Target = "C:\Users\nikit\Downloads\Sonar-Ui-Lib\src\icons\Lucide.lua"
)

$ErrorActionPreference = "Stop"

$wanted = @(
	"house","settings","search","user","users","bell","bell-off","check","x","plus","minus",
	"trash-2","pencil","copy","clipboard","image","folder","folder-open","file","file-text",
	"sun","moon","star","heart","lock","lock-open","eye","eye-off","info","circle-alert",
	"triangle-alert","circle-check","circle-x","arrow-left","arrow-right","arrow-up","arrow-down",
	"chevron-left","chevron-right","chevron-up","chevron-down","chevrons-up-down","more-horizontal",
	"more-vertical","menu","panel-left","panel-right","panel-top","panel-bottom","layout-dashboard",
	"layout-grid","layout-list","palette","type","sliders-horizontal","volume-2","volume-x",
	"wifi","wifi-off","battery","play","pause","square","refresh-cw","download","upload","link",
	"external-link","globe","terminal","code","box","layers","list","table","calendar","clock",
	"timer","mail","message-circle","phone","camera","video","mic","zap","activity","trending-up",
	"trending-down","bar-chart","chart-pie","grid-3x3","columns-3","rows-3","maximize","minimize",
	"rotate-ccw","save","filter","send","share-2","printer","credit-card","dollar-sign","percent",
	"hash","at-sign","key","database","server","hard-drive","cloud","cloud-upload","cloud-download",
	"monitor","smartphone","tablet","cpu","package","gift","award","target","crosshair","flag",
	"bookmark","thumbs-up","smile","frown","meh","rocket","flame","sparkles","wand-2","crown",
	"gauge","radar","waves","orbit","scan","scan-line","crop","shuffle","repeat","undo","redo",
	"wand","wand-sparkles","sliders-vertical",
	"bold","italic","underline","strikethrough","align-left","align-center","align-right",
	"chevrons-up","chevrons-down","arrow-up-right","arrow-down-right","corner-down-right",
	"circle","circle-dot","dot","grip-vertical","grip-horizontal","ellipsis","square-check-big",
	"check-check","circle-plus","circle-minus","minus-circle","plus-circle","sliders",
	"chevron-up-down","panel-bottom-open","panel-right-open","columns-2","rows-2","square-pen",
	"clipboard-check","clipboard-list","file-image","file-code","file-json","file-lock",
	"message-square","message-square-plus","bell-plus","user-plus","user-minus","user-check",
	"log-in","log-out","power","settings-2","list-todo","list-ordered",
	"calendar-days","calendar-check","calendar-clock","map-pin","navigation","compass",
	"globe-2","languages","book","book-open","notebook","notebook-pen","highlighter",
	"eraser","paintbrush","palette-2","droplet","flame-2","sunrise","sunset","moon-star",
	"bolt","shield","shield-check","shield-alert","badge-check","badge-alert","badge-info",
	"circle-slash","slash","trending-flat","signal","antenna","satellite","waypoints"
) | Sort-Object -Unique

$content = Get-Content -LiteralPath $Source -Raw

$map = [ordered]@{}
foreach ($name in $wanted) {
	$pattern = '(?m)^\s*\["' + [regex]::Escape($name) + '"\]\s*=\s*"([^"]+)"'
	$match = [regex]::Match($content, $pattern)
	if ($match.Success) {
		$map[$name] = $match.Groups[1].Value
	}
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("return {")
foreach ($key in $map.Keys) {
	$lines.Add(('	["{0}"] = "{1}",' -f $key, $map[$key]))
}
$lines.Add("}")

[System.IO.File]::WriteAllLines($Target, $lines, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("Extracted {0} icons to {1}" -f $map.Count, $Target)
