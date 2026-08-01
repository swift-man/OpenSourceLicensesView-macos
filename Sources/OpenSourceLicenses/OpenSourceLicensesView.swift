//
//  OpenSourceLicensesView.swift
//  OpenSourceLicenses
//
//  Created by SwiftMan on 8/2/26.
//

import SwiftUI

/// 외부에서 주입한 오픈소스 패키지 목록과 선택한 라이선스 전문을 표시합니다.
public struct OpenSourceLicensesView: View {
  /// 호스트 앱이 로딩과 검증을 마친 라이선스 목록입니다.
  private let licenses: [OpenSourceLicense]
  /// 호스트 앱이 현지화하거나 변경한 화면 문구입니다.
  private let configuration: OpenSourceLicensesConfiguration

  /// 좌측 목록에서 선택한 라이선스 ID입니다.
  @State
  private var selection: OpenSourceLicense.ID?

  /// 외부에서 준비한 라이선스 목록과 표시 문구로 화면을 구성합니다.
  ///
  /// 각 라이선스의 `id`는 목록 안에서 고유해야 합니다.
  public init(
    licenses: [OpenSourceLicense],
    configuration: OpenSourceLicensesConfiguration = .init()
  ) {
    self.licenses = licenses
    self.configuration = configuration
    _selection = State(initialValue: licenses.first?.id)
  }

  /// 좌측 패키지 목록과 우측 상세 콘텐츠를 macOS split view로 구성합니다.
  public var body: some View {
    NavigationSplitView {
      licenseList
    } detail: {
      licenseDetail
    }
    .navigationTitle(configuration.title)
    .onChange(of: licenses) { _, updatedLicenses in
      synchronizeSelection(with: updatedLicenses)
    }
  }
}

private extension OpenSourceLicensesView {
  /// 현재 선택 ID와 일치하는 라이선스입니다.
  var selectedLicense: OpenSourceLicense? {
    licenses.first { $0.id == selection }
  }

  /// 외부 목록이 교체되면 유효한 기존 선택을 유지하고 없어진 선택만 첫 항목으로 보정합니다.
  func synchronizeSelection(with updatedLicenses: [OpenSourceLicense]) {
    selection = synchronizedLicenseSelection(selection, with: updatedLicenses)
  }

  /// 패키지 목록과 빈 목록 안내를 표시합니다.
  var licenseList: some View {
    List(licenses, selection: $selection) { license in
      OpenSourceLicenseRowView(license: license)
        .tag(license.id)
    }
    .navigationSplitViewColumnWidth(min: 260, ideal: 300)
    .overlay {
      if licenses.isEmpty {
        OpenSourceLicensePlaceholderView(
          title: configuration.noLicensesTitle,
          systemImage: "doc.text.magnifyingglass",
          message: configuration.noLicensesMessage
        )
      }
    }
  }

  /// 선택 상태에 맞는 라이선스 상세 또는 안내 화면을 반환합니다.
  @ViewBuilder
  var licenseDetail: some View {
    if let selectedLicense {
      OpenSourceLicenseDetailView(license: selectedLicense)
    } else if licenses.isEmpty {
      OpenSourceLicensePlaceholderView(
        title: configuration.noLicensesTitle,
        systemImage: "doc.text.magnifyingglass",
        message: configuration.noLicensesMessage
      )
    } else {
      OpenSourceLicensePlaceholderView(
        title: configuration.selectLicenseTitle,
        systemImage: "doc.text",
        message: configuration.selectLicenseMessage
      )
    }
  }
}

/// 라이선스 화면의 빈 목록과 미선택 상태를 일관된 형식으로 보여주는 안내 뷰입니다.
private struct OpenSourceLicensePlaceholderView: View {
  /// 안내 상태의 제목입니다.
  let title: String
  /// 안내 상태를 상징하는 SF Symbol 이름입니다.
  let systemImage: String
  /// 사용자가 다음 상태를 이해할 수 있도록 제공하는 보조 설명입니다.
  let message: String

  /// 아이콘, 제목, 설명을 중앙 정렬합니다.
  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 34, weight: .medium))
        .foregroundStyle(.secondary)

      Text(title)
        .font(.headline)

      Text(message)
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// 좌측 목록에서 패키지명, 버전, 라이선스 종류를 요약하는 행입니다.
private struct OpenSourceLicenseRowView: View {
  /// 이 행에 표시할 단일 패키지 라이선스 정보입니다.
  let license: OpenSourceLicense

  /// 패키지 이름을 강조하고 버전과 라이선스를 보조 정보로 배치합니다.
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(license.name)
        .font(.headline)

      HStack(spacing: 6) {
        Text(license.version)
        Text("·")
        Text(license.licenseName)
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .lineLimit(1)
    }
    .padding(.vertical, 4)
  }
}

/// 선택한 패키지의 출처 정보와 라이선스 전문을 표시하는 상세 화면입니다.
private struct OpenSourceLicenseDetailView: View {
  /// 상세 화면에 표시할 선택된 라이선스 모델입니다.
  let license: OpenSourceLicense

  /// 헤더와 라이선스 전문을 선택 가능한 스크롤 콘텐츠로 구성합니다.
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        header
        Divider()
        licenseText
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(28)
    }
    .background(Color(nsColor: .textBackgroundColor))
  }
}

private extension OpenSourceLicenseDetailView {
  /// 패키지명, 버전, 라이선스 파일, 저장소 링크를 표시하는 상단 영역입니다.
  var header: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(license.name)
        .font(.largeTitle.bold())
        .textSelection(.enabled)

      HStack(spacing: 8) {
        Label(license.version, systemImage: "tag")
        Label(license.licenseName, systemImage: "doc.text")
        Label(license.licenseFileName, systemImage: "paperclip")
      }
      .font(.callout)
      .foregroundStyle(.secondary)

      if let repositoryURL {
        Link(license.repositoryURL, destination: repositoryURL)
          .font(.callout)
      } else {
        Text(license.repositoryURL)
          .font(.callout)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      }
    }
  }

  /// HTTP 또는 HTTPS 저장소 주소만 사용자가 열 수 있는 링크로 반환합니다.
  var repositoryURL: URL? {
    openSourceLicenseRepositoryURL(from: license.repositoryURL)
  }

  /// 원문 형식을 읽기 쉽도록 고정폭 글꼴로 표시하는 라이선스 전문 영역입니다.
  var licenseText: some View {
    Text(license.licenseText)
      .font(.system(.body, design: .monospaced))
      .foregroundStyle(.primary)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// 기존 선택이 유효하면 유지하고, 아니면 새 목록의 첫 항목을 선택합니다.
func synchronizedLicenseSelection(
  _ selection: OpenSourceLicense.ID?,
  with licenses: [OpenSourceLicense]
) -> OpenSourceLicense.ID? {
  guard
    let selection,
    licenses.contains(where: { $0.id == selection })
  else {
    return licenses.first?.id
  }
  return selection
}

/// HTTP(S) 외의 스킴을 링크로 열지 않도록 저장소 주소를 검증합니다.
func openSourceLicenseRepositoryURL(from value: String) -> URL? {
  guard
    let url = URL(string: value),
    let scheme = url.scheme?.lowercased(),
    scheme == "https" || scheme == "http"
  else {
    return nil
  }
  return url
}
