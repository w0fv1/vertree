import 'dart:io';

import 'package:vertree/VerTreeRegistryService.dart';

import 'main.dart';

extension StringTranslate on String {
  String tr([List<String>? args]) {
    String result = this;

    if (args == null) {
      return result;
    }
    for (final arg in args) {
      result = result.replaceFirst('%a', arg);
    }
    return result;
  }
}

enum Lang {
  ZH_CN("简体中文"),
  EN("English"),
  JA("日本語"),
  OTHER("");

  final String label;

  const Lang(this.label);

  static Lang fromString(String value) {
    for (var l in Lang.values) {
      if (l.name == value) return l;
    }
    return Lang.OTHER;
  }
}

class AppLocale {
  Lang lang = Lang.ZH_CN;

  void changeLang(Lang newLang) {
    if(newLang.name == lang.name){
      return;
    }
    lang = newLang;
    configer.set<String>('locale', newLang.name); // ✅ 已经保存到 config

    VerTreeRegistryService.reAddContextMenu();
    // 如果你使用 flutter_localization 或 intl，这里应该刷新语言环境
    // 例如: LocalizationService().setLocale(newLang.toLocale());
  }

  List<Lang> get supportedLangs => [Lang.ZH_CN, Lang.EN, Lang.JA];

  AppLocale() {
    // 从 config 中读取语言配置
    final String localeStr = configer.get<String>('locale', 'OTHER');
    final Lang configLang = Lang.fromString(localeStr);

    if (configLang == Lang.OTHER) {
      // 如果配置中是 OTHER，使用系统语言
      final systemLocale = Platform.localeName.toLowerCase();
      if (systemLocale.startsWith('zh')) {
        lang = Lang.ZH_CN;
      } else if (systemLocale.startsWith('ja')) {
        lang = Lang.JA;
      } else if (systemLocale.startsWith('en')) {
        lang = Lang.EN;
      } else {
        lang = Lang.OTHER;
      }
    } else {
      lang = configLang;
    }
  }

  String getText(String key) {
    final Map<String, String> langMap;

    switch (lang) {
      case Lang.ZH_CN:
        langMap = ZH_CN;
        break;
      case Lang.EN:
        langMap = EN;
        break;
      case Lang.JA:
        langMap = JA;
        break;
      case Lang.OTHER:
        langMap = ZH_CN;
        break;
    }

    return langMap[key] ?? '$key not found';
  }

  static const String registry_backupKeyName = "RegistryVerTreeBackup";
  static const String registry_expressBackupKeyName = "RegistryVerTreeExpressBackup";
  static const String registry_monitorKeyName = "RegistryVerTreeMonitor";
  static const String registry_viewTreeKeyName = "RegistryVerTreeViewTree";

  static const String app_confirmExitTitle = 'confirmExitTitle';
  static const String app_confirmExitContent = 'confirmExitContent';
  static const String app_minimize = 'minimize';
  static const String app_exit = 'exit';

  static const String app_trayNotificationTitle = 'trayNotificationTitle';
  static const String app_trayNotificationContent = 'trayNotificationContent';

  static const String app_monitStartedTitle = 'monitStartedTitle';
  static const String app_monitStartedContent = 'monitStartedContent';

  static const String app_backupFailed = 'backupFailed';
  static const String app_backupSuccessTitle = 'backupSuccessTitle';
  static const String app_backupSuccessContent = 'backupSuccessContent';

  static const String app_enterLabelTitle = 'enterLabelTitle';
  static const String app_enterLabelHint = 'enterLabelHint';
  static const String app_cancelBackup = 'cancelBackup';
  static const String app_confirm = 'confirm';

  static const String app_cancelNotificationTitle = 'cancelNotificationTitle';
  static const String app_cancelNotificationContent = 'cancelNotificationContent';

  static const String app_labelDialogError = 'labelDialogError';

  static const String app_enableMonitTitle = 'enableMonitTitle';
  static const String app_enableMonitContent = 'enableMonitContent';
  static const String app_yes = 'yes';
  static const String app_no = 'no';

  static const String app_monitFailedTitle = 'monitFailedTitle';

