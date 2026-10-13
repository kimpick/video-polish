# Timestamped contact sheets for reviewing the video. Sheets are written to sheets\.
# usage: .\make-sheets.ps1 -In input.mp4 [-Start 0] [-Duration 0 (0 = whole)] [-Step 10] [-Cols 3] [-Rows 3] [-Width 640] [-Prefix sheet]
# Read each sheet image with the Read tool. Use a small -Step and -Start/-Duration to zoom into a time range.
param(
  [Parameter(Mandatory)][string]$In,
  [double]$Start = 0, [double]$Duration = 0, [double]$Step = 10,
  [int]$Cols = 3, [int]$Rows = 3, [int]$Width = 640, [string]$Prefix = "sheet"
)
Set-Location $PSScriptRoot
$ffmpeg = (Get-Command ffmpeg).Source
$inv = [Globalization.CultureInfo]::InvariantCulture
New-Item -ItemType Directory -Force sheets | Out-Null
$fps = (1 / $Step).ToString("0.######", $inv)
$ts = "drawtext=fontfile='C\:/Windows/Fonts/malgunbd.ttf':text='%{pts\:hms}':fontsize=26:fontcolor=yellow:box=1:boxcolor=black@0.7:x=6:y=6"
$pre = @("-y", "-v", "error")
if ($Start -gt 0) { $pre += @("-ss", $Start.ToString($inv)) }
if ($Duration -gt 0) { $pre += @("-t", $Duration.ToString($inv)) }
# pts restarts at 0 after -ss, so offset the printed time
$off = $Start.ToString($inv)
$ts = "drawtext=fontfile='C\:/Windows/Fonts/malgunbd.ttf':text='%{pts\:hms\:$off}':fontsize=26:fontcolor=yellow:box=1:boxcolor=black@0.7:x=6:y=6"
& $ffmpeg @pre -i $In -vf "fps=$fps,scale=${Width}:-1,$ts,tile=${Cols}x${Rows}" ("sheets\{0}_%d.jpg" -f $Prefix)
Get-ChildItem ("sheets\{0}_*.jpg" -f $Prefix) | Select-Object -ExpandProperty FullName
