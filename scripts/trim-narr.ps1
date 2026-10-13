# Remove the TTS glitches from raw clips: click in the first ~10 ms, noise burst at the very end.
# Tail: find the last silence segment (speech end .. burst start) and cut inside it; fallback = cut last 0.3 s.
# Head: drop first 12 ms + 8 ms fade-in. Tail: 30 ms fade-out.
# Do NOT use a fixed tail cut: regenerated clips end at different positions (speech can be cut off).
# usage: .\trim-narr.ps1 [-RawDir narr_raw] [-OutDir narr]
param([string]$RawDir = "narr_raw", [string]$OutDir = "narr")
$ErrorActionPreference = "Continue"   # ffmpeg writes progress/info to stderr; do not let a caller's -Stop turn that into an error
Set-Location $PSScriptRoot
$ffmpeg = (Get-Command ffmpeg).Source
$inv = [Globalization.CultureInfo]::InvariantCulture
New-Item -ItemType Directory -Force $OutDir | Out-Null
foreach ($f in Get-ChildItem (Join-Path $RawDir "*.wav")) {
  $log = & $ffmpeg -hide_banner -i $f.FullName -af "silencedetect=n=-40dB:d=0.05" -f null NUL 2>&1 | Out-String
  $starts = @([regex]::Matches($log, 'silence_start: ([\d.]+)') | ForEach-Object { [double]::Parse($_.Groups[1].Value, $inv) })
  $ends = @([regex]::Matches($log, 'silence_end: ([\d.]+)') | ForEach-Object { [double]::Parse($_.Groups[1].Value, $inv) })
  $m = [regex]::Match($log, 'Duration: (\d+):(\d+):([\d.]+)')
  $dur = [int]$m.Groups[1].Value * 3600 + [int]$m.Groups[2].Value * 60 + [double]::Parse($m.Groups[3].Value, $inv)
  $cut = $dur - 0.3
  if ($starts.Count -gt 0 -and $ends.Count -gt 0) {
    $s = $starts[$starts.Count - 1]; $e = $ends[$ends.Count - 1]
    if ($e -gt $s -and $e -lt $dur - 0.02) { $cut = $s + ($e - $s) * 0.6 }
  }
  $cut = [math]::Round($cut, 3)
  $headS = "0.012"; $cutS = $cut.ToString($inv)
  $fo = ([math]::Round($cut - 0.012 - 0.03, 3)).ToString($inv)
  $af = "atrim=start=${headS}:end=${cutS},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.008,afade=t=out:st=${fo}:d=0.03"
  & $ffmpeg -y -v error -i $f.FullName -af $af (Join-Path $OutDir $f.Name)
  "{0}  raw {1:N2}s -> {2:N2}s" -f $f.Name, $dur, ($cut - 0.012)
}
