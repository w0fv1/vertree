import 'dart:io';

import 'package:vertree/VerTreeRegistryService.dart'; // Assuming this exists
// Assuming 'main.dart' defines 'configer' or provides access to it
// If 'configer' is global, this import might be okay.
// Otherwise, AppLocale might need access via constructor or DI.
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

// --- Enum for Languages (Keep as is) ---
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

// --- NEW: Enum for Localization Keys ---
enum LocaleKey {
  // Registry Keys
  registry_backupKeyName,
  registry_expressBackupKeyName,
  registry_monitorKeyName,
  registry_viewTreeKeyName,

  // App General Keys
  app_confirmExitTitle,
  app_confirmExitContent,
  app_minimize,
  app_exit,
  app_trayNotificationTitle,
  app_trayNotificationContent,
  app_monitStartedTitle,
  app_monitStartedContent,
  app_backupFailed,
  app_backupSuccessTitle,
  app_backupSuccessContent,
  app_enterLabelTitle,
  app_enterLabelHint,
  app_cancelBackup,
  app_confirm,
  app_cancelNotificationTitle,
  app_cancelNotificationContent,
  app_labelDialogError,
  app_enableMonitTitle,
  app_enableMonitContent,
  app_yes,
  app_no,
  app_monitFailedTitle,
  app_monitSuccessTitle,
  app_monitSuccessContent,

  // Brand Keys
  brand_title,
  brand_slogan,
  brand_monitorPage,
  brand_settingPage,
  brand_exit,
  brand_initTitle,
  brand_initContent,
  brand_cancel,
  brand_confirm,
  brand_initDoneTitle,
  brand_initDoneBody,

  // Monitor Page Keys
  monit_title,
  monit_empty,
  monit_addSuccess,
  monit_addFail,
  monit_fileNotSelected,
  monit_deleteDialogTitle,
  monit_deleteDialogContent,
  monit_cancel,
  monit_delete,
  monit_deleteSuccess,
  monit_searchHint,
  monit_noResults,
  monit_cleanInvalidTasksDialogTitle,
  monit_invalidTaskDialogItem,
  monit_cleanInvalidTaskDialogBackupDirNotSet,
  monit_cleanInvalidTaskDialogNoInvalidTasks,
  monit_cleanInvalidTaskDialogCleaned,

  // Setting Page Keys
  setting_title,
  setting_titleBar,
  setting_language,
  setting_contextMenuGroup,
  setting_addBackupMenu,
  setting_addExpressBackupMenu,
  setting_addMonitorMenu,
  setting_addViewtreeMenu,
  setting_monitGroup,
  setting_monitRate,
  setting_monitMaxSize,
  setting_enableAutostart,
  setting_openConfig,
  setting_openLogs,
  setting_visitWebsite,
  setting_openGithub,
  setting_notifyAddBackup,
  setting_notifyRemoveBackup,
  setting_notifyAddMonitor,
  setting_notifyRemoveMonitor,
  setting_notifyAddView,
  setting_notifyRemoveView,
  setting_notifyEnableAutostart,
  setting_notifyDisableAutostart,
  setting_notifyAddExpress,
  setting_notifyRemoveExpress,

  // VerTree Page Keys
  vertree_title,
  vertree_fileTreeTitle,

  // Monitor Card Keys
  monitcard_monitorStatus,
  monitcard_backupFolder,
  monitcard_openBackupFolder,
  monitcard_delete,
  monitcard_pause,
  monitcard_clean,
  monitcard_cleanSuccess,
  monitcard_cleanFail,
  monitcard_cleanDialogTitle,
  monitcard_cleanDialogContent,
  monitcard_cleanDialogCancel,
  monitcard_cleanDialogConfirm,
  monitcard_statusRunning,
  monitcard_statusStopped,
  // File Tree Keys
  filetree_inputLabelTitle,
  filetree_inputLabelHint,
  filetree_inputCancel,
  filetree_inputConfirm,

  // File Leaf Keys
  fileleaf_noLabel,
  fileleaf_lastModified,
  fileleaf_openTitle,
  fileleaf_openContent,
  fileleaf_cancel,
  fileleaf_confirm,
  fileleaf_menuBackup,
  fileleaf_menuMonit,
  fileleaf_menuProperty,
  fileleaf_monitTitle,
  fileleaf_monitContent,
  fileleaf_notifyFailed,
  fileleaf_notifySuccess,
  fileleaf_notifyHint,
  fileleaf_propertyTitle,
  fileleaf_propertyFullname,
  fileleaf_propertyName,
  fileleaf_propertyLabel,
  fileleaf_propertyInputLabel,
  fileleaf_propertyVersion,
  fileleaf_propertyExt,
  fileleaf_propertyPath,
  fileleaf_propertySize,
  fileleaf_propertyCreated,
  fileleaf_propertyModified,
  fileleaf_propertyClose,
}

