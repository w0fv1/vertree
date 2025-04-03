import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:toastification/toastification.dart';
import 'package:vertree/component/FileUtils.dart';
import 'dart:io';
import 'package:vertree/main.dart';

/// 初始化本地通知
Future<void> initLocalNotifier() async {
  await localNotifier.setup(
    appName: 'Vertree',
    shortcutPolicy: ShortcutPolicy.requireCreate, // 仅适用于 Windows
  );
}

/// 显示通知
Future<void> showWindowsNotification(String title, String description) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onShow = () {
    logger.info('通知已显示: ${notification.identifier}');
  };

  notification.onClose = (closeReason) {
    logger.info('通知已关闭: ${notification.identifier} - 关闭原因: $closeReason');
  };

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
  };

  await notification.show();
}

/// 显示通知（点击后打开文件）
Future<void> showWindowsNotificationWithFile(String title, String description, String filePath) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
    FileUtils.openFile(filePath);
  };

  await notification.show();
}
/// 显示通知（点击后打开文件夹）
Future<void> showWindowsNotificationWithFolder(String title, String description, String folderPath) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
    FileUtils.openFolder(folderPath);

  };

  await notification.show();
}
/// 显示通知（点击后执行自定义任务）
Future<void> showWindowsNotificationWithTask(
    String title, String description, Function task) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
    logger.info('用户点击了通知: ${notification.identifier}');
    task.call(); // 执行传入的任务
    logger.info('用户点击了通知: ${notification.identifier}');
    logger.info('用户点击了通知: ${notification.identifier}');

  };

  await notification.show();
}



void showToast(String message) {
  toastification.show(
    title: Text(message),
    autoCloseDuration: const Duration(seconds: 3),
    style: ToastificationStyle.simple,
    showProgressBar: false,
    alignment: Alignment.bottomCenter, // 设置在底部中央显示
  );
}
