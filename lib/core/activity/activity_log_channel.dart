import 'dart:io';

import 'package:flutter/services.dart';

const String _kChannel = 'replymate/activity_log';

/// Pulls JSON lines written by Android background components into Dart.
class ActivityLogChannel {
  ActivityLogChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_kChannel);

  final MethodChannel _channel;

  /// Returns pending log lines (JSON); native clears the pending file after read.
  Future<List<String>> pullPendingLogs() async {
    if (!Platform.isAndroid) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('pullPendingLogs');
      if (raw == null) return const [];
      final out = <String>[];
      for (final e in raw) {
        if (e is String) {
          out.add(e);
        } else if (e != null) {
          out.add(e.toString());
        }
      }
      return out;
    } on MissingPluginException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
