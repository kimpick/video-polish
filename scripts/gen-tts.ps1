# Gemini TTS: reads "say" (falls back to "text") of each cue in cues.json and writes RAW clips to narr_raw\NN.wav.
# The raw clips carry a click at the start and a noise burst at the end -> always run trim-narr.ps1 afterwards.
# usage: .\gen-tts.ps1 [-Voice Sulafat] [-Only 2,3] [-Cues cues.json] [-RawDir narr_raw] [-Model <id>]
# NEVER prefix a style instruction to the text: the model reads it aloud (4 s clip became 10-15 s). Control tone with -Voice only.
param(
  [string]$Cues = "cues.json",
  [string]$Voice = "",
  [string]$Model = "",
  [string]$RawDir = "narr_raw",
  [int[]]$Only
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$key = [Environment]::GetEnvironmentVariable("GEMINI_API_KEY", "User")
if (-not $key) { $key = $env:GEMINI_API_KEY }
if (-not $key) { throw "GEMINI_API_KEY missing (run check-key.ps1)" }
if (-not $Model) { if (Test-Path model.txt) { $Model = (Get-Content model.txt -Raw).Trim() } else { throw "model.txt missing (run check-key.ps1)" } }
if (-not $Voice) { if (Test-Path voice.txt) { $Voice = (Get-Content voice.txt -Raw).Trim() } else { $Voice = "Sulafat" } }
$ffmpeg = (Get-Command ffmpeg).Source
# PS 5.1: ConvertFrom-Json returns a JSON array as ONE object; piping through ForEach-Object unrolls it. Do not wrap in @(...) alone.
$cueList = @(Get-Content $Cues -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })
New-Item -ItemType Directory -Force $RawDir | Out-Null
$uri = "https://generativelanguage.googleapis.com/v1beta/models/${Model}:generateContent"
"model=$Model voice=$Voice"

for ($i = 0; $i -lt $cueList.Count; $i++) {
  $n = $i + 1
  if ($Only -and ($Only -notcontains $n)) { continue }
  $c = $cueList[$i]
  $t = if ($c.say) { $c.say } else { ($c.text -replace "`n", " ") }
  $body = @{
    contents = @(@{ parts = @(@{ text = $t }) })
    generationConfig = @{
      responseModalities = @("AUDIO")
      speechConfig = @{ voiceConfig = @{ prebuiltVoiceConfig = @{ voiceName = $Voice } } }
    }
  } | ConvertTo-Json -Depth 10
  $bytes = [Text.Encoding]::UTF8.GetBytes($body)
  $ok = $false
  for ($try = 1; $try -le 4 -and -not $ok; $try++) {
    try {
      $r = Invoke-RestMethod -Uri $uri -Method Post -Headers @{ "x-goog-api-key" = $key } -ContentType "application/json; charset=utf-8" -Body $bytes
      $b64 = $r.candidates[0].content.parts[0].inlineData.data
      if (-not $b64) { throw "no audio in response" }
      $pcm = Join-Path $RawDir ("{0:D2}.pcm" -f $n)
      [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot $pcm), [Convert]::FromBase64String($b64))
      # ffmpeg prints an informational "Guessed Channel Layout" to stderr; PowerShell 5.1 treats native stderr as an error under -Stop
      $wav = Join-Path $RawDir ("{0:D2}.wav" -f $n)
      $ErrorActionPreference = "Continue"
      & $ffmpeg -y -v quiet -f s16le -ar 24000 -ac 1 -i $pcm $wav
      $ErrorActionPreference = "Stop"
      if (-not (Test-Path $wav)) { throw "pcm->wav conversion failed" }
      [IO.File]::Delete((Join-Path $PSScriptRoot $pcm))
      $ok = $true; "{0:D2} ok: {1}" -f $n, $t
    } catch {
      # 429 = per-minute quota: back off, then retry
      "{0:D2} retry {1}: {2}" -f $n, $try, $_.Exception.Message
      Start-Sleep (20 * $try)
    }
  }
  if (-not $ok) { throw "cue $n failed" }
}
