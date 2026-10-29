class ApiConfig {
  /// Base URL of the ASP.NET Web API (IIS / IIS Express).
  ///
  /// Android emulator : http://10.0.2.2/ProgressMonitoringProject/api
  /// Physical device  : http://<your-pc-lan-ip>/ProgressMonitoringProject/api
  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10/ProgressMonitoringProject/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2/ProgressMonitoringProject/api',
  );
}
