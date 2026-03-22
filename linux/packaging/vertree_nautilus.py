from pathlib import Path
import subprocess

import gi

for _nautilus_version in ("4.1", "4.0", "3.0"):
    try:
        gi.require_version("Nautilus", _nautilus_version)
        break
    except ValueError:
        pass

from gi.repository import GObject, GLib, Nautilus

VERTREE_EXECUTABLE = "/usr/bin/vertree"
USER_OVERRIDE = Path(
    "~/.local/share/nautilus-python/extensions/vertree_user_extension.py"
).expanduser()
ACTIONS = [
    ("backup", "备份该文件", "backup"),
    ("expressBackup", "快速备份该文件", "express-backup"),
    ("monitor", "监控该文件", "monit"),
    ("share", "局域网分享下载", "share"),
    ("viewTree", "查看版本树", ""),
]


def _resolve_local_file_path(file_info):
    try:
        uri = file_info.get_uri()
    except Exception:
        return None
    if not uri or not uri.startswith("file://"):
        return None
    try:
        path, _ = GLib.filename_from_uri(uri)
        return path
    except Exception:
        return None


class VertreeSystemExtension(GObject.GObject, Nautilus.MenuProvider):
    def _launch(self, action, path):
        try:
            command = [VERTREE_EXECUTABLE, path] if not action else [VERTREE_EXECUTABLE, action, path]
            subprocess.Popen(
                command,
                start_new_session=True,
            )
        except Exception:
            pass

    def get_file_items(self, *args):
        if USER_OVERRIDE.exists():
            return

        files = args[-1] if args else None
        if not files or len(files) != 1:
            return

        file_info = files[0]
        if file_info.is_directory():
            return

        path = _resolve_local_file_path(file_info)
        if not path:
            return

        root = Nautilus.MenuItem(
            name="Vertree::Root",
            label="Vertree",
            tip="Vertree 文件操作",
        )
        submenu = Nautilus.Menu()
        root.set_submenu(submenu)

        for action_key, label, cli_action in ACTIONS:
            item = Nautilus.MenuItem(
                name=f"Vertree::{action_key}",
                label=label,
                tip=label,
            )
            item.connect(
                "activate",
                lambda _item, action=cli_action, file_path=path: self._launch(
                    action, file_path
                ),
            )
            submenu.append_item(item)

        return [root]
