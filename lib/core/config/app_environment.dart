enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.enableVerboseLogs,
    required this.enableMockFallback,
  });

  final AppEnvironment environment;
  final String appName;
  final bool enableVerboseLogs;
  final bool enableMockFallback;

  static const development = AppConfig(
    environment: AppEnvironment.development,
    appName: 'Popcorn Dev',
    enableVerboseLogs: true,
    enableMockFallback: true,
  );

  static const staging = AppConfig(
    environment: AppEnvironment.staging,
    appName: 'Popcorn Staging',
    enableVerboseLogs: true,
    enableMockFallback: true,
  );

  static const production = AppConfig(
    environment: AppEnvironment.production,
    appName: 'Popcorn',
    enableVerboseLogs: false,
    enableMockFallback: false,
  );
}
