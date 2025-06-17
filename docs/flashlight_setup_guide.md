# 플래시라이트 하드웨어 제어 구현 가이드

## 개요

이 문서는 Flutter 앱에서 iOS/Android 플래시라이트 하드웨어 제어를 위한 구현 사항을 설명합니다.

## 구현된 기능

### 1. 플래시라이트 제어 서비스 (`lib/services/flashlight_service.dart`)

- **플래시라이트 지원 여부 확인**: 기기에서 플래시라이트를 지원하는지 확인
- **플래시라이트 ON/OFF 제어**: 안전한 플래시라이트 켜기/끄기 기능
- **상태 관리**: 현재 플래시라이트 상태 추적
- **예외 처리**: 다양한 에러 상황에 대한 안전한 처리
- **싱글톤 패턴**: 앱 전체에서 하나의 인스턴스만 사용

### 2. 사용자 정의 예외 클래스

- `FlashlightException`: 기본 예외 클래스
- `FlashlightNotSupportedException`: 플래시라이트 미지원 기기 예외
- `FlashlightInUseException`: 카메라 사용 중 예외

### 3. 테스트 UI (`lib/main.dart`)

- 플래시라이트 상태 시각적 표시
- 원터치 켜기/끄기 버튼
- 지원 여부 확인 기능
- 상세한 에러 메시지 표시

## 권한 설정

### Android 권한 (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- 플래시라이트 권한 -->
<uses-permission android:name="android.permission.FLASHLIGHT" />
<uses-permission android:name="android.permission.CAMERA" />

<!-- 하드웨어 기능 (선택적) -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.flash" android:required="false" />
```

### iOS 권한 (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to control the flashlight.</string>
```

### Android SDK 요구사항 (`android/app/build.gradle`)

```gradle
defaultConfig {
    minSdk = 23  // torch_light 플러그인 요구사항
    // ...
}
```

## 사용된 플러그인

### torch_light ^1.1.0

- **장점**:
  - 검증된 퍼블리셔 (verified publisher)
  - 안정적이고 널리 사용됨 (55+ likes, 18K+ downloads)
  - Dart 3 호환성 및 null safety 지원
  - 간단하고 명확한 API
- **기능**:
  - 플래시라이트 지원 여부 확인
  - 플래시라이트 켜기/끄기
  - 다양한 예외 상황 처리

## 실제 기기 테스트 방법

### 1. 개발 환경 준비

```bash
# 종속성 설치
flutter pub get

# Android 빌드 확인
flutter build apk --debug

# iOS 빌드 확인 (macOS에서만)
flutter build ios --debug --no-codesign
```

### 2. 실기기 연결 및 실행

```bash
# 연결된 기기 확인
flutter devices

# Android 기기에서 실행
flutter run -d <android_device_id>

# iOS 기기에서 실행
flutter run -d <ios_device_id>
```

### 3. 테스트 시나리오

#### 기본 기능 테스트

1. **앱 실행**: 플래시라이트 지원 여부 자동 확인
2. **플래시라이트 켜기**: "플래시라이트 켜기" 버튼 탭
3. **플래시라이트 끄기**: "플래시라이트 끄기" 버튼 탭
4. **상태 확인**: UI에서 현재 상태 표시 확인

#### 예외 상황 테스트

1. **미지원 기기**: 플래시라이트가 없는 기기에서 테스트
2. **카메라 사용 중**: 다른 앱에서 카메라 사용 중일 때 테스트
3. **권한 거부**: 카메라 권한을 거부한 상태에서 테스트

### 4. 예상 동작

#### 정상 동작

- ✅ 플래시라이트 지원 기기에서 즉시 켜짐/꺼짐
- ✅ 200ms 이내 응답 (PRD 요구사항)
- ✅ 상태 변화에 따른 UI 업데이트
- ✅ 앱 종료시 자동으로 플래시라이트 끄기

#### 예외 처리

- ❌ 미지원 기기: "플래시라이트를 지원하지 않습니다" 메시지
- ❌ 권한 없음: 권한 요청 또는 에러 메시지
- ❌ 카메라 사용 중: "다른 앱에서 카메라 사용 중" 메시지

## 다음 단계 (PRD Phase 1 완료를 위해)

### 1. 대머리 애니메이션 추가

- Lottie 또는 GIF 애니메이션 통합
- 플래시라이트 상태 변화에 따른 애니메이션 재생

### 2. 전면 광고 통합

- AdMob SDK 추가
- 앱 실행시 전면 광고 표시

### 3. 사용자 경험 개선

- 햅틱 피드백 추가
- 사운드 효과 (선택적)
- 다크모드 지원

### 4. 성능 최적화

- 배터리 사용량 모니터링
- 메모리 사용량 최적화

## 트러블슈팅

### 일반적인 문제

#### Android

1. **minSdkVersion 에러**:
   - 해결책: `android/app/build.gradle`에서 `minSdk = 23` 설정
2. **권한 에러**:
   - 해결책: AndroidManifest.xml 권한 확인
3. **빌드 실패**:
   - 해결책: `flutter clean && flutter pub get` 후 재빌드

#### iOS

1. **카메라 권한 에러**:
   - 해결책: Info.plist에 NSCameraUsageDescription 추가
2. **시뮬레이터에서 테스트 불가**:
   - 해결책: 실제 iOS 기기에서만 테스트 가능

### 디버깅 팁

- 콘솔 로그 확인: `flutter logs`
- 권한 상태 확인: 기기 설정 > 앱 > 권한
- 하드웨어 지원 확인: 기기 사양 문서 참조

## 결론

플래시라이트 하드웨어 제어 기능이 성공적으로 구현되었습니다. 실제 기기에서 테스트를 진행하여 PRD의 Acceptance Criteria를 만족하는지 확인하시기 바랍니다.
