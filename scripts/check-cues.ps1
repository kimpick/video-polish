# Timing check of cues.json against the trimmed narration clips (narr\NN.wav) and the video length.
# Flags: narration longer than the subtitle window, overlap with the next cue, cue outside the video.
# usage: .\check-cues.ps1 -Video input.mp4
param([Parameter(Mandatory)][string]$Video, [string]$Cues = "cues.json", [string]$NarrDir = "narr")
Set-Location $PSScriptRoot
$ffprobe = Join-Path (Split-Path (Get-Command ffmpeg).Source) "ffprobe.exe"
$inv = [Globalization.CultureInfo]::InvariantCulture
$vd = [double]::Parse((& $ffprobe -v error -show_entries format=duration -of csv=p=0 $Video), $inv)
# PS 5.1: ConvertFrom-Json returns a JSON array as ONE object; piping through ForEach-Object unrolls it. Do not wrap in @(...) alone.
$cueList = @(Get-Content $Cues -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })
"video {0:N1}s, cues {1}" -f $vd, $cueList.Count
$problems = 0
for ($i = 0; $i -lt $cueList.Count; $i++) {
  $n = $i + 1; $c = $cueList[$i]; $f = Join-Path $NarrDir ("{0:D2}.wav" -f $n)
  $nd = $null
  if (Test-Path $f) { $nd = [double]::Parse((& $ffprobe -v error -show_entries format=duration -of csv=p=0 $f), $inv) }
  $flags = @()
  if ([double]$c.end -le [double]$c.start) { $flags += "end<=start" }
  if ([double]$c.end -gt $vd) { $flags += "end beyond video" }
  if ($nd -ne $null) {
    if ([double]$c.start + $nd -gt [double]$c.end) { $flags += "narration ({0:N1}s) outlasts subtitle window" -f $nd }
    if ($i -lt $cueList.Count - 1 -and [double]$c.start + $nd -gt [double]$cueList[$i + 1].start) { $flags += "narration overlaps next cue" }
  } else { $flags += "no narration clip" }
  if ($flags.Count) { $problems++ }
  "{0:D2}  {1,6:N1}-{2,6:N1}s  narr={3}  {4}" -f $n, [double]$c.start, [double]$c.end, $(if ($nd -ne $null) { "{0:N1}s" -f $nd } else { "--" }), $(if ($flags.Count) { "!! " + ($flags -join "; ") } else { "ok" })
}
"problems: $problems"
