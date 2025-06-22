# Product Requirements Document

## 1. Executive Summary

대머리 클리커 앱은 10대 사용자가 화면을 탭하여 ‘대머리’를 때리는 재미를 느끼며 수집·성장 요소와 광고 기반 보상을 경험할 수 있는 모바일 클리커 게임이다. 간단한 조작, 수집 욕구 자극, 피버타임으로 인한 몰입도를 통해 이용자 체류 시간을 극대화하고, 광고 수익을 창출한다.

## 2. Problem Statement

• 10대 사용자는 짧은 시간 동안 즉각적 재미와 성취감을 주는 가벼운 게임을 원한다.  
• 기존 클리커 게임은 단순 반복이 금방 지루해지고, 수집 요소가 부족하거나 광고 보상 경험이 단절적이다.  
• 시장에는 ‘두드리기’ 테마는 많으나 개성 있는 소재(대머리)에 집중한 게임은 드물어 차별화 기회가 있다.

## 3. Goals and Objectives

- Primary Goal: 탭 기반 대머리 타격·수집 게임 출시로 DAU 5만, ARPDAU 0.15달러 달성(6개월).
- Secondary Goals:  
  • 평균 세션 길이 5분 이상 유지  
  • 광고 시청 완료율 70% 이상  
  • 사용자 평점 4.3/5 이상(구글 플레이)
- Success Metrics: DAU, ARPDAU, 평균 세션 길이, 광고 시청 완료율, 리텐션(D1 45%, D7 15%)

## 4. Target Audience

### Primary Users

- 10대(13–19세) 모바일 게이머
- 짧은 시간에 즉각적 보상을 받고 싶어함
- 밈·코믹 요소 선호, 광고 수용도 높음

### Secondary Users

- 광고주(AdMob)
- 스트리머·SNS 인플루언서(콘텐츠 재료)
- 학부모(결제·설치 허가자)

## 5. User Stories

- “10대 유저로서, 대머리를 탭해 시원한 타격 효과를 느껴 스트레스를 풀고 싶다.”
- “수집가 유저로서, 일정 횟수마다 새로운 대머리를 얻어 모으는 재미를 느끼고 싶다.”
- “경쟁 유저로서, 친구보다 많은 타격 수를 기록해 랭킹에서 앞서고 싶다.”
- “무과금 유저로서, 광고를 시청해 피버타임 혜택을 얻어 빠르게 성장하고 싶다.”

## 6. Functional Requirements

### Core Features

1. 기본 타격
   - 화면 탭 시 손바닥 이미지가 0.2초간 대머리 위에 오버레이 후 사라짐
   - 타격당 ‘딱’ 효과음(모든 대머리 동일 효과음 사용, 효과음 커스터마이징은 추후 검토)
   - 카운트 +1
   - FPS 60 기준 5ms 이내 입력 반응
2. 대머리 수집·교체
   - 누적 타격 수가 목표치 도달 시 랜덤 대머리 획득(희귀도 구분은 MVP에서는 적용하지 않음)
   - 보유한 대머리 목록 UI, 탭으로 선택 교체
   - 각 대머리마다 고유 스킨(효과음은 통일)
3. 피버타임(광고 보상)
   - AdMob 리워드 동영상 15~30초 시청 → 3분간 카운트 x2, 손바닥 2개 애니메이션
   - 피버타임 남은 시간 HUD 표시
   - 피버타임 중 광고 버튼 비활성화
4. 통계·랭킹
   - 총 타격 수, 일일 타격 수, 최고 연속 타격 표시
   - (랭킹 시스템은 MVP에서는 제외, DB 연동 보류)

### Supporting Features

- 진동 피드백 ON/OFF
- 배경음·효과음 볼륨 조절
- 신규 대머리 알림 뱃지
- 인앱 공지(이벤트/업데이트)
- 스크린샷 공유(소셜 버즈 유도)

## 7. Non-Functional Requirements

- Performance: ≤50 MB APK, 메모리 300 MB 이내, 2GB RAM 기기서 60FPS
- Security: 구글 플레이 결제 및 AdMob 정책 준수, 개인정보 수집 없음
- Usability: 3탭 이내 주요 기능 접근, 1분 튜토리얼
- Scalability: 신규 대머리·이벤트 데이터 원격 JSON 업데이트
- Compatibility: Android 8.0+, iOS 13+ (선출시는 Android)
- **Localization: 첫 출시는 영어만 지원 (다국어 지원은 추후 도입 검토)**

## 8. Technical Considerations

- Architecture: Flutter + Dart, Clean Architecture, BLoC 패턴
- Ads: Google AdMob(Rewarded, Interstitial)
- Data: Local SQLite (랭킹 및 서버 DB 연동은 MVP에서는 보류)
- Assets: Spine 애니메이션, MP3 효과음(효과음은 대머리별로 통일)
- CI/CD: GitHub Actions → Firebase App Distribution
- Third-party: Firebase Analytics, Crashlytics

## 9. Success Metrics and KPIs

- DAU, MAU
- ARPDAU, 광고 노출수·eCPM
- 평균 세션 길이, 세션/일
- D1/D7/D30 리텐션
- 앱 평점, 오류율(Crash Free 99.5%)

## 10. Timeline and Milestones

- Phase 1 (M1): 기획 확정, UI/UX 와이어프레임, 핵심 타격·카운트 구현
- Phase 2 (M2): 대머리 수집 로직, 기본 10종 대머리 아트 완료
- Phase 3 (M3): 광고 연동, 피버타임, 통계
- Phase 4 (M4): QA, 퍼포먼스 최적화, 스토어 심사 제출
- Soft Launch (M5): 주요 시장 3개국, 지표 모니터링·AB 테스트
- Global Launch (M6): iOS 병행 출시, 마케팅 캠페인 시작

## 11. Risks and Mitigation

- 기술: 저사양 기기 프레임 드랍 → 애셋 압축·LOD 적용
- 비즈니스: 광고 차단 앱 사용 증가 → 인앱 구매형 광고 제거권 도입 고려
- 사용자: 소재(대머리)로 인한 불쾌감 → 코믹·긍정 톤 유지, 신고/차단 기능 제공

## 12. Future Considerations

- PvP 실시간 ‘대머리 배틀’ 모드
- 스킨 합성·강화 시스템
- 시즌 패스(프리미엄 수익)
- WebGL 버전(브라우저 데모)
- 캐릭터 IP 콜라보(유명 밈, 크리에이터)
- 대머리 희귀도, 대머리별 효과음 및 랭킹 시스템(추후 도입 검토)
