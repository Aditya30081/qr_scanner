import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _openURLAutoKey = "auto";
  static const String _vibratekey = "vibrate";
  static const String _DarkModekey = "mode";

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

  Future<void> saveLaunchBool(bool firstTimeLaunch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    /*bool newStatus = !isFeatureEnabled;*/
    await prefs.setBool('first_launch', firstTimeLaunch);

  }

  Future<bool> loadFeatureStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch')?? true;
    return isFirstLaunch;

  }
}
