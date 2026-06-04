import 'package:get/get.dart';
import '../../core/notifications/push_notification_service.dart';

class NotificationsController extends GetxController {
  final PushNotificationService _service = PushNotificationService.instance;

  void markAsRead(String id) {
    _service.markAsRead(id);
  }

  void markAllAsRead() {
    _service.markAllAsRead();
  }

  void deleteNotification(String id) {
    _service.deleteNotification(id);
  }

  void clearAll() {
    _service.clearAll();
  }
}
