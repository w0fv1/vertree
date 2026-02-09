# macOS Support Notes (Vertree)

## Current macOS Feature Mapping

- Tray/menu bar: Uses `tray_manager` + `window_manager` (same UX as Windows tray: show/hide window, quit).
- Auto-start (Login Items): Uses `launch_at_startup` on macOS (Settings page toggle maps to macOS login item state).
- Notifications: Uses `local_notifier` (macOS API warnings are from the plugin; functionality works in debug).
- File monitoring + backup: Pure Dart logic; no platform-specific changes required.

## macOS UX For "Right-Click Menu" Features

Goal: keep the same 4 actions as Windows, but delivered via macOS-native entry points:

- Backup file (with note)
- Quick backup
- Monitor file changes
- View version tree

Implemented entry point:

1. Finder Services (Quick Actions)
   - Implemented via macOS Services in the app bundle (`NSServices`).
   - Appears in Finder right-click → Services / Quick Actions.
   - Each action passes file path(s) into the running app.

## Single Instance

- Windows: `windows_single_instance` already used.
- macOS proposal:
  - Use a file lock under `~/Library/Application Support/vertree/instance.lock`.
  - On second launch, send the args to the running instance (local TCP/Unix socket).