// --- AppLocale Class ---
class AppLocale {
  Lang lang = Lang.ZH_CN;

  AppLocale() {
    _initializeLocale();
  }

  void _initializeLocale() {
    // From config
    final String localeStr = configer.get<String>('locale', 'OTHER');
    final Lang configLang = Lang.fromString(localeStr);

    if (configLang == Lang.OTHER) {
      // If config is OTHER, use system language
      final systemLocale = Platform.localeName.toLowerCase();
      if (systemLocale.startsWith('zh')) {
        lang = Lang.ZH_CN;
      } else if (systemLocale.startsWith('ja')) {
        lang = Lang.JA;
      } else if (systemLocale.startsWith('en')) {
        lang = Lang.EN;
      } else {
        // Default fallback if system lang is not supported
        lang = Lang.ZH_CN; // Or Lang.EN
      }
    } else {
      lang = configLang;
    }
    print("AppLocale Initialized. Language set to: ${lang.name}");
  }

  void changeLang(Lang newLang) {
    if (newLang.name == lang.name || newLang == Lang.OTHER) {
      return;
    }
    lang = newLang;
    configer.set<String>('locale', newLang.name); // ✅ Save to config

    VerTreeRegistryService.reAddContextMenu();
    // If you use flutter_localization or intl, refresh here
    // Example: LocalizationService().setLocale(newLang.toLocale());
    print("AppLocale Language changed to: ${lang.name}");
    // You might need to trigger a UI rebuild here if using Flutter UI framework
  }

  List<Lang> get supportedLangs => [Lang.ZH_CN, Lang.EN, Lang.JA];

  // Updated getText method
  String getText(LocaleKey key) {
    final Map<LocaleKey, String> langMap;

    switch (lang) {
      case Lang.ZH_CN:
        langMap = _ZH_CN;
        break;
      case Lang.EN:
        langMap = _EN;
        break;
      case Lang.JA:
        langMap = _JA;
        break;
      case Lang.OTHER:
        // Fallback logic: Use Chinese as default if 'OTHER' is somehow selected
        langMap = _ZH_CN;
        break;
    }

    // Provide fallbacks: Current Lang -> Chinese -> English -> Key Name
    return langMap[key] ?? _ZH_CN[key] ?? _EN[key] ?? key.name;
  }

  // --- REMOVED: Static const String keys are now in the LocaleKey enum ---