  static const String app_monitSuccessTitle = 'monitSuccessTitle';
  static const String app_monitSuccessContent = 'monitSuccessContent';

  static const String brand_title = 'brandTitle';
  static const String brand_slogan = 'brandSlogan';
  static const String brand_monitorPage = 'brandMonitorPage';
  static const String brand_settingPage = 'brandSettingPage';
  static const String brand_exit = 'brandExit';
  static const String brand_initTitle = 'brandInitTitle';
  static const String brand_initContent = 'brandInitContent';
  static const String brand_cancel = 'brandCancel';
  static const String brand_confirm = 'brandConfirm';
  static const String brand_initDoneTitle = 'brandInitDoneTitle';
  static const String brand_initDoneBody = 'brandInitDoneBody';

  static const String monit_title = 'monitTitle';
  static const String monit_empty = 'monitEmpty';
  static const String monit_addSuccess = 'monitAddSuccess';
  static const String monit_addFail = 'monitAddFail';
  static const String monit_fileNotSelected = 'monitFileNotSelected';
  static const String monit_confirmDeleteTitle = 'monitConfirmDeleteTitle';
  static const String monit_confirmDeleteContent = 'monitConfirmDeleteContent';
  static const String monit_cancel = 'monitCancel';
  static const String monit_delete = 'monitDelete';
  static const String monit_deleteSuccess = 'monitDeleteSuccess';

  static const String setting_title = 'settingTitle';
  static const String setting_titleBar = 'settingTitleBar';
  static const String setting_language = 'settingLanguage';
  static const String setting_contextMenuGroup = 'settingContextMenuGroup';
  static const String setting_addBackupMenu = 'settingAddBackupMenu';
  static const String setting_addExpressBackupMenu = 'settingAddExpressBackupMenu';
  static const String setting_addMonitorMenu = 'settingAddMonitorMenu';
  static const String setting_addViewtreeMenu = 'settingAddViewtreeMenu';
  static const String setting_enableAutostart = 'settingEnableAutostart';
  static const String setting_openConfig = 'settingOpenConfig';
  static const String setting_visitWebsite = 'settingVisitWebsite';
  static const String setting_openGithub = 'settingOpenGithub';

  static const String setting_notifyAddBackup = 'settingNotifyAddBackup';
  static const String setting_notifyRemoveBackup = 'settingNotifyRemoveBackup';
  static const String setting_notifyAddMonitor = 'settingNotifyAddMonitor';
  static const String setting_notifyRemoveMonitor = 'settingNotifyRemoveMonitor';
  static const String setting_notifyAddView = 'settingNotifyAddView';
  static const String setting_notifyRemoveView = 'settingNotifyRemoveView';
  static const String setting_notifyEnableAutostart = 'settingNotifyEnableAutostart';
  static const String setting_notifyDisableAutostart = 'settingNotifyDisableAutostart';
  static const String setting_notifyAddExpress = 'settingNotifyAddExpress';
  static const String setting_notifyRemoveExpress = 'settingNotifyRemoveExpress';

  static const String vertree_title = 'vertreeTitle';
  static const String vertree_fileTreeTitle = 'vertreeFileTreeTitle';

  static const String monitcard_monitorStatus = 'monitCardMonitorStatus';
  static const String monitcard_backupFolder = 'monitCardBackupFolder';

  static const String filetree_inputLabelTitle = 'filetreeInputLabelTitle';
  static const String filetree_inputLabelHint = 'filetreeInputLabelHint';
  static const String filetree_inputCancel = 'filetreeInputCancel';
  static const String filetree_inputConfirm = 'filetreeInputConfirm';

  static const String fileleaf_noLabel = 'fileleafNoLabel';
  static const String fileleaf_lastModified = 'fileleafLastModified';
  static const String fileleaf_openTitle = 'fileleafOpenTitle';
  static const String fileleaf_openContent = 'fileleafOpenContent';
  static const String fileleaf_cancel = 'fileleafCancel';
  static const String fileleaf_confirm = 'fileleafConfirm';
  static const String fileleaf_menuBackup = 'fileleafMenuBackup';
  static const String fileleaf_menuMonit = 'fileleafMenuMonit';
  static const String fileleaf_menuProperty = 'fileleafMenuProperty';
  static const String fileleaf_monitTitle = 'fileleafMonitTitle';
  static const String fileleaf_monitContent = 'fileleafMonitContent';
  static const String fileleaf_notifyFailed = 'fileleafNotifyFailed';
  static const String fileleaf_notifySuccess = 'fileleafNotifySuccess';
  static const String fileleaf_notifyHint = 'fileleafNotifyHint';

