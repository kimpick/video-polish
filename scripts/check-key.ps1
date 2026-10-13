# Gemini API key + TTS model check. Never prints the key. Writes the chosen model to model.txt in the job folder.
# usage: .\check-key.ps1
Set-Location $PSScriptRoot
$key = [Environment]::GetEnvironmentVariable("GEMINI_API_KEY", "User")
if (-not $key) { $key = $env:GEMINI_API_KEY }
if (-not $key) {
  "KEY_MISSING: GEMINI_API_KEY 환경변수가 없습니다. 사용자에게 새 터미널에서 setx GEMINI_API_KEY ""키"" 실행을 요청하세요(채팅에 키 붙이지 않기)."
  exit 2
}
"KEY_FOUND: GEMINI_API_KEY (길이 $($key.Length), 값은 출력하지 않음)"
try {
  $r = Invoke-RestMethod "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200" -Headers @{ "x-goog-api-key" = $key }
} catch { "KEY_INVALID: 모델 목록 조회 실패 - $($_.Exception.Message)"; exit 3 }

$tts = $r.models | Where-Object { $_.name -match "tts" -and ($_.supportedGenerationMethods -contains "generateContent") }
if (-not $tts) { "NO_TTS_MODEL: 이 키로 쓸 수 있는 TTS 모델이 없습니다."; exit 4 }
$rank = $tts | ForEach-Object {
  $v = 0.0; if ($_.name -match "(\d+\.\d+)") { $v = [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture) }
  [pscustomobject]@{ Name = ($_.name -replace "^models/", ""); Ver = $v; Preview = ($_.name -match "preview"); Lite = ($_.name -match "lite"); Pro = ($_.name -match "pro") }
}
"사용 가능한 TTS 모델:"; $rank | ForEach-Object { "  {0}  (v{1}{2}{3})" -f $_.Name, $_.Ver, $(if ($_.Preview) { ", preview" }), $(if ($_.Lite) { ", lite" }) }
$pick = $rank | Sort-Object @{ e = { -$_.Ver } }, @{ e = { $_.Preview } }, @{ e = { $_.Lite } }, @{ e = { $_.Pro } } | Select-Object -First 1
Set-Content -Path (Join-Path $PSScriptRoot "model.txt") -Value $pick.Name -Encoding ASCII
"CHOSEN_MODEL: $($pick.Name)  (model.txt에 저장)"