  // --- Translation Maps using LocaleKey ---
  // Made private (_EN, _ZH_CN, _JA) as they are internal implementation details
  static const Map<LocaleKey, String> _EN = {
    LocaleKey.registry_backupKeyName: "Backup Files VerTree",
    LocaleKey.registry_expressBackupKeyName: "Quick Backup Files VerTree",
    LocaleKey.registry_monitorKeyName: "Monitor File Changes VerTree",
    LocaleKey.registry_viewTreeKeyName: "View File Version Tree VerTree",

    LocaleKey.app_confirmExitTitle: "Confirm Exit",
    LocaleKey.app_confirmExitContent: "Are you sure you want to exit the application?",
    LocaleKey.app_minimize: "Minimize",
    LocaleKey.app_exit: "Exit",

    LocaleKey.app_trayNotificationTitle: "Vertree running in background",
    LocaleKey.app_trayNotificationContent: "File version tree manager 🌲 (Click to open)",

    LocaleKey.app_monitStartedTitle: "Vertree started monitoring",
    LocaleKey.app_monitStartedContent: "Click to view monitoring tasks",

    LocaleKey.app_backupFailed: "Vertree failed to back up the file",
    LocaleKey.app_backupSuccessTitle: "Vertree backed up file",
    LocaleKey.app_backupSuccessContent: "Click to open new file",

    LocaleKey.app_enterLabelTitle: "Enter a note for backing up",
    LocaleKey.app_enterLabelHint: "Note (optional)",
    LocaleKey.app_cancelBackup: "Cancel backup",
    LocaleKey.app_confirm: "Confirm",

    LocaleKey.app_cancelNotificationTitle: "Vertree backup canceled",
    LocaleKey.app_cancelNotificationContent: "User canceled the backup operation",

    LocaleKey.app_labelDialogError: "Failed to create label input dialog: ",

    LocaleKey.app_enableMonitTitle: "Enable monitoring?",
    LocaleKey.app_enableMonitContent: "Do you want to monitor the new version after backup?",
    LocaleKey.app_yes: "Yes",
    LocaleKey.app_no: "No",

    LocaleKey.app_monitFailedTitle: "Vertree monitoring failed",
    LocaleKey.app_monitSuccessTitle: "Vertree started monitoring file",
    LocaleKey.app_monitSuccessContent: "Click to open backup folder",

    LocaleKey.brand_title: 'Vertree',
    LocaleKey.brand_slogan: 'Vertree, a tree-based file version manager 🌲, making every iteration worry-free!',
    LocaleKey.brand_monitorPage: 'Monitor Page',
    LocaleKey.brand_settingPage: 'Settings',
    LocaleKey.brand_exit: 'Exit Vertree',
    LocaleKey.brand_initTitle: 'Initial Setup',
    LocaleKey.brand_initContent: 'Allow Vertree to add context menu and enable auto start?',
    LocaleKey.brand_cancel: 'Cancel',
    LocaleKey.brand_confirm: 'Confirm',
    LocaleKey.brand_initDoneTitle: 'Vertree setup complete!',
    LocaleKey.brand_initDoneBody: 'Let’s get started!',

    LocaleKey.monit_title: 'Vertree Monitor',
    LocaleKey.monit_empty: 'No monitoring tasks yet',
    LocaleKey.monit_addSuccess: 'Successfully added monitor task: %a',
    LocaleKey.monit_addFail: 'Failed to add task: %a',
    LocaleKey.monit_fileNotSelected: 'No file selected',
    LocaleKey.monit_deleteDialogTitle: 'Confirm Delete',
    LocaleKey.monit_deleteDialogContent: 'Are you sure you want to delete the monitor task: %a?',
    LocaleKey.monit_cancel: 'Cancel',
    LocaleKey.monit_delete: 'Delete',
    LocaleKey.monit_deleteSuccess: 'Deleted monitor task: %a',
    LocaleKey.monit_searchHint: "Filter by keyword...",
    LocaleKey.monit_noResults: "No matching tasks found",

    LocaleKey.monit_cleanInvalidTasksDialogTitle: "Clean Invalid Monitor Tasks",
    LocaleKey.monit_invalidTaskDialogItem: "File Path: %a, Backup Path: %a",
    LocaleKey.monit_cleanInvalidTaskDialogBackupDirNotSet: "Backup path not set",
    LocaleKey.monit_cleanInvalidTaskDialogNoInvalidTasks: "No invalid monitor tasks found",
    LocaleKey.monit_cleanInvalidTaskDialogCleaned: "Invalid monitor tasks cleaned successfully",

    LocaleKey.setting_title: "Settings",
    LocaleKey.setting_titleBar: "Vertree Settings",
    LocaleKey.setting_language: "Language",
    LocaleKey.setting_contextMenuGroup: "Context Menu Options",
    LocaleKey.setting_addBackupMenu: "Add 'Backup this file' to context menu",
    LocaleKey.setting_addExpressBackupMenu: "Add 'Express backup this file' to context menu",
    LocaleKey.setting_addMonitorMenu: "Add 'Monitor this file' to context menu",
    LocaleKey.setting_addViewtreeMenu: "Add 'View version tree' to context menu",
    LocaleKey.setting_enableAutostart: "Enable Vertree on startup (Recommended)",
    LocaleKey.setting_openConfig: "Open config.json",
    LocaleKey.setting_visitWebsite: "Visit official website",
    LocaleKey.setting_openGithub: "View GitHub repo",
    LocaleKey.setting_notifyAddBackup: "Added 'Backup this file version' to context menu",
    LocaleKey.setting_notifyRemoveBackup: "Removed 'Backup this file version' from context menu",
    LocaleKey.setting_notifyAddMonitor: "Added 'Monitor this file' to context menu",
    LocaleKey.setting_notifyRemoveMonitor: "Removed 'Monitor this file' from context menu",
    LocaleKey.setting_notifyAddView: "Added 'View file version tree' to context menu",
    LocaleKey.setting_notifyRemoveView: "Removed 'View file version tree' from context menu",
    LocaleKey.setting_notifyEnableAutostart: "Enabled autostart",
    LocaleKey.setting_notifyDisableAutostart: "Disabled autostart",
    LocaleKey.setting_notifyAddExpress: "Added 'Express backup this file' to context menu",
    LocaleKey.setting_notifyRemoveExpress: "Removed 'Express backup this file' from context menu",

    LocaleKey.vertree_title: "Vertree",
    LocaleKey.vertree_fileTreeTitle: "%a.%a File Version Tree",

    LocaleKey.monitcard_monitorStatus: "Monitoring of %a has been %a",
    LocaleKey.monitcard_backupFolder: "Backup Folder: %a",
    LocaleKey.monitcard_openBackupFolder: "Open Backup Folder",
    LocaleKey.monitcard_delete: "Delete Monitor Task",
    LocaleKey.monitcard_pause: "Pause", // Assuming 'Pause'/'Resume' toggle text
    LocaleKey.monitcard_clean: "Clean Backup Folder",
    LocaleKey.monitcard_cleanSuccess: "Successfully cleaned backup folder %a",
    LocaleKey.monitcard_cleanFail: "Failed to clean backup folder %a",
    LocaleKey.monitcard_cleanDialogTitle: "Confirm Clean Backup Folder",
    LocaleKey.monitcard_cleanDialogContent:
        "Are you sure you want to clean all files in backup folder %a? This action cannot be undone.",
    LocaleKey.monitcard_cleanDialogCancel: "Cancel",
    LocaleKey.monitcard_cleanDialogConfirm: "Confirm",

    LocaleKey.filetree_inputLabelTitle: "Enter a label",
    LocaleKey.filetree_inputLabelHint: "Enter a label (optional)",
    LocaleKey.filetree_inputCancel: "Cancel",
    LocaleKey.filetree_inputConfirm: "Confirm",

    LocaleKey.fileleaf_noLabel: "No label",
    LocaleKey.fileleaf_lastModified: "Last modified",
    LocaleKey.fileleaf_openTitle: "Open file %a.%a?",
    LocaleKey.fileleaf_openContent: "You are about to open \"%a.%a\" version %a",
    LocaleKey.fileleaf_cancel: "Cancel",
    LocaleKey.fileleaf_confirm: "Confirm",
    LocaleKey.fileleaf_menuBackup: "Backup version",
    LocaleKey.fileleaf_menuMonit: "Monitor changes",
    LocaleKey.fileleaf_menuProperty: "Properties",
    LocaleKey.fileleaf_monitTitle: "Confirm file monitoring",
    LocaleKey.fileleaf_monitContent: "Start monitoring file \"%a.%a\"?",
    LocaleKey.fileleaf_notifyFailed: "Vertree monitoring failed,",
    LocaleKey.fileleaf_notifySuccess: "Vertree is now monitoring file",
    LocaleKey.fileleaf_notifyHint: "Click me to open backup folder",

    LocaleKey.fileleaf_propertyTitle: "File Properties",
    LocaleKey.fileleaf_propertyFullname: "Full Name:",
    LocaleKey.fileleaf_propertyName: "Name:",
    LocaleKey.fileleaf_propertyLabel: "Label:",
    LocaleKey.fileleaf_propertyInputLabel: "Enter label",
    LocaleKey.fileleaf_propertyVersion: "Version:",
    LocaleKey.fileleaf_propertyExt: "Extension:",
    LocaleKey.fileleaf_propertyPath: "Path:",
    LocaleKey.fileleaf_propertySize: "File Size:",
    LocaleKey.fileleaf_propertyCreated: "Created Time:",
    LocaleKey.fileleaf_propertyModified: "Modified Time:",
    LocaleKey.fileleaf_propertyClose: "Close",
  };

