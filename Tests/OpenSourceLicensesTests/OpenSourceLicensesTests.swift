//
//  OpenSourceLicensesTests.swift
//  OpenSourceLicensesTests
//
//  Created by SwiftMan on 8/2/26.
//

import Foundation
import XCTest

@testable import OpenSourceLicenses

final class OpenSourceLicensesTests: XCTestCase {
  /// 외부 JSON을 공개 모델로 디코딩해 뷰에 주입할 수 있는지 확인합니다.
  func testDecodesExternallyProvidedLicense() throws {
    let data = Data(
      """
      [
        {
          "id": "sample",
          "name": "Sample",
          "version": "1.0.0",
          "repositoryURL": "https://example.com/sample",
          "licenseName": "MIT License",
          "licenseFileName": "LICENSE",
          "licenseText": "Permission is hereby granted."
        }
      ]
      """.utf8
    )

    let licenses = try JSONDecoder().decode([OpenSourceLicense].self, from: data)

    XCTAssertEqual(licenses.count, 1)
    XCTAssertEqual(licenses.first?.id, "sample")
    XCTAssertEqual(licenses.first?.licenseName, "MIT License")
  }

  /// 필수 필드가 빠진 외부 JSON을 잘못된 모델로 받아들이지 않는지 확인합니다.
  func testRejectsIncompleteExternalLicense() {
    let data = Data(
      """
      [
        {
          "id": "sample",
          "name": "Sample"
        }
      ]
      """.utf8
    )

    XCTAssertThrowsError(
      try JSONDecoder().decode([OpenSourceLicense].self, from: data)
    ) { error in
      XCTAssertTrue(error is DecodingError)
    }
  }

  /// 공개 초기화가 모든 표시 필드를 손실 없이 보존하는지 확인합니다.
  func testInitializesPublicLicenseFields() {
    let license = makeLicense(id: "sample")

    XCTAssertEqual(license.id, "sample")
    XCTAssertEqual(license.name, "Sample")
    XCTAssertEqual(license.version, "1.0.0")
    XCTAssertEqual(license.repositoryURL, "https://example.com/sample")
    XCTAssertEqual(license.licenseName, "MIT License")
    XCTAssertEqual(license.licenseFileName, "LICENSE")
    XCTAssertEqual(license.licenseText, "Permission is hereby granted.")
  }

  /// 호스트 앱이 화면의 모든 사용자 문구를 현지화해 주입할 수 있는지 확인합니다.
  func testStoresExternallyProvidedDisplayStrings() {
    let configuration = OpenSourceLicensesConfiguration(
      title: "오픈 소스 라이선스",
      noLicensesTitle: "라이선스 없음",
      noLicensesMessage: "포함된 라이선스가 없습니다.",
      selectLicenseTitle: "라이선스 선택",
      selectLicenseMessage: "목록에서 패키지를 선택하세요."
    )

    XCTAssertEqual(configuration.title, "오픈 소스 라이선스")
    XCTAssertEqual(configuration.noLicensesTitle, "라이선스 없음")
    XCTAssertEqual(configuration.noLicensesMessage, "포함된 라이선스가 없습니다.")
    XCTAssertEqual(configuration.selectLicenseTitle, "라이선스 선택")
    XCTAssertEqual(configuration.selectLicenseMessage, "목록에서 패키지를 선택하세요.")
  }

  /// 기본 설정도 별도 리소스 없이 완전한 영어 문구를 제공하는지 확인합니다.
  func testDefaultDisplayStrings() {
    let configuration = OpenSourceLicensesConfiguration()

    XCTAssertEqual(configuration.title, "Open Source Licenses")
    XCTAssertEqual(configuration.noLicensesTitle, "No Licenses")
    XCTAssertEqual(configuration.noLicensesMessage, "No open source license entries are included.")
    XCTAssertEqual(configuration.selectLicenseTitle, "Select a License")
    XCTAssertEqual(configuration.selectLicenseMessage, "Choose an open source package from the list.")
  }

  /// 목록 갱신 후에도 유효한 기존 선택은 그대로 유지하는지 확인합니다.
  func testPreservesValidSelection() {
    let licenses = [makeLicense(id: "first"), makeLicense(id: "selected")]

    XCTAssertEqual(synchronizedLicenseSelection("selected", with: licenses), "selected")
  }

  /// 없어진 선택은 새 목록의 첫 항목으로 복구하는지 확인합니다.
  func testReplacesStaleSelectionWithFirstLicense() {
    let licenses = [makeLicense(id: "first"), makeLicense(id: "second")]

    XCTAssertEqual(synchronizedLicenseSelection("removed", with: licenses), "first")
    XCTAssertEqual(synchronizedLicenseSelection(nil, with: licenses), "first")
  }

  /// 빈 목록은 유효한 선택을 만들 수 없으므로 `nil`을 반환하는지 확인합니다.
  func testClearsSelectionForEmptyLicenseList() {
    XCTAssertNil(synchronizedLicenseSelection("removed", with: []))
  }

  /// 대소문자와 관계없이 HTTP(S) 저장소 주소만 링크로 허용하는지 확인합니다.
  func testAcceptsHTTPRepositoryURLs() {
    XCTAssertNotNil(openSourceLicenseRepositoryURL(from: "https://example.com/package"))
    XCTAssertNotNil(openSourceLicenseRepositoryURL(from: "HTTP://example.com/package"))
  }

  /// 외부 앱을 열 수 있는 링크는 HTTP(S) 스킴으로 제한하는지 확인합니다.
  func testRejectsUnsupportedRepositoryURLs() {
    XCTAssertNil(openSourceLicenseRepositoryURL(from: "ftp://example.com/package"))
    XCTAssertNil(openSourceLicenseRepositoryURL(from: "example.com/package"))
    XCTAssertNil(openSourceLicenseRepositoryURL(from: "https://exa mple.com"))
    XCTAssertNil(openSourceLicenseRepositoryURL(from: "https://"))
    XCTAssertNil(openSourceLicenseRepositoryURL(from: "https:///package"))
  }
}

private extension OpenSourceLicensesTests {
  /// 선택과 URL 검증 테스트에서 사용할 일관된 라이선스 픽스처를 만듭니다.
  func makeLicense(id: String) -> OpenSourceLicense {
    OpenSourceLicense(
      id: id,
      name: "Sample",
      version: "1.0.0",
      repositoryURL: "https://example.com/sample",
      licenseName: "MIT License",
      licenseFileName: "LICENSE",
      licenseText: "Permission is hereby granted."
    )
  }
}
