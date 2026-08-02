//
//  OpenSourceLicense.swift
//  OpenSourceLicenses
//
//  Created by SwiftMan on 8/2/26.
//

import Foundation

/// 오픈소스 패키지 목록과 라이선스 전문에 표시할 단일 항목입니다.
public struct OpenSourceLicense: Codable, Hashable, Identifiable, Sendable {
  /// 목록 선택과 SwiftUI diff에 사용하는 고유 식별자입니다.
  public let id: String
  /// 사용자에게 표시할 패키지 이름입니다.
  public let name: String
  /// 앱이 실제로 포함한 패키지 버전입니다.
  public let version: String
  /// 원본 소스와 저작권 정보를 확인할 수 있는 저장소 주소입니다.
  public let repositoryURL: String
  /// MIT, Apache-2.0 등 라이선스의 표시 이름입니다.
  public let licenseName: String
  /// 원본 패키지에서 라이선스 전문을 가져온 파일 이름입니다.
  public let licenseFileName: String
  /// 상세 화면에서 그대로 표시할 라이선스 전문입니다.
  public let licenseText: String

  /// 외부 데이터 소스가 준비한 라이선스 정보를 생성합니다.
  public init(
    id: String,
    name: String,
    version: String,
    repositoryURL: String,
    licenseName: String,
    licenseFileName: String,
    licenseText: String
  ) {
    self.id = id
    self.name = name
    self.version = version
    self.repositoryURL = repositoryURL
    self.licenseName = licenseName
    self.licenseFileName = licenseFileName
    self.licenseText = licenseText
  }
}
