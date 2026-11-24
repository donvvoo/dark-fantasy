# 어비스 키우기: Google Play 출시 준비

마지막 확인: 2026-11-23 · Godot 4.7.2 · 타깃 API 36 · AAB · arm64-v8a

## 이미 맞춰 둔 것 (프로젝트 안)

| 항목 | 값 | 위치 |
|---|---|---|
| 형식 | Android App Bundle (AAB), Gradle 빌드 | `export_presets.cfg` |
| 패키지 이름 | `com.raiseabyss.game` | `export_presets.cfg` |
| 타깃 / 최소 SDK | 36 (Android 16) / 24 (Android 7.0) | `export_presets.cfg` |
| 아키텍처 | arm64-v8a (64비트) | `export_presets.cfg` |
| 16KB 페이지 | Godot 4.7 지원 | `docs/engine-reference/godot/breaking-changes.md` |
| 화면 | 세로 고정, 몰입 모드 | `project.godot`, `export_presets.cfg` |
| 아이콘 | 512x512 픽셀 아트 (런처 192 자동 생성) | `assets/icon.png`, `docs/store/play-icon-512.png` |
| 저장 | 기기 안 `user://save.json`, 앱 일시정지·종료·뒤로 가기 때 저장 | `src/core/game_state.gd`, `src/main.gd` |
| 권한 | 없음 (인터넷 권한도 없음) | `export_presets.cfg` |
| 개인정보처리방침 | 수집 없음 | `docs/store/privacy-policy.md` |

## 직접 해야 하는 것

1. **패키지 이름: `com.raiseabyss.game`** (확정, 2026-11-24). 첫 업로드 후에는 바꿀 수 없다. `export_presets.cfg`의 `package/unique_name`.
2. **업로드 키 만들기 (내 PC에서, 한 번만).** 이 키는 절대 저장소에 올리지 말고 안전한 곳에 백업한다.
   ```bash
   keytool -genkeypair -v -keystore ashen-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```
3. **릴리스 빌드.** 키 정보는 환경 변수로만 넘긴다.
   ```bash
   GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/안전한/경로/ashen-upload.keystore GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<비밀번호> godot --headless --path . --export-release "Android" build/android/ashen-vanguard.aab
   ```
   (처음 한 번: Godot 4.7.2 내보내기 템플릿 설치, 에디터 설정에 Android SDK·JDK 경로 지정, `android/build`에 Gradle 템플릿 설치)
4. **Play Console 계정** (등록비 25달러, 한 번). 새 개인 계정은 출시 전에 **비공개 테스트(테스터 12명 이상, 14일 이상)** 를 거쳐야 프로덕션 출시를 신청할 수 있다. 계정 유형별 조건은 Play Console에서 확인한다.
5. **Play App Signing 사용**: 첫 AAB 업로드 때 Google이 앱 서명 키를 관리하게 둔다(기본값).
6. **스토어 등록정보**
   - 앱 이름: 어비스 키우기 (영문: Raise Abyss)
   - 짧은 설명(80자 이내) 예시: "횃불을 든 선봉대가 마왕성까지. 켜 두기만 해도 강해지는 다크 판타지 방치 RPG"
   - 그래픽: 아이콘 512x512(`docs/store/play-icon-512.png`), 그래픽 이미지 1024x500, 휴대전화 스크린샷 2장 이상
   - 카테고리: 게임 › 롤플레잉
7. **앱 콘텐츠 설문**
   - 개인정보처리방침 URL: `docs/store/privacy-policy.md` 내용을 웹에 올린 주소 (예: GitHub Pages)
   - 데이터 보안: "데이터를 수집하거나 공유하지 않음"
   - 광고: "광고 없음"
   - 콘텐츠 등급(IARC) 설문: 판타지 전투(피 표현 없음), 사용자 상호작용 없음, 결제 없음
   - 대상 연령: 직접 선택 (13세 이상 권장 — 판타지 폭력)
8. **버전 올리기**: 업데이트마다 `export_presets.cfg`의 `version/code`를 1씩 올리고 `version/name`을 바꾼다.

## 나중에 붙일 것 (지금 버전에는 없음)

- 광고(AdMob)·인앱 결제(Google Play Billing): Godot 플러그인으로 추가. 추가하면 개인정보처리방침·데이터 보안 설문을 함께 갱신.
- 클라우드 저장(Play 게임즈 서비스): 기기 변경 시 진행 이어가기.
