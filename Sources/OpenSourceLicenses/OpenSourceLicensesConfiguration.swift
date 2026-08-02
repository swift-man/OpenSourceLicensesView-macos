//
//  OpenSourceLicensesConfiguration.swift
//  OpenSourceLicenses
//
//  Created by SwiftMan on 8/2/26.
//

import Foundation

/// 라이선스 화면에서 사용하는 사용자 문구를 호스트 앱이 주입하기 위한 설정입니다.
public struct OpenSourceLicensesConfiguration: Equatable, Sendable {
  /// 화면과 창 탐색 영역에 표시할 제목입니다.
  public let title: String
  /// 주입된 라이선스가 없을 때 표시할 제목입니다.
  public let noLicensesTitle: String
  /// 주입된 라이선스가 없을 때 표시할 안내입니다.
  public let noLicensesMessage: String
  /// 선택 가능한 목록이 있지만 아직 선택하지 않았을 때 표시할 제목입니다.
  public let selectLicenseTitle: String
  /// 선택 가능한 목록이 있지만 아직 선택하지 않았을 때 표시할 안내입니다.
  public let selectLicenseMessage: String

  /// 호스트 앱이 원하는 표시 문구를 구성합니다.
  public init(
    title: String = "Open Source Licenses",
    noLicensesTitle: String = "No Licenses",
    noLicensesMessage: String = "No open source license entries are included.",
    selectLicenseTitle: String = "Select a License",
    selectLicenseMessage: String = "Choose an open source package from the list."
  ) {
    self.title = title
    self.noLicensesTitle = noLicensesTitle
    self.noLicensesMessage = noLicensesMessage
    self.selectLicenseTitle = selectLicenseTitle
    self.selectLicenseMessage = selectLicenseMessage
  }
}
