# Gemini TTS 목소리 (한국어 낭독용 후보)

공식 설명(영문 톤) 기준으로 사용자에게 보여줄 분류표다. **성별 표기는 통칭이라 틀릴 수 있고, 한국어 발음 품질은 목소리마다 다르다.** 반드시 `make-samples.ps1`로 같은 문장을 만들어 사용자가 듣고 고르게 한다.
검증됨: Kore, Puck, Sulafat (이 PC·키로 실제 생성 확인). 나머지는 이름이 거부되면 `FAIL`로 표시되니 다른 목소리로 대체한다.

| 취향 | 여성 | 남성 |
|---|---|---|
| 산뜻·밝음 | Zephyr (Bright), Leda (Youthful), Aoede (Breezy), Laomedeia (Upbeat) | Puck (Upbeat), Sadachbia (Lively) |
| 진중·단단함 | Kore (Firm), Gacrux (Mature) | Charon (Informative), Orus (Firm), Alnilam (Firm) |
| 따뜻·친근 | Sulafat (Warm), Vindemiatrix (Gentle) | Achird (Friendly), Zubenelgenubi (Casual) |
| 부드럽·차분 | Achernar (Soft), Callirrhoe (Easy-going) | Algieba (Smooth), Umbriel (Easy-going) |
| 또렷·설명형 | Erinome (Clear) | Iapetus (Clear), Sadaltager (Knowledgeable), Rasalgethi (Informative) |

## 고르는 요령
- 튜토리얼·교육 영상: 따뜻·친근 또는 또렷·설명형이 안정적. 이번 작업은 Sulafat(여성, 따뜻)을 기본으로 썼다.
- 사용자 취향이 "여자/남자 + 산뜻/진중"처럼 두 축으로 오면 표의 칸에서 각 2개씩 총 3~4개 샘플을 만든다.
- 샘플 문장은 영상에 실제로 나오는 용어(클로드, 깃허브, 버셀 등)가 들어간 한 문장으로 한다. 용어 발음이 어색한 목소리를 걸러낸다.
- 속도·감정은 지시문으로 바꾸지 않는다(지시문까지 읽는다). 목소리 선택으로만 조절한다.