  static const Map<LocaleKey, String> _ZH_CN = {
    LocaleKey.registry_backupKeyName: "备份文件 VerTree",
    LocaleKey.registry_expressBackupKeyName: "快速备份文件 VerTree",
    LocaleKey.registry_monitorKeyName: "监控文件变动 VerTree",
    LocaleKey.registry_viewTreeKeyName: "查看文件版本树 VerTree",

    LocaleKey.app_confirmExitTitle: "确认退出",
    LocaleKey.app_confirmExitContent: "确定要退出应用吗？",
    LocaleKey.app_minimize: "最小化",
    LocaleKey.app_exit: "退出",

    LocaleKey.app_trayNotificationTitle: "Vertree最小化运行中",
    LocaleKey.app_trayNotificationContent: "树状文件版本管理🌲（点我打开）",

    LocaleKey.app_monitStartedTitle: "Vertree开始监控",
    LocaleKey.app_monitStartedContent: "点击查看监控任务",

    LocaleKey.app_backupFailed: "Vertree 备份文件失败",
    LocaleKey.app_backupSuccessTitle: "Vertree 已备份文件",
    LocaleKey.app_backupSuccessContent: "点击我打开新文件",

    LocaleKey.app_enterLabelTitle: "请输入备份备注（可选）",
    LocaleKey.app_enterLabelHint: "备注信息（可选）",
    LocaleKey.app_cancelBackup: "取消备份",
    LocaleKey.app_confirm: "确定",

    LocaleKey.app_cancelNotificationTitle: "Vertree 备份已取消",
    LocaleKey.app_cancelNotificationContent: "用户取消了备份操作",

    LocaleKey.app_labelDialogError: "创建询问备注对话框失败：",

    LocaleKey.app_enableMonitTitle: "开启监控？",
    LocaleKey.app_enableMonitContent: "是否对备份的新版本进行监控？",
    LocaleKey.app_yes: "是",
    LocaleKey.app_no: "否",

    LocaleKey.app_monitFailedTitle: "Vertree监控失败",
    LocaleKey.app_monitSuccessTitle: "Vertree已开始监控文件",
    LocaleKey.app_monitSuccessContent: "点击我打开备份目录",




    LocaleKey.brand_title: 'Vertree维树',
    LocaleKey.brand_slogan: 'Vertree维树，树状文件版本管理🌲，让每一次迭代都有备无患！',
    LocaleKey.brand_monitorPage: '监控页',
    LocaleKey.brand_settingPage: '设置页',
    LocaleKey.brand_exit: '完全退出维树',
    LocaleKey.brand_initTitle: '初始化设置',
    LocaleKey.brand_initContent: '是否允许Vertree添加右键菜单和开机启动？',
    LocaleKey.brand_cancel: '取消',
    LocaleKey.brand_confirm: '确定',
    LocaleKey.brand_initDoneTitle: 'Vertree初始设置已完成！',
    LocaleKey.brand_initDoneBody: '开始使用吧！',

    LocaleKey.monit_title: 'Vertree 监控',
    LocaleKey.monit_empty: '暂无监控任务',
    LocaleKey.monit_addSuccess: '成功添加监控任务: %a',
    LocaleKey.monit_addFail: '添加失败: %a',
    LocaleKey.monit_fileNotSelected: '未选择文件',
    LocaleKey.monit_deleteDialogTitle: '确认删除',
    LocaleKey.monit_deleteDialogContent: '确定要删除监控任务: %a 吗？此操作会一并删除相应的备份文件夹和所有备份内容！',
    LocaleKey.monit_cancel: '取消',
    LocaleKey.monit_delete: '删除',
    LocaleKey.monit_deleteSuccess: '已删除监控任务: %a',
    LocaleKey.monit_searchHint: "按关键字筛选...",
    LocaleKey.monit_noResults: "未找到匹配搜索的任务",

    LocaleKey.monit_cleanInvalidTasksDialogTitle: "清理无效监控任务",
    LocaleKey.monit_invalidTaskDialogItem: "文件路径：%a，备份路径：%a",
    LocaleKey.monit_cleanInvalidTaskDialogBackupDirNotSet: "未设置备份路径",
    LocaleKey.monit_cleanInvalidTaskDialogNoInvalidTasks: "未发现无效监控任务",
    LocaleKey.monit_cleanInvalidTaskDialogCleaned: "无效监控任务已成功清理",

    LocaleKey.setting_title: "设置",
    LocaleKey.setting_language: '语言',
    LocaleKey.setting_titleBar: "Vertree 设置",
    LocaleKey.setting_contextMenuGroup: "右键菜单选项设置",
    LocaleKey.setting_addBackupMenu: "将“备份该文件”增加到右键菜单",
    LocaleKey.setting_addExpressBackupMenu: "将“快速备份该文件”增加到右键菜单",
    LocaleKey.setting_addMonitorMenu: "将“监控该文件”增加到右键菜单",
    LocaleKey.setting_addViewtreeMenu: "将“浏览该文件版本树”增加到右键菜单",

    LocaleKey.setting_monitGroup: "监控文件设置",
    LocaleKey.setting_monitRate: "备份文件时间间隔（单位分钟）",
    LocaleKey.setting_monitMaxSize: "备份文件最多数量（会滚动删除旧文件）",

    LocaleKey.setting_enableAutostart: "开机自启 Vertree（推荐）",
    LocaleKey.setting_openConfig: "打开 config.json",
    LocaleKey.setting_openLogs: "打开日志文件夹",

    LocaleKey.setting_visitWebsite: "访问官方网站",
    LocaleKey.setting_openGithub: "查看 GitHub 仓库",
    LocaleKey.setting_notifyAddBackup: "已添加 '备份当前文件版本' 到右键菜单",
    LocaleKey.setting_notifyRemoveBackup: "已从右键菜单移除 '备份当前文件版本' 功能按钮",
    LocaleKey.setting_notifyAddMonitor: "已添加 '监控该文件' 到右键菜单",
    LocaleKey.setting_notifyRemoveMonitor: "已从右键菜单移除 '监控该文件' 功能按钮",
    LocaleKey.setting_notifyAddView: "已添加 '浏览文件版本树' 到右键菜单",
    LocaleKey.setting_notifyRemoveView: "已从右键菜单移除 '浏览文件版本树' 功能按钮",
    LocaleKey.setting_notifyEnableAutostart: "已启用开机自启",
    LocaleKey.setting_notifyDisableAutostart: "已禁用开机自启",
    LocaleKey.setting_notifyAddExpress: "已添加 '快速备份该文件' 到右键菜单",
    LocaleKey.setting_notifyRemoveExpress: "已从右键菜单移除 '快速备份该文件' 功能按钮",

    LocaleKey.vertree_title: "Vertree维树",
    LocaleKey.vertree_fileTreeTitle: "%a.%a 文本版本树",

    LocaleKey.monitcard_monitorStatus: "%a的监控已经%a",
    LocaleKey.monitcard_backupFolder: "备份文件夹：%a",
    LocaleKey.monitcard_openBackupFolder: "打开备份文件夹",
    LocaleKey.monitcard_delete: "删除监控任务",
    LocaleKey.monitcard_pause: "暂停", // Assuming '暂停'/'恢复' toggle text
    LocaleKey.monitcard_clean: "清理备份文件夹",
    LocaleKey.monitcard_cleanSuccess: "清理备份文件夹 %a 成功",
    LocaleKey.monitcard_cleanFail: "清理备份文件夹 %a 失败",
    LocaleKey.monitcard_cleanDialogTitle: "确认清理备份文件夹",
    LocaleKey.monitcard_cleanDialogContent: "确定要清理备份文件夹 %a 中的所有文件吗？此操作不可撤销。",
    LocaleKey.monitcard_cleanDialogCancel: "取消",
    LocaleKey.monitcard_cleanDialogConfirm: "确认",
    LocaleKey.monitcard_statusRunning: "监控中..",
    LocaleKey.monitcard_statusStopped: "已暂停",

    LocaleKey.filetree_inputLabelTitle: "请输入备注",
    LocaleKey.filetree_inputLabelHint: "请输入备注（可选）",
    LocaleKey.filetree_inputCancel: "取消",
    LocaleKey.filetree_inputConfirm: "确认",

    LocaleKey.fileleaf_noLabel: "无备注",
    LocaleKey.fileleaf_lastModified: "最后修改",
    LocaleKey.fileleaf_openTitle: "打开文件 %a.%a ?",
    LocaleKey.fileleaf_openContent: "即将打开 \"%a.%a\" %a 版",
    LocaleKey.fileleaf_cancel: "取消",
    LocaleKey.fileleaf_confirm: "确认",
    LocaleKey.fileleaf_menuBackup: "备份版本",
    LocaleKey.fileleaf_menuMonit: "监控变更",
    LocaleKey.fileleaf_menuProperty: "属性",
    LocaleKey.fileleaf_monitTitle: "确认文件监控",
    LocaleKey.fileleaf_monitContent: "确定要开始监控文件 \"%a.%a\" 吗？",
    LocaleKey.fileleaf_notifyFailed: "Vertree监控失败，",
    LocaleKey.fileleaf_notifySuccess: "Vertree已开始监控文件",
    LocaleKey.fileleaf_notifyHint: "点击我打开备份目录",

    LocaleKey.fileleaf_propertyTitle: "文件属性",
    LocaleKey.fileleaf_propertyFullname: "全名:",
    LocaleKey.fileleaf_propertyName: "名称:",
    LocaleKey.fileleaf_propertyLabel: "备注:",
    LocaleKey.fileleaf_propertyInputLabel: "请输入备注",
    LocaleKey.fileleaf_propertyVersion: "版本:",
    LocaleKey.fileleaf_propertyExt: "扩展名:",
    LocaleKey.fileleaf_propertyPath: "路径:",
    LocaleKey.fileleaf_propertySize: "文件大小:",
    LocaleKey.fileleaf_propertyCreated: "创建时间:",
    LocaleKey.fileleaf_propertyModified: "修改时间:",
    LocaleKey.fileleaf_propertyClose: "关闭",
  };

