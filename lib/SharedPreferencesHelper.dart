import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _openURLAutoKey = "auto";
  static const String _vibratekey = "vibrate";
  static const String _DarkModekey = "mode";
  static const String _DifficultyLevel = "level";

  void saveOpenURLAutoData(bool data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_openURLAutoKey, data);
  }

  Future<bool> getOpenURLAutoData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_openURLAutoKey) ?? true;
  }

  Future<void> saveVibrateData(bool data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibratekey, data);
  }

  Future<bool> getVibrateData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibratekey) ?? true;
  }

  Future<void> saveDarkModeData(bool data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_DarkModekey, data);
  }

  Future<bool> getDarkModeData() async {
    bool value =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light
            ? false
            : true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_DarkModekey) ?? value;
  }
  void saveDifficultyLevel(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_DifficultyLevel, data);
  }

  Future<String> getDifficultyLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_DifficultyLevel) ?? 'Easy';
  }
}
