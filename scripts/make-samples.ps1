# Voice audition: render the same sentence with several Gemini voices -> samples\<Voice>.wav (already trimmed).
# usage: .\make-samples.ps1 -Voices Kore,Puck,Sulafat,Charon [-Text "샘플 문장"]
param(
  [Parameter(Mandatory)][string[]]$Voices,
  [string]$Text = "먼저 클로드 코드에, 챗봇을 만들어 달라고 요청해요. 이어서 깃허브에 올리고, 버셀로 배포해요."
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force samples | Out-Null
$one = @(@{ start = 0; end = 10; text = $Text; say = $Text }) | ConvertTo-Json -Depth 5
if ($one -notmatch '^\s*\[') { $one = "[$one]" }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot "sample_cues.json"), $one, (New-Object Text.UTF8Encoding($false)))
foreach ($v in $Voices) {
  $raw = "samples_raw\$v"; $out = "samples_tmp\$v"
  try {
    & (Join-Path $PSScriptRoot "gen-tts.ps1") -Cues sample_cues.json -Voice $v -RawDir $raw | Out-Null
    & (Join-Path $PSScriptRoot "trim-narr.ps1") -RawDir $raw -OutDir $out | Out-Null
    Copy-Item (Join-Path $out "01.wav") ("samples\{0}.wav" -f $v) -Force
    "OK  samples\$v.wav"
  } catch { "FAIL $v : $($_.Exception.Message)" }
}