  static const Map<LocaleKey, String> _JA = {
    LocaleKey.registry_backupKeyName: "バックアップファイル VerTree",
    LocaleKey.registry_expressBackupKeyName: "クイックバックアップファイル VerTree",
    LocaleKey.registry_monitorKeyName: "ファイル変更監視 VerTree",
    LocaleKey.registry_viewTreeKeyName: "ファイルバージョンツリー表示 VerTree",

    LocaleKey.app_confirmExitTitle: "終了の確認",
    LocaleKey.app_confirmExitContent: "アプリを終了してもよろしいですか？",
    LocaleKey.app_minimize: "最小化",
    LocaleKey.app_exit: "終了",

    LocaleKey.app_trayNotificationTitle: "Vertree はバックグラウンドで実行中",
    LocaleKey.app_trayNotificationContent: "ファイルバージョンツリーマネージャー 🌲（クリックして開く）",

    LocaleKey.app_monitStartedTitle: "Vertree は監視を開始しました",
    LocaleKey.app_monitStartedContent: "クリックして監視タスクを表示",

    LocaleKey.app_backupFailed: "Vertree のバックアップに失敗しました",
    LocaleKey.app_backupSuccessTitle: "Vertree はファイルをバックアップしました",
    LocaleKey.app_backupSuccessContent: "クリックして新しいファイルを開く",

    LocaleKey.app_enterLabelTitle: "バックアップのメモを入力してください（任意）",
    LocaleKey.app_enterLabelHint: "メモ（任意）",
    LocaleKey.app_cancelBackup: "バックアップをキャンセル",
    LocaleKey.app_confirm: "確認",

    LocaleKey.app_cancelNotificationTitle: "Vertree バックアップがキャンセルされました",
    LocaleKey.app_cancelNotificationContent: "ユーザーがバックアップ操作をキャンセルしました",

    LocaleKey.app_labelDialogError: "メモ入力ダイアログの作成に失敗しました：",

    LocaleKey.app_enableMonitTitle: "監視を有効にしますか？",
    LocaleKey.app_enableMonitContent: "バックアップ後の新しいバージョンを監視しますか？",
    LocaleKey.app_yes: "はい",
    LocaleKey.app_no: "いいえ",

    LocaleKey.app_monitFailedTitle: "Vertree の監視に失敗しました",
    LocaleKey.app_monitSuccessTitle: "Vertree はファイルの監視を開始しました",
    LocaleKey.app_monitSuccessContent: "クリックしてバックアップフォルダーを開く",

    LocaleKey.brand_title: 'Vertree',
    LocaleKey.brand_slogan: 'Vertree、ツリー型のファイルバージョン管理🌲、すべての変更を安全に！',
    LocaleKey.brand_monitorPage: 'モニター画面',
    LocaleKey.brand_settingPage: '設定画面',
    LocaleKey.brand_exit: 'Vertreeを完全終了',
    LocaleKey.brand_initTitle: '初期設定',
    LocaleKey.brand_initContent: 'Vertreeに右クリックメニューと自動起動を許可しますか？',
    LocaleKey.brand_cancel: 'キャンセル',
    LocaleKey.brand_confirm: '確認',
    LocaleKey.brand_initDoneTitle: 'Vertreeの初期設定が完了しました！',
    LocaleKey.brand_initDoneBody: 'さあ、始めましょう！',

    LocaleKey.monit_title: 'Vertree モニター',
    LocaleKey.monit_empty: '監視タスクはありません',
    LocaleKey.monit_addSuccess: '監視タスクを追加しました: %a',
    LocaleKey.monit_addFail: 'タスクの追加に失敗しました: %a',
    LocaleKey.monit_fileNotSelected: 'ファイルが選択されていません',
    LocaleKey.monit_deleteDialogTitle: '削除の確認',
    LocaleKey.monit_deleteDialogContent: '監視タスク %a を削除しますか？対応するバックアップフォルダとすべてのバックアップ内容も削除されます！',
    // Updated JA translation
    LocaleKey.monit_cancel: 'キャンセル',
    LocaleKey.monit_delete: '削除',
    LocaleKey.monit_deleteSuccess: '監視タスクを削除しました: %a',
    LocaleKey.monit_searchHint: "キーワードで絞り込む...",
    LocaleKey.monit_noResults: "一致するタスクが見つかりません",

    LocaleKey.monit_cleanInvalidTasksDialogTitle: "無効な監視タスクのクリーンアップ",
    LocaleKey.monit_invalidTaskDialogItem: "ファイルパス：%a、バックアップパス：%a",
    LocaleKey.monit_cleanInvalidTaskDialogBackupDirNotSet: "バックアップパスが設定されていません",
    LocaleKey.monit_cleanInvalidTaskDialogNoInvalidTasks: "無効な監視タスクは見つかりませんでした",
    LocaleKey.monit_cleanInvalidTaskDialogCleaned: "無効な監視タスクが正常にクリーンアップされました",

    LocaleKey.setting_title: "設定",
    LocaleKey.setting_language: '言語',
    LocaleKey.setting_titleBar: "Vertree 設定",
    LocaleKey.setting_contextMenuGroup: "右クリックメニューのオプション",
    LocaleKey.setting_addBackupMenu: "「このファイルをバックアップ」を右クリックメニューに追加",
    LocaleKey.setting_addExpressBackupMenu: "「このファイルを即時バックアップ」を右クリックメニューに追加",
    LocaleKey.setting_addMonitorMenu: "「このファイルを監視」を右クリックメニューに追加",
    LocaleKey.setting_addViewtreeMenu: "「バージョンツリーを表示」を右クリックメニューに追加",
    LocaleKey.setting_enableAutostart: "起動時に Vertree を自動実行（推奨）",
    LocaleKey.setting_openConfig: "config.json を開く",
    LocaleKey.setting_visitWebsite: "公式サイトを訪問",
    LocaleKey.setting_openGithub: "GitHub リポジトリを見る",
    LocaleKey.setting_notifyAddBackup: "「このファイルバージョンをバックアップ」が右クリックメニューに追加されました",
    LocaleKey.setting_notifyRemoveBackup: "「このファイルバージョンをバックアップ」が右クリックメニューから削除されました",
    LocaleKey.setting_notifyAddMonitor: "「このファイルを監視」が右クリックメニューに追加されました",
    LocaleKey.setting_notifyRemoveMonitor: "「このファイルを監視」が右クリックメニューから削除されました",
    LocaleKey.setting_notifyAddView: "「バージョンツリーを表示」が右クリックメニューに追加されました",
    LocaleKey.setting_notifyRemoveView: "「バージョンツリーを表示」が右クリックメニューから削除されました",
    LocaleKey.setting_notifyEnableAutostart: "自動起動が有効になりました",
    LocaleKey.setting_notifyDisableAutostart: "自動起動が無効になりました",
    LocaleKey.setting_notifyAddExpress: "「このファイルを即時バックアップ」が右クリックメニューに追加されました",
    LocaleKey.setting_notifyRemoveExpress: "「このファイルを即時バックアップ」が右クリックメニューから削除されました",

    LocaleKey.vertree_title: "Vertreeバージョンツリー",
    LocaleKey.vertree_fileTreeTitle: "%a.%a ファイルバージョンツリー",

    LocaleKey.monitcard_monitorStatus: "%aの監視は%aされました",
    // Needs context for %a (e.g., 開始/停止 - started/stopped)
    LocaleKey.monitcard_backupFolder: "バックアップフォルダ：%a",
    LocaleKey.monitcard_openBackupFolder: "バックアップフォルダを開く",
    LocaleKey.monitcard_delete: "監視タスクを削除",
    LocaleKey.monitcard_pause: "一時停止",
    // Assuming '一時停止'/'再開' toggle text
    LocaleKey.monitcard_clean: "バックアップフォルダをクリーンアップ",
    LocaleKey.monitcard_cleanSuccess: "バックアップフォルダ %a のクリーンアップに成功しました",
    LocaleKey.monitcard_cleanFail: "バックアップフォルダ %a のクリーンアップに失敗しました",
    LocaleKey.monitcard_cleanDialogTitle: "バックアップフォルダのクリーンアップ確認",
    LocaleKey.monitcard_cleanDialogContent: "バックアップフォルダ %a 内のすべてのファイルをクリーンアップしますか？この操作は元に戻せません。",
    LocaleKey.monitcard_cleanDialogCancel: "キャンセル",
    LocaleKey.monitcard_cleanDialogConfirm: "確認",

    LocaleKey.filetree_inputLabelTitle: "ラベルを入力してください",
    LocaleKey.filetree_inputLabelHint: "ラベルを入力してください（任意）",
    LocaleKey.filetree_inputCancel: "キャンセル",
    LocaleKey.filetree_inputConfirm: "確認",

    LocaleKey.fileleaf_noLabel: "備考なし",
    LocaleKey.fileleaf_lastModified: "最終更新",
    LocaleKey.fileleaf_openTitle: "ファイル %a.%a を開きますか？",
    LocaleKey.fileleaf_openContent: "「%a.%a」バージョン %a を開こうとしています",
    LocaleKey.fileleaf_cancel: "キャンセル",
    LocaleKey.fileleaf_confirm: "確認",
    LocaleKey.fileleaf_menuBackup: "バックアップバージョン",
    LocaleKey.fileleaf_menuMonit: "変更を監視",
    LocaleKey.fileleaf_menuProperty: "プロパティ",
    LocaleKey.fileleaf_monitTitle: "ファイル監視の確認",
    LocaleKey.fileleaf_monitContent: "ファイル「%a.%a」の監視を開始しますか？",
    LocaleKey.fileleaf_notifyFailed: "Vertreeの監視に失敗しました、",
    LocaleKey.fileleaf_notifySuccess: "Vertreeがファイルの監視を開始しました",
    LocaleKey.fileleaf_notifyHint: "クリックしてバックアップフォルダを開く",

    LocaleKey.fileleaf_propertyTitle: "ファイルプロパティ",
    LocaleKey.fileleaf_propertyFullname: "フルネーム：",
    LocaleKey.fileleaf_propertyName: "名前：",
    LocaleKey.fileleaf_propertyLabel: "ラベル：",
    LocaleKey.fileleaf_propertyInputLabel: "ラベルを入力してください",
    LocaleKey.fileleaf_propertyVersion: "バージョン：",
    LocaleKey.fileleaf_propertyExt: "拡張子：",
    LocaleKey.fileleaf_propertyPath: "パス：",
    LocaleKey.fileleaf_propertySize: "ファイルサイズ：",
    LocaleKey.fileleaf_propertyCreated: "作成日時：",
    LocaleKey.fileleaf_propertyModified: "更新日時：",
    LocaleKey.fileleaf_propertyClose: "閉じる",
  };
}
