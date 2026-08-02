# 변경 이력

이 프로젝트의 주요 변경 사항을 이 파일에 기록합니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르고,
버전은 [Semantic Versioning](https://semver.org/lang/ko/spec/v2.0.0.html)을 사용합니다.

## [Unreleased]

## [0.1.0] - 2026-08-02

### Added

- macOS 14 이상에서 사용할 수 있는 Swift 6 `OpenSourceLicenses` 라이브러리 제공
- 외부에서 준비한 라이선스 목록과 원문을 표시하는 `NavigationSplitView` 기반 UI 제공
- `Codable`, `Hashable`, `Identifiable`, `Sendable`을 지원하는 `OpenSourceLicense` 공개 모델 제공
- 호스트 앱이 모든 사용자 표시 문구를 주입할 수 있는 `OpenSourceLicensesConfiguration` 제공
- 빈 목록, 미선택 상태, 목록 교체 후 선택 동기화 처리 제공
- Swift 6.0 최소 툴체인과 현재 macOS 툴체인을 검증하는 GitHub Actions CI 제공
- actionlint 워크플로 린트, 유지보수 스크립트 검사, 버전 추적 자동화 제공
- Dependabot GitHub Actions 업데이트 설정 제공
- MIT License 적용

### Security

- 저장소 링크를 유효한 호스트가 있는 HTTP 또는 HTTPS URL로 제한

[Unreleased]: https://github.com/swift-man/OpenSourceLicensesView-macos/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/swift-man/OpenSourceLicensesView-macos/releases/tag/v0.1.0