  static const String fileleaf_propertyTitle = 'fileleafPropertyTitle';
  static const String fileleaf_propertyFullname = 'fileleafPropertyFullname';
  static const String fileleaf_propertyName = 'fileleafPropertyName';
  static const String fileleaf_propertyLabel = 'fileleafPropertyLabel';
  static const String fileleaf_propertyInputLabel = 'fileleafPropertyInputLabel';
  static const String fileleaf_propertyVersion = 'fileleafPropertyVersion';
  static const String fileleaf_propertyExt = 'fileleafPropertyExt';
  static const String fileleaf_propertyPath = 'fileleafPropertyPath';
  static const String fileleaf_propertySize = 'fileleafPropertySize';
  static const String fileleaf_propertyCreated = 'fileleafPropertyCreated';
  static const String fileleaf_propertyModified = 'fileleafPropertyModified';
  static const String fileleaf_propertyClose = 'fileleafPropertyClose';


  static const Map<String, String> EN = {
    registry_backupKeyName: "Backup Files VerTree",
    registry_expressBackupKeyName: "Quick Backup Files VerTree",
    registry_monitorKeyName: "Monitor File Changes VerTree",
    registry_viewTreeKeyName: "View File Version Tree VerTree",

    app_confirmExitTitle: "Confirm Exit",
    app_confirmExitContent: "Are you sure you want to exit the application?",
    app_minimize: "Minimize",
    app_exit: "Exit",

    app_trayNotificationTitle: "Vertree running in background",
    app_trayNotificationContent: "File version tree manager 🌲 (Click to open)",

    app_monitStartedTitle: "Vertree started monitoring",
    app_monitStartedContent: "Click to view monitoring tasks",

    app_backupFailed: "Vertree failed to back up the file",
    app_backupSuccessTitle: "Vertree backed up file",
    app_backupSuccessContent: "Click to open new file",

    app_enterLabelTitle: "Enter a note for backing up",
    app_enterLabelHint: "Note (optional)",
    app_cancelBackup: "Cancel backup",
    app_confirm: "Confirm",

    app_cancelNotificationTitle: "Vertree backup canceled",
    app_cancelNotificationContent: "User canceled the backup operation",

    app_labelDialogError: "Failed to create label input dialog: ",

    app_enableMonitTitle: "Enable monitoring?",
    app_enableMonitContent: "Do you want to monitor the new version after backup?",
    app_yes: "Yes",
    app_no: "No",

    app_monitFailedTitle: "Vertree monitoring failed",
    app_monitSuccessTitle: "Vertree started monitoring file",
    app_monitSuccessContent: "Click to open backup folder",

    brand_title: 'Vertree',
    brand_slogan: 'Vertree, a tree-based file version manager 🌲, making every iteration worry-free!',
    brand_monitorPage: 'Monitor Page',
    brand_settingPage: 'Settings',
    brand_exit: 'Exit Vertree',
    brand_initTitle: 'Initial Setup',
    brand_initContent: 'Allow Vertree to add context menu and enable auto start?',
    brand_cancel: 'Cancel',
    brand_confirm: 'Confirm',
    brand_initDoneTitle: 'Vertree setup complete!',
    brand_initDoneBody: 'Let’s get started!',

    monit_title: 'Vertree Monitor',
    monit_empty: 'No monitoring tasks yet',
    monit_addSuccess: 'Successfully added monitor task: %a',
    monit_addFail: 'Failed to add task: %a',
    monit_fileNotSelected: 'No file selected',
    monit_confirmDeleteTitle: 'Confirm Delete',
    monit_confirmDeleteContent: 'Are you sure you want to delete the monitor task: %a?',
    monit_cancel: 'Cancel',
    monit_delete: 'Delete',
    monit_deleteSuccess: 'Deleted monitor task: %a',

    setting_title: "Settings",
    setting_titleBar: "Vertree Settings",
    setting_language: "Language",
    setting_contextMenuGroup: "Context Menu Options",
    setting_addBackupMenu: "Add 'Backup this file' to context menu",
    setting_addExpressBackupMenu: "Add 'Express backup this file' to context menu",
    setting_addMonitorMenu: "Add 'Monitor this file' to context menu",
    setting_addViewtreeMenu: "Add 'View version tree' to context menu",
    setting_enableAutostart: "Enable Vertree on startup (Recommended)",
    setting_openConfig: "Open config.json",
    setting_visitWebsite: "Visit official website",
    setting_openGithub: "View GitHub repo",
    setting_notifyAddBackup: "Added 'Backup this file version' to context menu",
    setting_notifyRemoveBackup: "Removed 'Backup this file version' from context menu",
    setting_notifyAddMonitor: "Added 'Monitor this file' to context menu",
    setting_notifyRemoveMonitor: "Removed 'Monitor this file' from context menu",
    setting_notifyAddView: "Added 'View file version tree' to context menu",
    setting_notifyRemoveView: "Removed 'View file version tree' from context menu",
    setting_notifyEnableAutostart: "Enabled autostart",
    setting_notifyDisableAutostart: "Disabled autostart",
    setting_notifyAddExpress: "Added 'Express backup this file' to context menu",
    setting_notifyRemoveExpress: "Removed 'Express backup this file' from context menu",

    vertree_title: "Vertree",
    vertree_fileTreeTitle: "%a.%a File Version Tree",

    monitcard_monitorStatus: "Monitoring of %a has been %a",
    monitcard_backupFolder: "Backup Folder: %a",

    filetree_inputLabelTitle: "Enter a label",
    filetree_inputLabelHint: "Enter a label (optional)",
    filetree_inputCancel: "Cancel",
    filetree_inputConfirm: "Confirm",

    fileleaf_noLabel: "No label",
    fileleaf_lastModified: "Last modified",
    fileleaf_openTitle: "Open file %a.%a?",
    fileleaf_openContent: "You are about to open \"%a.%a\" version %a",
    fileleaf_cancel: "Cancel",
    fileleaf_confirm: "Confirm",
    fileleaf_menuBackup: "Backup version",
    fileleaf_menuMonit: "Monitor changes",
    fileleaf_menuProperty: "Properties",
    fileleaf_monitTitle: "Confirm file monitoring",
    fileleaf_monitContent: "Start monitoring file \"%a.%a\"?",
    fileleaf_notifyFailed: "Vertree monitoring failed,",
    fileleaf_notifySuccess: "Vertree is now monitoring file",
    fileleaf_notifyHint: "Click me to open backup folder",

    fileleaf_propertyTitle: "File Properties",
    fileleaf_propertyFullname: "Full Name:",
    fileleaf_propertyName: "Name:",
    fileleaf_propertyLabel: "Label:",
    fileleaf_propertyInputLabel: "Enter label",
    fileleaf_propertyVersion: "Version:",
    fileleaf_propertyExt: "Extension:",
    fileleaf_propertyPath: "Path:",
    fileleaf_propertySize: "File Size:",
    fileleaf_propertyCreated: "Created Time:",
    fileleaf_propertyModified: "Modified Time:",
    fileleaf_propertyClose: "Close",
  };

