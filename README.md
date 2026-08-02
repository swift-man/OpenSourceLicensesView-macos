# OpenSourceLicenses

[![CI](https://github.com/swift-man/OpenSourceLicensesView-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-man/OpenSourceLicensesView-macos/actions/workflows/ci.yml)

외부에서 준비한 오픈소스 라이선스 목록을 macOS `NavigationSplitView`로 표시하는 Swift Package입니다.

패키지는 JSON 파일, 앱 번들, 로딩 정책을 소유하지 않습니다. 호스트 앱이 데이터를 로딩하고 현지화한 표시 문구와 함께 주입합니다.

```swift
import OpenSourceLicenses

let licenses = try JSONDecoder().decode(
  [OpenSourceLicense].self,
  from: licenseData
)

OpenSourceLicensesView(
  licenses: licenses,
  configuration: OpenSourceLicensesConfiguration(
    title: "오픈 소스 라이선스",
    noLicensesTitle: "라이선스 없음",
    noLicensesMessage: "포함된 라이선스가 없습니다.",
    selectLicenseTitle: "라이선스 선택",
    selectLicenseMessage: "목록에서 패키지를 선택하세요."
  )
)
```

## 요구 사항

- macOS 14 이상
- Swift 5.9 이상

CI는 지원 중인 macOS runner에 Swift 5.9.2 툴체인을 설치해 최소 지원 Swift 버전에서 빌드와 테스트를 검증합니다.

## 라이선스

이 패키지는 [MIT License](LICENSE)로 배포됩니다.
