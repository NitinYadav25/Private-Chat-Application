abstract final class ApiEndpoints {
  // Configurable base URL:
  // On Android emulator: http://10.0.2.2:5000
  // On real device: http://<LAN_IP>:5000 or production Render URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ghostconv-backend.onrender.com',
  );

  static const String health = '/health';
  static const String rooms = '/rooms';
  static const String joinRoom = '/rooms/join';
  static String roomById(String id) => '/rooms/$id';
  static const String signMedia = '/media/sign';
}