  static const Map<String, String> ZH_CN = {
    registry_backupKeyName: "备份文件 VerTree",
    registry_expressBackupKeyName: "快速备份文件 VerTree",
    registry_monitorKeyName: "监控文件变动 VerTree",
    registry_viewTreeKeyName: "查看文件版本树 VerTree",

    app_confirmExitTitle: "确认退出",
    app_confirmExitContent: "确定要退出应用吗？",
    app_minimize: "最小化",
    app_exit: "退出",

    app_trayNotificationTitle: "Vertree最小化运行中",
    app_trayNotificationContent: "树状文件版本管理🌲（点我打开）",

    app_monitStartedTitle: "Vertree开始监控",
    app_monitStartedContent: "点击查看监控任务",

    app_backupFailed: "Vertree 备份文件失败",
    app_backupSuccessTitle: "Vertree 已备份文件",
    app_backupSuccessContent: "点击我打开新文件",

    app_enterLabelTitle: "请输入备份备注（可选）",
    app_enterLabelHint: "备注信息（可选）",
    app_cancelBackup: "取消备份",
    app_confirm: "确定",

    app_cancelNotificationTitle: "Vertree 备份已取消",
    app_cancelNotificationContent: "用户取消了备份操作",

    app_labelDialogError: "创建询问备注对话框失败：",

    app_enableMonitTitle: "开启监控？",
    app_enableMonitContent: "是否对备份的新版本进行监控？",
    app_yes: "是",
    app_no: "否",

    app_monitFailedTitle: "Vertree监控失败",
    app_monitSuccessTitle: "Vertree已开始监控文件",
    app_monitSuccessContent: "点击我打开备份目录",

    brand_title: 'Vertree维树',
    brand_slogan: 'Vertree维树，树状文件版本管理🌲，让每一次迭代都有备无患！',
    brand_monitorPage: '监控页',
    brand_settingPage: '设置页',
    brand_exit: '完全退出维树',
    brand_initTitle: '初始化设置',
    brand_initContent: '是否允许Vertree添加右键菜单和开机启动？',
    brand_cancel: '取消',
    brand_confirm: '确定',
    brand_initDoneTitle: 'Vertree初始设置已完成！',
    brand_initDoneBody: '开始使用吧！',

    monit_title: 'Vertree 监控',
    monit_empty: '暂无监控任务',
    monit_addSuccess: '成功添加监控任务: %a',
    monit_addFail: '添加失败: %a',
    monit_fileNotSelected: '未选择文件',
    monit_confirmDeleteTitle: '确认删除',
    monit_confirmDeleteContent: '确定要删除监控任务: %a 吗？',
    monit_cancel: '取消',
    monit_delete: '删除',
    monit_deleteSuccess: '已删除监控任务: %a',

    setting_title: "设置",
    setting_language: '语言',
    setting_titleBar: "Vertree 设置",
    setting_contextMenuGroup: "右键菜单选项",
    setting_addBackupMenu: "将“备份该文件”增加到右键菜单",
    setting_addExpressBackupMenu: "将“快速备份该文件”增加到右键菜单",
    setting_addMonitorMenu: "将“监控该文件”增加到右键菜单",
    setting_addViewtreeMenu: "将“浏览该文件版本树”增加到右键菜单",
    setting_enableAutostart: "开机自启 Vertree（推荐）",
    setting_openConfig: "打开 config.json",
    setting_visitWebsite: "访问官方网站",
    setting_openGithub: "查看 GitHub 仓库",
    setting_notifyAddBackup: "已添加 '备份当前文件版本' 到右键菜单",
    setting_notifyRemoveBackup: "已从右键菜单移除 '备份当前文件版本' 功能按钮",
    setting_notifyAddMonitor: "已添加 '监控该文件' 到右键菜单",
    setting_notifyRemoveMonitor: "已从右键菜单移除 '监控该文件' 功能按钮",
    setting_notifyAddView: "已添加 '浏览文件版本树' 到右键菜单",
    setting_notifyRemoveView: "已从右键菜单移除 '浏览文件版本树' 功能按钮",
    setting_notifyEnableAutostart: "已启用开机自启",
    setting_notifyDisableAutostart: "已禁用开机自启",
    setting_notifyAddExpress: "已添加 '快速备份该文件' 到右键菜单",
    setting_notifyRemoveExpress: "已从右键菜单移除 '快速备份该文件' 功能按钮",

    vertree_title: "Vertree维树",
    vertree_fileTreeTitle: "%a.%a 文本版本树",

    monitcard_monitorStatus: "%a的监控已经%a",
    monitcard_backupFolder: "备份文件夹：%a",

    filetree_inputLabelTitle: "请输入备注",
    filetree_inputLabelHint: "请输入备注（可选）",
    filetree_inputCancel: "取消",
    filetree_inputConfirm: "确认",

    fileleaf_noLabel: "无备注",
    fileleaf_lastModified: "最后修改",
    fileleaf_openTitle: "打开文件 %a.%a ?",
    fileleaf_openContent: "即将打开 \"%a.%a\" %a 版",
    fileleaf_cancel: "取消",
    fileleaf_confirm: "确认",
    fileleaf_menuBackup: "备份版本",
    fileleaf_menuMonit: "监控变更",
    fileleaf_menuProperty: "属性",
    fileleaf_monitTitle: "确认文件监控",
    fileleaf_monitContent: "确定要开始监控文件 \"%a.%a\" 吗？",
    fileleaf_notifyFailed: "Vertree监控失败，",
    fileleaf_notifySuccess: "Vertree已开始监控文件",
    fileleaf_notifyHint: "点击我打开备份目录",

    fileleaf_propertyTitle: "文件属性",
    fileleaf_propertyFullname: "全名:",
    fileleaf_propertyName: "名称:",
    fileleaf_propertyLabel: "备注:",
    fileleaf_propertyInputLabel: "请输入备注",
    fileleaf_propertyVersion: "版本:",
    fileleaf_propertyExt: "扩展名:",
    fileleaf_propertyPath: "路径:",
    fileleaf_propertySize: "文件大小:",
    fileleaf_propertyCreated: "创建时间:",
    fileleaf_propertyModified: "修改时间:",
    fileleaf_propertyClose: "关闭",
  };

