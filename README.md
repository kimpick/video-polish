# video-polish

Recordly 등으로 녹화한 mp4(소리 없는 화면 녹화)에 **배경음 · 시간별 자막 · Gemini TTS 낭독**을 입혀 완성본 mp4를 만드는 Claude Code 스킬.

배경음·자막·목소리는 만들기 전에 후보를 보여주고 사용자가 고른 뒤에 진행한다. 순서와 규칙은 [SKILL.md](SKILL.md), 시행착오는 [references/lessons.md](references/lessons.md).

## 필요한 것
- Windows 10/11 + PowerShell 5.1 이상
- Claude Code (스킬이 로드되는 환경), git
- ffmpeg, Gemini API 키는 **미리 준비하지 않아도 된다.** 스킬이 첫 실행 때 확인하고, 없으면 설치(승인 후)·키 등록 방법을 안내한다. 키가 없으면 자막+배경음만 만들 수도 있다.

## 설치

PowerShell에서 한 줄만 실행한다.

```powershell
git clone https://github.com/kimpick/video-polish.git "$env:USERPROFILE\.claude\skills\video-polish"
```

설치 확인: 새 Claude Code 세션에서 `/video-polish`를 입력하거나, "녹화 영상에 자막·배경음·TTS 넣어줘"라고 요청한다.

## 업데이트

```powershell
git -C "$env:USERPROFILE\.claude\skills\video-polish" pull
```

## 사용

1. 녹화한 mp4를 준비한다(보통 `Downloads\export-*.mp4`).
2. Claude Code에서 "이 영상에 자막이랑 배경음, TTS 넣어줘"처럼 요청한다.
3. Claude가 순서대로 확인을 구한다: API 키 → 배경음 후보 → 자막 시간표(`cues.json`) → 목소리 샘플 → 완성본.
4. 결과는 작업 폴더 `C:\Claude\video-edit\{작업명}\out\`에 저장된다.

## 구성

```
SKILL.md                 진행 절차와 규칙
scripts/                 check-key · make-sheets · make-samples · gen-tts · trim-narr · check-cues · build
references/lessons.md    시행착오 기록 (TTS 잡음, PowerShell 5.1 함정 등)
references/voices.md     Gemini 목소리 분류표
references/bgm-sources.md  CC0 배경음 출처와 사용 이력
```

## 주의
- TTS 원본에는 클립 시작 틱과 끝 잡음이 있다. `trim-narr.ps1`을 반드시 거친다(SKILL.md 6단계).
- 배경음은 CC0 곡만 쓴다. 곡마다 라이선스 페이지를 확인한다.
- 스크립트 `.ps1`은 UTF-8 BOM으로 저장돼 있다. 편집기에서 BOM 없이 저장하면 PowerShell 5.1에서 한글 주석 때문에 동작이 깨질 수 있다.
