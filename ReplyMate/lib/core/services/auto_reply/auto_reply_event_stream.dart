import 'package:flutter/services.dart';

/// Native auto-reply engine events (dispatch, throttle, errors) for foreground UI.
class AutoReplyEventStream {
  AutoReplyEventStream._();

  static const EventChannel _channel = EventChannel(
    'replymate/auto_reply_events',
  );

  static Stream<dynamic> get stream => _channel.receiveBroadcastStream();
}
