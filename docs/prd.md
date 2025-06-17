# 제품 요구 사항 문서(PRD) – “대머리손전등” 앱

## 1. Executive Summary

“대머리손전등”은 기본 플래시라이트 기능에 유쾌한 애니메이션(대머리에 손전등 비추기)을 결합한 Flutter 기반 모바일 앱이다. 사용자는 손전등을 켜고 끌 때마다 짧고 재미있는 애니메이션을 보며 지루한 플래시 앱 경험을 개선한다. 앱 실행 시마다 전면 광고를 노출하여 수익을 창출하고, 보상형 광고 시청 시 대머리 스타일을 커스터마이즈할 수 있어 수익-재미 균형을 맞춘다.

## 2. Problem Statement

기존 손전등 앱은 단순 기능 제공에 그쳐 사용 경험이 밋밋하고 차별성이 부족하다.  
• 유저는 단순 조명 기능 외 재미 요소를 원하지만 시장에 대안이 거의 없다.  
• 개발사는 광고 수익을 극대화하면서도 사용자 만족도를 유지할 방법이 필요하다.

## 3. Goals and Objectives

- Primary Goal: 기본 손전등 기능과 독특한 애니메이션으로 차별화된 사용자 경험 제공
- Secondary Goals:  
  • 앱 실행 시마다 전면 광고로 안정적 수익 확보  
  • 보상형 광고를 통한 추가 ARPU 및 사용자 참여 증대
- Success Metrics:  
  • D1 Retention ≥ 40%  
  • 평균 세션당 애니메이션 재생 ≥ 3회  
  • 전면 광고 클릭률 ≥ 8%  
  • 보상형 광고 완료율 ≥ 60%

## 4. Target Audience

### Primary Users

- 15–45세, 스마트폰 기본 도구 앱 자주 이용
- 짧은 엔터테인먼트 요소를 선호하는 캐주얼 유저
- 광고 관대도 중간 이상, 무료 앱 선호

### Secondary Users

- 광고주(AdMob)
- 인디 게임/앱 커뮤니티(밈, 리뷰 등)

## 5. User Stories

- 사용자로서 손전등을 켤 때 재미있는 애니메이션을 보고 싶다, 그래서 지루하지 않다.
- 사용자로서 손전등 앱을 무료로 이용하고 싶다, 그래서 추가 지출 없이 편리함을 얻는다.
- 사용자로서 광고를 보면 대머리 스타일을 바꾸고 싶다, 그래서 나만의 재미를 느낀다.
- 제품 매니저로서 앱 실행 시마다 전면 광고 노출로 수익을 확보하고 싶다, 그래서 운영비를 충당한다.

## 6. Functional Requirements

### Core Features

1. 손전등 ON/OFF
   - 플래시 하드웨어 제어 (iOS, Android)
   - Acceptance: 버튼 클릭 시 200ms 이내 플래시 상태 변경
2. 대머리 애니메이션
   - 손전등 상태 변화마다 0.5초 영상/GIF 재생
   - 음소거 옵션 포함
   - Acceptance: 98% 이상 무결 재생, ON/OFF 동기화
3. 전면 광고(AdMob)
   - 앱 실행 시마다 1회 노출
   - 광고 닫기 후 메인 화면 로드
   - Acceptance: 광고 실패 시 메인 화면 2초 이내 로드

### Supporting Features

- 설정 화면: 애니메이션 볼륨, 진동 여부, 평가하기 링크
- 보상형 광고(AdMob Rewarded)  
  • 광고 시청 완료 시 대머리 스타일 스킨(모자, 무늬 등) 해제  
  • 인벤토리 최대 5종, 로컬 저장
- 다크모드 자동 연동
- 간단한 튜토리얼(3장) & 스킵 가능

## 7. Non-Functional Requirements

- Performance: 앱 크기 ≤ 15 MB, 메모리 사용 ≤ 150 MB, 애니 재생 FPS ≥ 30
- Security: 최소 권한(카메라/플래시), GDPR·CCPA 광고 동의 플로우
- Usability: 1-Tap ON/OFF, 애니메이션 중 터치 가능
- Scalability: 광고/애니메이션 리소스 원격 업데이트 지원
- Compatibility: Android 8.0+, iOS 13+, 주요 해상도 90% 커버

## 8. Technical Considerations

- Architecture: Flutter + Dart, BLoC 상태 관리
- 애니메이션: Lottie/MP4, A/B 테스트 가능
- Analytics: Firebase Analytics & Crashlytics
- Ad SDK: Google AdMob (Interstitial, Rewarded)
- Remote Config: Firebase Remote Config로 버전별 광고 빈도 조절

## 9. Success Metrics and KPIs

- UX: 평균 세션 길이 ≥ 45초, NPS ≥ 20
- Business: eCPM ≥ $5, 월 광고 수익 ≥ $5K, 보상 광고 ARPU ≥ $0.20
- Technical: Crash-Free Rate ≥ 99.5%, 첫 로드 시간 ≤ 1.5초

## 10. Timeline and Milestones

- Phase 1 (4주):  
  • 기본 플래시 제어, 대머리 애니메이션, 전면 광고, MVP 출시
- Phase 2 (3주):  
  • 보상형 광고 + 대머리 스타일, 설정 화면, 다크모드
- Phase 3 (2주):  
  • A/B 테스트, 리모트 업데이트, 글로벌 현지화(영/한)
- Launch + Marketing: 1주 (SNS 밈 캠페인)

## 11. Risks and Mitigation

- 광고 거부감 → 광고 빈도 최소화, PRO(유료 제거) 향후 고려
- 하드웨어 호환 이슈 → 기종별 QA, 플래시 미지원 시 화면 흰색 대체
- 밈 컨텐츠 단기 흥미 → 지속적 스타일 업데이트(월 1회)

## 12. Future Considerations

- PRO 버전: 광고 제거, 추가 스타일 팩 판매(IAP)
- AR 기능: 실시간 얼굴 인식으로 사용자 머리에 빔 투사
- 커뮤니티 공유: 애니메이션 캡처를 SNS로 공유해 자연 유입 확대
