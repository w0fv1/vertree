import Cocoa
import FinderSync

private let appGroupIdentifier = "group.dev.w0fv1.vertree"
private let requestKeyPrefix = "finderAction."
private let launcherScheme = "vertree://finder"

private struct PendingFinderActionItem: Codable {
  let path: String
  let bookmarkBase64: String
}

private struct PendingFinderAction: Codable {
  let action: String
  let items: [PendingFinderActionItem]
}

final class FinderSync: FIFinderSync {
  override init() {
    super.init()
    FIFinderSyncController.default().directoryURLs = defaultMonitoredFolders()
  }

  override func menu(for menuKind: FIMenuKind) -> NSMenu? {
    guard menuKind == .contextualMenuForItems else {
      return nil
    }

    let menu = NSMenu(title: "Vertree")
    let rootItem = NSMenuItem(title: "Vertree", action: nil, keyEquivalent: "")
    let submenu = NSMenu(title: "Vertree")

    submenu.addItem(menuItem(
      title: "备份文件",
      action: #selector(backupSelectedFiles(_:))
    ))
    submenu.addItem(menuItem(
      title: "快速备份",
      action: #selector(expressBackupSelectedFiles(_:))
    ))
    submenu.addItem(menuItem(
      title: "监控文件",
      action: #selector(monitSelectedFiles(_:))
    ))
    submenu.addItem(menuItem(
      title: "查看版本树",
      action: #selector(viewtreeSelectedFiles(_:))
    ))

    rootItem.submenu = submenu
    menu.addItem(rootItem)
    return menu
  }

  @objc private func backupSelectedFiles(_ sender: Any?) {
    dispatchAction("backup")
  }

  @objc private func expressBackupSelectedFiles(_ sender: Any?) {
    dispatchAction("express-backup")
  }

  @objc private func monitSelectedFiles(_ sender: Any?) {
    dispatchAction("monit")
  }

  @objc private func viewtreeSelectedFiles(_ sender: Any?) {
    dispatchAction("viewtree")
  }

  private func menuItem(title: String, action: Selector) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
    item.target = self
    return item
  }

  private func defaultMonitoredFolders() -> Set<URL> {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let desktop = home.appendingPathComponent("Desktop", isDirectory: true)
    return [home, desktop]
  }

  private func selectedFileURLs() -> [URL] {
    let controller = FIFinderSyncController.default()
    let selectedURLs = Array(controller.selectedItemURLs() ?? [])
    if !selectedURLs.isEmpty {
      return selectedURLs.filter(isRegularFileURL(_:))
    }

    guard let targetedURL = controller.targetedURL() else {
      return []
    }
    return isRegularFileURL(targetedURL) ? [targetedURL] : []
  }

  private func isRegularFileURL(_ url: URL) -> Bool {
    guard url.isFileURL else {
      return false
    }

    let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
    if values?.isDirectory == true {
      return false
    }
    return values?.isRegularFile ?? true
  }

  private func dispatchAction(_ action: String) {
    let items = selectedFileURLs().compactMap(makePendingItem(from:))
    guard !items.isEmpty else {
      return
    }

    let request = PendingFinderAction(action: action, items: items)
    let requestID = UUID().uuidString.lowercased()
    guard persist(request: request, requestID: requestID) else {
      return
    }

    openMainApp(requestID: requestID, action: action)
  }

  private func makePendingItem(from url: URL) -> PendingFinderActionItem? {
    guard let bookmarkData = try? url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    ) else {
      return nil
    }

    return PendingFinderActionItem(
      path: url.path,
      bookmarkBase64: bookmarkData.base64EncodedString()
    )
  }

  private func persist(request: PendingFinderAction, requestID: String) -> Bool {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
          let data = try? JSONEncoder().encode(request) else {
      return false
    }

    defaults.set(data, forKey: "\(requestKeyPrefix)\(requestID)")
    defaults.synchronize()
    return true
  }

  private func openMainApp(requestID: String, action: String) {
    var components = URLComponents(string: launcherScheme)
    components?.queryItems = [
      URLQueryItem(name: "action", value: action),
      URLQueryItem(name: "request", value: requestID),
    ]

    guard let url = components?.url else {
      return
    }

    NSWorkspace.shared.open(url)
  }
}