  static const Map<String, String> JA = {
    registry_backupKeyName: "バックアップファイル VerTree",
    registry_expressBackupKeyName: "クイックバックアップファイル VerTree",
    registry_monitorKeyName: "ファイル変更監視 VerTree",
    registry_viewTreeKeyName: "ファイルバージョンツリー表示 VerTree",

    app_confirmExitTitle: "終了の確認",
    app_confirmExitContent: "アプリを終了してもよろしいですか？",
    app_minimize: "最小化",
    app_exit: "終了",

    app_trayNotificationTitle: "Vertree はバックグラウンドで実行中",
    app_trayNotificationContent: "ファイルバージョンツリーマネージャー 🌲（クリックして開く）",

    app_monitStartedTitle: "Vertree は監視を開始しました",
    app_monitStartedContent: "クリックして監視タスクを表示",

    app_backupFailed: "Vertree のバックアップに失敗しました",
    app_backupSuccessTitle: "Vertree はファイルをバックアップしました",
    app_backupSuccessContent: "クリックして新しいファイルを開く",

    app_enterLabelTitle: "バックアップのメモを入力してください（任意）",
    app_enterLabelHint: "メモ（任意）",
    app_cancelBackup: "バックアップをキャンセル",
    app_confirm: "確認",

    app_cancelNotificationTitle: "Vertree バックアップがキャンセルされました",
    app_cancelNotificationContent: "ユーザーがバックアップ操作をキャンセルしました",

    app_labelDialogError: "メモ入力ダイアログの作成に失敗しました：",

    app_enableMonitTitle: "監視を有効にしますか？",
    app_enableMonitContent: "バックアップ後の新しいバージョンを監視しますか？",
    app_yes: "はい",
    app_no: "いいえ",

    app_monitFailedTitle: "Vertree の監視に失敗しました",
    app_monitSuccessTitle: "Vertree はファイルの監視を開始しました",
    app_monitSuccessContent: "クリックしてバックアップフォルダーを開く",

    brand_title: 'Vertree',
    brand_slogan: 'Vertree、ツリー型のファイルバージョン管理🌲、すべての変更を安全に！',
    brand_monitorPage: 'モニター画面',
    brand_settingPage: '設定画面',
    brand_exit: 'Vertreeを完全終了',
    brand_initTitle: '初期設定',
    brand_initContent: 'Vertreeに右クリックメニューと自動起動を許可しますか？',
    brand_cancel: 'キャンセル',
    brand_confirm: '確認',
    brand_initDoneTitle: 'Vertreeの初期設定が完了しました！',
    brand_initDoneBody: 'さあ、始めましょう！',

    monit_title: 'Vertree モニター',
    monit_empty: '監視タスクはありません',
    monit_addSuccess: '監視タスクを追加しました: %a',
    monit_addFail: 'タスクの追加に失敗しました: %a',
    monit_fileNotSelected: 'ファイルが選択されていません',
    monit_confirmDeleteTitle: '削除の確認',
    monit_confirmDeleteContent: '監視タスクを削除しますか: %a？',
    monit_cancel: 'キャンセル',
    monit_delete: '削除',
    monit_deleteSuccess: '監視タスクを削除しました: %a',

    setting_title: "設定",
    setting_language: '言語',
    setting_titleBar: "Vertree 設定",
    setting_contextMenuGroup: "右クリックメニューのオプション",
    setting_addBackupMenu: "「このファイルをバックアップ」を右クリックメニューに追加",
    setting_addExpressBackupMenu: "「このファイルを即時バックアップ」を右クリックメニューに追加",
    setting_addMonitorMenu: "「このファイルを監視」を右クリックメニューに追加",
    setting_addViewtreeMenu: "「バージョンツリーを表示」を右クリックメニューに追加",
    setting_enableAutostart: "起動時に Vertree を自動実行（推奨）",
    setting_openConfig: "config.json を開く",
    setting_visitWebsite: "公式サイトを訪問",
    setting_openGithub: "GitHub リポジトリを見る",
    setting_notifyAddBackup: "「このファイルバージョンをバックアップ」が右クリックメニューに追加されました",
    setting_notifyRemoveBackup: "「このファイルバージョンをバックアップ」が右クリックメニューから削除されました",
    setting_notifyAddMonitor: "「このファイルを監視」が右クリックメニューに追加されました",
    setting_notifyRemoveMonitor: "「このファイルを監視」が右クリックメニューから削除されました",
    setting_notifyAddView: "「バージョンツリーを表示」が右クリックメニューに追加されました",
    setting_notifyRemoveView: "「バージョンツリーを表示」が右クリックメニューから削除されました",
    setting_notifyEnableAutostart: "自動起動が有効になりました",
    setting_notifyDisableAutostart: "自動起動が無効になりました",
    setting_notifyAddExpress: "「このファイルを即時バックアップ」が右クリックメニューに追加されました",
    setting_notifyRemoveExpress: "「このファイルを即時バックアップ」が右クリックメニューから削除されました",

    vertree_title: "Vertreeバージョンツリー",
    vertree_fileTreeTitle: "%a.%a ファイルバージョンツリー",

    monitcard_monitorStatus: "%aの監視は%aされました",
    monitcard_backupFolder: "バックアップフォルダ：%a",

    filetree_inputLabelTitle: "ラベルを入力してください",
    filetree_inputLabelHint: "ラベルを入力してください（任意）",
    filetree_inputCancel: "キャンセル",
    filetree_inputConfirm: "確認",

    fileleaf_noLabel: "備考なし",
    fileleaf_lastModified: "最終更新",
    fileleaf_openTitle: "ファイル %a.%a を開きますか？",
    fileleaf_openContent: "「%a.%a」バージョン %a を開こうとしています",
    fileleaf_cancel: "キャンセル",
    fileleaf_confirm: "確認",
    fileleaf_menuBackup: "バックアップバージョン",
    fileleaf_menuMonit: "変更を監視",
    fileleaf_menuProperty: "プロパティ",
    fileleaf_monitTitle: "ファイル監視の確認",
    fileleaf_monitContent: "ファイル「%a.%a」の監視を開始しますか？",
    fileleaf_notifyFailed: "Vertreeの監視に失敗しました、",
    fileleaf_notifySuccess: "Vertreeがファイルの監視を開始しました",
    fileleaf_notifyHint: "クリックしてバックアップフォルダを開く",

    fileleaf_propertyTitle: "ファイルプロパティ",
    fileleaf_propertyFullname: "フルネーム：",
    fileleaf_propertyName: "名前：",
    fileleaf_propertyLabel: "ラベル：",
    fileleaf_propertyInputLabel: "ラベルを入力してください",
    fileleaf_propertyVersion: "バージョン：",
    fileleaf_propertyExt: "拡張子：",
    fileleaf_propertyPath: "パス：",
    fileleaf_propertySize: "ファイルサイズ：",
    fileleaf_propertyCreated: "作成日時：",
    fileleaf_propertyModified: "更新日時：",
    fileleaf_propertyClose: "閉じる",
  };
}
