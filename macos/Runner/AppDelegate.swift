import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var pendingServiceActions: [(action: String, path: String)] = []
  private var dockChannel: FlutterMethodChannel?

  private func scheduleDockIconRefresh() {
    DispatchQueue.main.async { [weak self] in
      self?.refreshDockIcon()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      self?.refreshDockIcon()
    }
  }

  private func setupDockChannelIfNeeded() {
    guard dockChannel == nil else { return }
    guard let controller = flutterViewController() else { return }

    let channel = FlutterMethodChannel(
      name: "vertree/dock",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(false)
        return
      }
      switch call.method {
      case "refresh":
        self.scheduleDockIconRefresh()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    dockChannel = channel
  }

  private func ensureRegularActivationPolicy() {
    // When the app runs as an "accessory" (no Dock icon) to support tray-only mode,
    // we must switch back to ".regular" before showing the main window, otherwise
    // the Dock icon can stay missing after restoring from the menu bar.
    if NSApp.activationPolicy() != .regular {
      _ = NSApp.setActivationPolicy(.regular)
      scheduleDockIconRefresh()
    }
  }

  private func refreshDockIcon() {
    // Use a named image set so we can reliably refresh after activation-policy changes.
    if let image = NSImage(named: NSImage.Name("DockIcon")) {
      NSApplication.shared.applicationIconImage = image
      NSApp.dockTile.display()
    }
  }

  private func activateAndShowMainWindow() {
    ensureRegularActivationPolicy()
    NSApp.activate(ignoringOtherApps: true)
    if let window = NSApp.mainWindow ?? NSApp.windows.first {
      window.makeKeyAndOrderFront(nil)
    }
    refreshDockIcon()
  }

  private func enqueueServiceAction(_ action: String, path: String) {
    pendingServiceActions.append((action: action, path: path))
  }

  private func flushPendingServiceActions() {
    guard !pendingServiceActions.isEmpty else { return }
    guard flutterViewController() != nil else { return }

    // Avoid re-entrancy if invoking an action triggers further events.
    let actions = pendingServiceActions
    pendingServiceActions.removeAll()
    for entry in actions {
      invokeServiceAction(entry.action, path: entry.path)
    }
  }

  private func flutterViewController() -> FlutterViewController? {
    if let window = NSApp.mainWindow,
       let controller = window.contentViewController as? FlutterViewController {
      return controller
    }
    for window in NSApp.windows {
      if let controller = window.contentViewController as? FlutterViewController {
        return controller
      }
    }
    return nil
  }

  private func invokeServiceAction(_ action: String, path: String) {
    guard let controller = flutterViewController() else {
      enqueueServiceAction(action, path: path)
      return
    }
    activateAndShowMainWindow()
    let channel = FlutterMethodChannel(
      name: "vertree/service",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.invokeMethod("serviceAction", arguments: [
      "action": action,
      "path": path
    ])
  }

  private func invokeMenuAction(_ action: String) {
    guard let controller = flutterViewController() else { return }
    activateAndShowMainWindow()
    let channel = FlutterMethodChannel(
      name: "vertree/service",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.invokeMethod("menuAction", arguments: [
      "action": action
    ])
  }

  @IBAction func openSettings(_ sender: Any?) {
    invokeMenuAction("openSettings")
  }

  @IBAction func menuBackup(_ sender: Any?) {
    invokeMenuAction("--backup")
  }

  @IBAction func menuExpressBackup(_ sender: Any?) {
    invokeMenuAction("--express-backup")
  }

  @IBAction func menuMonit(_ sender: Any?) {
    invokeMenuAction("--monit")
  }

  @IBAction func menuViewtree(_ sender: Any?) {
    invokeMenuAction("--viewtree")
  }

  private func readFilePaths(from pboard: NSPasteboard) -> [String] {
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true
    ]
    if let urls = pboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
       !urls.isEmpty {
      return urls.map { $0.path }
    }
    if let paths = pboard.propertyList(forType: .fileURL) as? [String], !paths.isEmpty {
      return paths
    }
    if let path = pboard.string(forType: .fileURL), !path.isEmpty {
      return [path]
    }
    return []
  }

  @objc func vertreeBackup(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
    for path in readFilePaths(from: pboard) {
      invokeServiceAction("--backup", path: path)
    }
  }

  @objc func vertreeExpressBackup(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
    for path in readFilePaths(from: pboard) {
      invokeServiceAction("--express-backup", path: path)
    }
  }

  @objc func vertreeMonit(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
    for path in readFilePaths(from: pboard) {
      invokeServiceAction("--monit", path: path)
    }
  }

  @objc func vertreeViewtree(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
    for path in readFilePaths(from: pboard) {
      invokeServiceAction("--viewtree", path: path)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app alive for tray/Services even if no window is visible.
    return false
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    setupDockChannelIfNeeded()
    scheduleDockIconRefresh()

    // If the app was launched by Finder (Services/Open With), the service callback can fire
    // before the Flutter view is fully wired. Retry shortly after launch.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
      self?.flushPendingServiceActions()
      self?.setupDockChannelIfNeeded()
      self?.scheduleDockIconRefresh()
    }
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    super.applicationDidBecomeActive(notification)
    setupDockChannelIfNeeded()
    scheduleDockIconRefresh()
    flushPendingServiceActions()
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    // "Open With -> Vertree" acts as a quick "Backup" trigger for selected files.
    for path in filenames {
      invokeServiceAction("--backup", path: path)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
