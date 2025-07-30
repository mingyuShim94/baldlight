# BaldClicker - 대머리 수집 클리커

재미있는 애니메이션과 함께 즐기는 한국형 모바일 앱입니다. 손전등 기능과 대머리 캐릭터의 유머러스한 상호작용을 결합한 엔터테인먼트 유틸리티 앱입니다.

[📱 앱스토어에서 보기](https://apps.apple.com/az/app/bald-clicker/id6747410558?uo=2)

## 🎯 주요 기능

### 🔦 기본 기능
- **대머리 캐릭터**: 다양한 스타일의 대머리 이미지 컬렉션
- **터치 상호작용**: 캐릭터를 터치하면 재미있는 반응과 사운드
- **진동 피드백**: 터치 시 햅틱 피드백 제공

### 🎮 게임 요소
- **컬렉션 시스템**: 다양한 대머리 스타일 수집
- **카운팅 시스템**: 터치 횟수 추적 및 통계
- **피버타임**: 특별한 이벤트 모드
- **사운드 효과**: 다양한 아픈 소리와 효과음

### 💰 수익화
- **Google AdMob**: 광고 기반 수익 모델
- **앱 오픈 광고**: 앱 실행 시 광고 표시
- **보상형 광고**: 컬렉션 아이템 획득을 위한 광고

## 🏗️ 기술 스택

### 플랫폼
- **Flutter 3.6.0+**
- **Android**: minSdk 21
- **iOS**: 13.0+

### 주요 의존성
```yaml
dependencies:
  audioplayers: ^5.0.0          # 사운드 효과
  google_mobile_ads: ^6.0.0     # AdMob 광고
  shared_preferences: ^2.0.15   # 로컬 데이터 저장
  vibration: ^2.0.0             # 진동 피드백
  url_launcher: ^6.1.6          # 외부 링크
  package_info_plus: ^4.2.0     # 앱 정보
```

## 📁 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점 및 메인 UI
├── screens/
│   ├── collection_screen.dart   # 컬렉션 화면
│   └── settings_screen.dart     # 설정 화면
├── services/
│   ├── admob_service.dart       # 광고 관리
│   ├── bald_style_service.dart  # 대머리 스타일 관리
│   ├── counting_service.dart    # 카운팅 시스템
│   ├── fever_time_service.dart  # 피버타임 관리
│   ├── game_service.dart        # 게임 로직
│   └── sound_service.dart       # 사운드 관리
└── widgets/
    └── hand_overlay.dart        # 손 오버레이 위젯

assets/
├── images/
│   ├── bald_styles/            # 대머리 스타일 이미지
│   ├── hand_palm.png           # 손바닥 이미지
│   ├── left_hand.png           # 왼손 이미지
│   └── right_hand.png          # 오른손 이미지
├── sounds/
│   ├── hurt_sounds/            # 다양한 아픈 소리 (7개)
│   ├── pain_sound.mp3          # 기본 아픈 소리
│   └── tap_sound.mp3           # 터치 효과음
└── icon/
    └── icon.png                # 앱 아이콘
```

## 🚀 개발 가이드

### 허용된 명령어
```bash
flutter pub upgrade    # 의존성 업데이트
flutter clean          # 빌드 캐시 정리
flutter doctor         # 개발 환경 체크
flutter test           # 테스트 실행
flutter devices        # 연결된 디바이스 확인
```

### 아이콘 생성
```bash
flutter pub run flutter_launcher_icons
```

### 광고 설정
- **개발 모드**: 자동으로 테스트 광고 ID 사용
- **프로덕션**: pubspec.yaml에서 실제 AdMob ID 설정

## 🎨 디자인 시스템

### UI/UX 특징
- **Material 3** 디자인 시스템
- **오렌지 컬러 스키마** 사용
- **시스템 테마** 지원 (라이트/다크 모드)
- **전체화면** 이미지 디스플레이
- **접근성** 지원 (시맨틱 라벨)

### 애니메이션
- **스케일 애니메이션**: 150ms 터치 피드백
- **전환 애니메이션**: 300ms 화면 전환
- **진동 패턴**: 터치 시 햅틱 피드백

## 📱 앱 버전 정보

- **현재 버전**: 1.0.2+10
- **패키지명**: baldlight
- **설명**: "Bald Collector - A fun flashlight app with entertaining animations."

## 🔧 개발 제약사항

**중요**: 다음 명령어들은 실행하지 마세요:
- `flutter build`
- `flutter run`
- `flutter pub get`

사용자가 직접 처리하는 영역:
- 의존성 설치
- 코드 분석
- 빌드
- 디바이스 테스트
- 앱 실행

## 🧪 테스트 전략

- **위젯 테스트**: UI 컴포넌트 테스트
- **물리 디바이스 필수**: 손전등 기능은 실제 디바이스에서만 작동
- **광고 테스트**: 디버그 모드에서 자동 테스트 광고 단위 사용

## ⚡ 성능 고려사항

- **광고 캐싱**: 4시간 만료 주기
- **응답 시간**: 손전등 토글 <200ms 요구사항
- **메모리 사용량**: 목표 ≤150MB
- **앱 크기**: 목표 ≤20MB

## 🔮 향후 계획

현재 구현은 더 큰 로드맵의 1단계입니다. 계획된 기능들:
- 강화된 컬렉션 시스템
- 추가 대머리 캐릭터 스타일
- 고급 설정 옵션
- Firebase Remote Config를 통한 기능 플래그

서비스 레이어 아키텍처는 주요 리팩토링 없이 이러한 미래 기능들을 수용할 수 있도록 설계되었습니다.

## 📄 라이선스

이 프로젝트는 개인 사용을 위한 것이며 pub.dev에 게시되지 않습니다.
