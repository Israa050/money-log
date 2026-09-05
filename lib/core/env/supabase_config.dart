/// Supabase credentials, supplied at build/run time via
/// `--dart-define-from-file=env.json` (see env.example.json for the shape).
///
/// These are read from compile-time environment variables rather than
/// hardcoded so the real values never need to be committed to git.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True once both values have actually been supplied via --dart-define.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
