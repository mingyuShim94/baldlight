# Bald Collector 앱 배포 자동화 가이드

## 개요
Bald Collector 앱의 Codemagic을 이용한 CI/CD 파이프라인 설정 및 배포 가이드입니다.

## 🚀 Codemagic 설정

### 1. Codemagic 계정 설정
1. [Codemagic](https://codemagic.io) 계정 생성
2. GitHub 리포지토리 연결
3. Bald Collector 프로젝트 추가

### 2. 환경 변수 설정

#### Android 배포용 환경 변수
Codemagic 대시보드 → Settings → Environment variables에서 다음 변수들을 설정:

```
# Android Keystore
CM_KEYSTORE_PASSWORD=agic3782
CM_KEY_PASSWORD=agic3782
CM_KEY_ALIAS=baldlight-key
CM_KEYSTORE_PATH=/path/to/baldlight-release-key.jks

# Google Play Console
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS=[JSON 형태의 서비스 계정 키]
```

#### iOS 배포용 환경 변수
```
# Apple Developer
CM_TEAM_ID=[Apple Developer Team ID]
CM_PROVISIONING_PROFILE=[Provisioning Profile 이름]

# App Store Connect
APP_STORE_CONNECT_ISSUER_ID=[App Store Connect API 발급자 ID]
APP_STORE_CONNECT_KEY_IDENTIFIER=[API 키 식별자]
APP_STORE_CONNECT_PRIVATE_KEY=[API 개인 키]
```

### 3. 서명 및 인증서 설정

#### Android
1. Codemagic → Settings → Code signing identities
2. Android keystores → Upload keystore
3. `android/app/baldlight-release-key.jks` 파일 업로드
4. 별칭: `baldlight_keystore`

#### iOS
1. Apple Developer 계정과 Codemagic 연동
2. Automatic code signing 활성화
3. Bundle ID: `com.gguggulab.baldlight`

## 📱 배포 워크플로우

### 워크플로우 종류
1. **dev-workflow**: 개발 빌드 (main, develop 브랜치 푸시 시)
2. **android-workflow**: Android 프로덕션 배포 (태그 푸시 시)
3. **ios-workflow**: iOS 프로덕션 배포 (태그 푸시 시)

### 배포 트리거
```bash
# 새 버전 태그 생성 및 푸시
git tag v1.0.1
git push origin v1.0.1
```

## 🔧 설정 파일 구조

```
.codemagic/
├── android/
│   └── keystore.properties      # Android 키 스토어 설정
├── ios/
│   └── export_options.plist     # iOS 내보내기 옵션
└── scripts/
    ├── setup_environment.sh     # 환경 설정 스크립트
    └── post_build.sh           # 빌드 후 처리 스크립트
```

## 📋 빌드 과정

### Android 빌드 과정
1. 환경 설정 (`setup_environment.sh`)
2. Flutter 의존성 설치 (`flutter pub get`)
3. 코드 분석 (`flutter analyze`)
4. APK 빌드 (`flutter build apk --release`)
5. AAB 빌드 (`flutter build appbundle --release`)
6. Google Play Console 업로드
7. 빌드 후 처리 (`post_build.sh`)

### iOS 빌드 과정
1. 환경 설정
2. 코드 서명 설정 (`xcode-project use-profiles`)
3. Flutter 의존성 설치
4. Pod 설치 (`pod install`)
5. 코드 분석
6. IPA 빌드 (`flutter build ipa --release`)
7. TestFlight 업로드
8. 빌드 후 처리

## 🎯 배포 전략

### 내부 테스트 (기본 설정)
- **Android**: Google Play Console Internal Testing
- **iOS**: TestFlight Beta Testing

### 프로덕션 배포
`codemagic.yaml`에서 다음 설정 변경:
```yaml
# Android
GOOGLE_PLAY_TRACK: production

# iOS
submit_to_app_store: true
```

## 📊 모니터링 및 알림

### 빌드 상태 알림
- 이메일 알림: `gguggulab@gmail.com`
- 성공/실패 시 자동 알림

### 빌드 결과물
- **Android**: APK, AAB 파일
- **iOS**: IPA 파일
- **공통**: 빌드 로그, 매핑 파일

## 🔍 문제 해결

### 일반적인 문제들

1. **키 스토어 오류**
   - 환경 변수 확인
   - 키 스토어 파일 경로 확인

2. **iOS 서명 오류**
   - Apple Developer 계정 상태 확인
   - Provisioning Profile 유효성 확인

3. **빌드 타임아웃**
   - `max_build_duration` 값 증가 (현재 60분)

4. **의존성 오류**
   - Flutter 버전 호환성 확인
   - `flutter clean` 후 재빌드

### 로그 확인
1. Codemagic 대시보드에서 빌드 로그 확인
2. `flutter_drive.log` 파일 다운로드
3. 빌드 결과 보고서 확인

## 🚀 고급 설정

### 커스텀 빌드 스크립트
빌드 과정을 커스터마이징하려면 `.codemagic/scripts/` 디렉토리의 스크립트들을 수정하세요.

### 다중 환경 배포
개발/스테이징/프로덕션 환경별로 다른 워크플로우를 구성할 수 있습니다.

### 자동 버전 관리
`pubspec.yaml`의 버전을 자동으로 증가시키는 스크립트를 추가할 수 있습니다.

## 📞 지원

문제가 발생하거나 추가 설정이 필요한 경우:
1. Codemagic 공식 문서 확인
2. Flutter 공식 배포 가이드 참조
3. GitHub Issues를 통한 문의

---

**주의사항**: 
- 민감한 정보(API 키, 비밀번호)는 절대 코드에 포함하지 마세요
- 모든 중요한 설정은 Codemagic 환경 변수로 관리하세요
- 배포 전 충분한 테스트를 진행하세요