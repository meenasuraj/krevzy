class SportsConfig {
  SportsConfig._();

  static const String apiSportsBaseUrl =
      'https://v3.football.api-sports.io';

  static const Duration requestTimeout = Duration(seconds: 20);

  static const String apiSportsKey = String.fromEnvironment(
    'API_SPORTS_KEY',
    defaultValue: '',
  );

  static bool get isApiSportsConfigured =>
      apiSportsKey.trim().isNotEmpty;
}