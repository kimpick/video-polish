# Burn subtitles + mix narration (narr\NN.wav at each cue start) + BGM (auto-ducked under narration) -> mp4.
# usage: .\build.ps1 -In input.mp4 [-Bgm bgm\track.wav] [-Out out\final.mp4] [-BgmVol 0 (0 = auto)] [-PosY 60] [-FontSize 36]
# Notes (PowerShell 5.1): never name a variable $args; parameter names are case-insensitive variables ($Cues vs $cues collide).
param(
  [Parameter(Mandatory)][string]$In,
  [string]$Bgm,
  [string]$Cues = "cues.json",
  [string]$Out = "out\final.mp4",
  [double]$BgmVol = 0,
  [int]$FontSize = 36,
  [string]$PosY = "60"
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$ffmpeg = (Get-Command ffmpeg).Source
$ffprobe = Join-Path (Split-Path $ffmpeg) "ffprobe.exe"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$inv = [Globalization.CultureInfo]::InvariantCulture

$dur = [double]::Parse((& $ffprobe -v error -show_entries format=duration -of csv=p=0 $In), $inv)
# PS 5.1: ConvertFrom-Json returns a JSON array as ONE object; piping through ForEach-Object unrolls it. Do not wrap in @(...) alone.
$cueList = @(Get-Content $Cues -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })
New-Item -ItemType Directory -Force cues_txt | Out-Null

# subtitles: one text file per cue + drawtext (avoids Korean/special-char escaping in the filter string)
$vf = @()
for ($i = 0; $i -lt $cueList.Count; $i++) {
  $c = $cueList[$i]
  $tf = "cues_txt/{0:D2}.txt" -f ($i + 1)
  [IO.File]::WriteAllText((Join-Path $PSScriptRoot $tf), ($c.text -replace '\\n', "`n"), $utf8)
  $s = ([double]$c.start).ToString($inv); $e = ([double]$c.end).ToString($inv)
  $vf += "drawtext=fontfile='C\:/Windows/Fonts/malgunbd.ttf':textfile='$tf':fontsize=${FontSize}:fontcolor=white:box=1:boxcolor=black@0.6:boxborderw=18:line_spacing=8:x=(w-text_w)/2:y=${PosY}:enable='between(t,$s,$e)'"
}
$filter = "[0:v]" + ($vf -join ",") + "[v]"

# audio
$fa = @("-y", "-i", $In)
$idx = 1; $afilt = @()
$hasBgm = $Bgm -and (Test-Path $Bgm)
if ($hasBgm) {
  if ($BgmVol -le 0) {
    # auto level: put the BGM mean at about -29 dB (narration sits near -17 dB)
    $ErrorActionPreference = "Continue"   # ffmpeg stderr must not abort under -Stop
    $o = (& $ffmpeg -hide_banner -i $Bgm -af volumedetect -f null NUL 2>&1 | Select-String "mean_volume") -replace '.*mean_volume: ', '' -replace ' dB', ''
    $ErrorActionPreference = "Stop"
    $mean = [double]::Parse($o.Trim(), $inv)
    $BgmVol = [math]::Round([math]::Pow(10, (-29 - $mean) / 20), 3)
    "BGM mean $mean dB -> volume $BgmVol"
  }
  $fa += @("-stream_loop", "-1", "-i", $Bgm)
  $d = $dur.ToString($inv); $fo = [math]::Max(0, $dur - 3).ToString($inv)
  $afilt += "[$idx`:a]volume=$($BgmVol.ToString($inv)),atrim=0:$d,afade=t=in:d=2,afade=t=out:st=${fo}:d=3,asetpts=N/SR/TB[bgm]"
  $idx++
}
$narr = @()
for ($i = 0; $i -lt $cueList.Count; $i++) {
  $w = "narr/{0:D2}.wav" -f ($i + 1)
  if (Test-Path $w) {
    $fa += @("-i", $w)
    $ms = [int]([double]$cueList[$i].start * 1000)
    $afilt += "[$idx`:a]adelay=$ms|$ms[n$i]"
    $narr += "[n$i]"; $idx++
  }
}
if ($narr.Count -gt 0) {
  # apad: sidechaincompress ends with its shortest input, so pad the voice track to the full length
  $afilt += ($narr -join "") + "amix=inputs=$($narr.Count):normalize=0,apad=whole_dur=$($dur.ToString($inv))[voice]"
  if ($hasBgm) {
    $afilt += "[voice]asplit[vo1][vo2]"
    $afilt += "[bgm][vo1]sidechaincompress=threshold=0.03:ratio=8:attack=20:release=400[duck]"
    $afilt += "[duck][vo2]amix=inputs=2:normalize=0[mx]"
    $afilt += "[mx]alimiter=limit=0.95[a]"
  } else { $afilt += "[voice]alimiter=limit=0.95[a]" }
} elseif ($hasBgm) { $afilt += "[bgm]anull[a]" }

$fc = $filter
if ($afilt.Count -gt 0) { $fc += ";" + ($afilt -join ";") }
$map = @("-map", "[v]")
if ($afilt.Count -gt 0) { $map += @("-map", "[a]") }

New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
$ErrorActionPreference = "Continue"
& $ffmpeg -hide_banner -loglevel error @fa -filter_complex $fc @map -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k -t $dur $Out
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed ($LASTEXITCODE)" }
"done: $Out"
