import Cocoa
import FlutterMacOS
import ServiceManagement

class AutoStartPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "vertree/auto_start",
      binaryMessenger: registrar.messenger
    )
    let instance = AutoStartPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if #available(macOS 13.0, *) {
      let service = SMAppService.mainApp
      switch call.method {
      case "isEnabled":
        result(service.status == .enabled)
      case "enable":
        do {
          try service.register()
          result(service.status == .enabled)
        } catch {
          result(FlutterError(
            code: "AUTOSTART_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        }
      case "disable":
        do {
          try service.unregister()
          result(service.status != .enabled)
        } catch {
          result(FlutterError(
            code: "AUTOSTART_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
      return
    }

    result(false)
  }
}
