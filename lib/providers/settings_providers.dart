// lib/providers/settings_providers.dart
// Persisted user-facing app settings (notifications preference, theme mode).
// Backed by SharedPreferences so choices survive app restarts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kNotificationsEnabledKey = 'settings_notifications_enabled';
const _kDarkModeEnabledKey = 'settings_dark_mode_enabled';

/// Whether the user wants notifications. NOTE: this only persists the
/// user's preference — there is no push-notification backend (FCM) wired
/// up in this project yet, so toggling it doesn't itself send/stop pushes.
final notificationsEnabledProvider =
StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
  return _BoolPrefNotifier(_kNotificationsEnabledKey, defaultValue: true);
});

/// App-wide theme mode. Most AstraFlix screens are hand-styled with fixed
/// brand-dark colors (AppColors.*) rather than Theme.of(context), so this
/// genuinely switches Material's own widgets (buttons, dialogs, text
/// fields, chrome) between light/dark; the custom screens keep their
/// brand-dark look either way — deliberate design choice, not a bug.
final darkModeEnabledProvider =
StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
  return _BoolPrefNotifier(_kDarkModeEnabledKey, defaultValue: true);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final isDark = ref.watch(darkModeEnabledProvider);
  return isDark ? ThemeMode.dark : ThemeMode.light;
});

class _BoolPrefNotifier extends StateNotifier<bool> {
  final String _key;
  _BoolPrefNotifier(this._key, {required bool defaultValue}) : super(defaultValue) {
    _load(defaultValue);
  }

  Future<void> _load(bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? defaultValue;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}