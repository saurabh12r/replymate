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

  /// Saves [filePath] to the public Downloads folder on Android via MediaStore.
  /// Returns the saved URI/path on success, throws on failure.
  Future<String> saveFileToDownloads({
    required String filePath,
    required String fileName,
    String mimeType = 'text/csv',
  }) async {
    if (!Platform.isAndroid) {
      return filePath;
    }
    try {
      final result = await _channel.invokeMethod<String>(
        'saveFileToDownloads',
        {'filePath': filePath, 'fileName': fileName, 'mimeType': mimeType},
      );
      return result ?? filePath;
    } on PlatformException catch (e) {
      throw Exception('Failed to save to Downloads: ${e.message}');
    }
  }
}
