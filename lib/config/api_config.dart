/// OMDb API configuration.
///
/// There is no free official IMDb API (IMDb's own API is enterprise-only), so
/// this app uses OMDb — the standard free stand-in that serves IMDb data.
///
/// Two ways to supply a key:
///   1. Replace [_hardCodedKey] below with your key.
///   2. Pass it at run time (preferred, keeps it out of source control):
///        flutter run --dart-define=OMDB_API_KEY=yourkeyhere
///
/// Get a free key (1,000 lookups/day): https://www.omdbapi.com/apikey.aspx
class ApiConfig {
  ApiConfig._();

  /// Paste your key here, or leave the placeholder and use --dart-define.
  static const String _hardCodedKey = 'PASTE_YOUR_KEY_HERE';

  /// A key passed via `--dart-define=OMDB_API_KEY=...` wins over the hard-coded
  /// value so you never have to edit source to run the app.
  static const String _definedKey =
      String.fromEnvironment('OMDB_API_KEY', defaultValue: '');

  /// The effective API key (dart-define takes priority).
  static String get apiKey => _definedKey.isNotEmpty ? _definedKey : _hardCodedKey;

  /// OMDb JSON endpoint.
  static const String endpoint = 'https://www.omdbapi.com/';

  /// Whether a usable key has been configured. When false the app still runs —
  /// it just shows an "add your key" card instead of live metadata.
  static bool get hasKey =>
      apiKey.isNotEmpty && apiKey != 'PASTE_YOUR_KEY_HERE';
}
