# 대머리손전등 (BaldLight) 📱💡

기본 플래시라이트 기능에 유쾌한 대머리 애니메이션을 결합한 Flutter 기반 모바일 앱입니다.  
손전등을 켜고 끌 때마다 재미있는 애니메이션을 통해 지루한 플래시 앱 경험을 개선합니다.

## ✨ 주요 기능

- 🔦 **기본 손전등 기능**: iOS/Android 플래시 하드웨어 제어
- 🎭 **대머리 애니메이션**: 손전등 ON/OFF 시마다 재미있는 0.5초 애니메이션 재생
- 💰 **광고 기반 수익화**:
  - 앱 실행 시 전면 광고 (AdMob Interstitial)
  - 보상형 광고를 통한 대머리 스타일 커스터마이징
- ⚙️ **설정 옵션**: 애니메이션 볼륨, 진동 설정, 다크모드 지원
- 🎨 **스타일 시스템**: 광고 시청으로 해제 가능한 5가지 대머리 스타일

## 🎯 타겟 사용자

- 15-45세 스마트폰 사용자
- 캐주얼 엔터테인먼트를 선호하는 사용자
- 무료 앱을 선호하며 광고에 관대한 사용자

## 🛠 기술 스택

- **Framework**: Flutter + Dart
- **상태 관리**: BLoC Pattern
- **애니메이션**: Lottie/MP4
- **광고**: Google AdMob (Interstitial, Rewarded)
- **분석**: Firebase Analytics & Crashlytics
- **원격 설정**: Firebase Remote Config

## 📱 지원 플랫폼

- **Android**: 8.0+ (API Level 26+)
- **iOS**: 13.0+
- **주요 해상도**: 90% 커버리지

## 🚀 시작하기

### 필수 요구사항

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode
- Firebase 프로젝트 설정

### 설치 및 실행

1. **저장소 클론**

   ```bash
   git clone https://github.com/your-username/baldlight.git
   cd baldlight
   ```

2. **의존성 설치**

   ```bash
   flutter pub get
   ```

3. **Firebase 설정**

   - Firebase 콘솔에서 프로젝트 생성
   - `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 추가
   - AdMob 광고 단위 ID 설정

4. **앱 실행**
   ```bash
   flutter run
   ```

### 환경 설정

Firebase 및 AdMob 설정을 위해 다음 파일들을 확인하세요:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- AdMob 광고 단위 ID 설정

## 📊 성과 지표

### 사용자 경험

- D1 Retention ≥ 40%
- 평균 세션당 애니메이션 재생 ≥ 3회
- 평균 세션 길이 ≥ 45초

### 비즈니스

- 전면 광고 클릭률 ≥ 8%
- 보상형 광고 완료율 ≥ 60%
- eCPM ≥ $5

### 기술적 성능

- 앱 크기 ≤ 15 MB
- 메모리 사용 ≤ 150 MB
- Crash-Free Rate ≥ 99.5%

## 🗺 로드맵

### Phase 1 (완료) - MVP

- [x] 기본 플래시 제어
- [x] 대머리 애니메이션
- [x] 전면 광고 통합

### Phase 2 (진행 중)

- [ ] 보상형 광고 + 스타일 시스템
- [ ] 설정 화면
- [ ] 다크모드 지원

### Phase 3 (계획)

- [ ] A/B 테스트 구현
- [ ] 원격 업데이트 시스템
- [ ] 다국어 지원 (영어/한국어)

### 향후 계획

- [ ] PRO 버전 (광고 제거)
- [ ] AR 기능 (실시간 얼굴 인식)
- [ ] 커뮤니티 공유 기능

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

프로젝트 관련 문의: [your-email@example.com]

프로젝트 링크: [https://github.com/your-username/baldlight](https://github.com/your-username/baldlight)

---

**"대머리손전등"** - 단순한 손전등이 아닌, 재미있는 경험을 제공하는 앱! 🎉
