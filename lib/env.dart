class Env {
  /// Pásala en runtime: --dart-define=BASE_URL=http://192.168.1.50:8000
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.80:8005',
  );
}
