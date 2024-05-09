part of '../hive_flutter.dart';

/// Flutter extensions for Hive.
extension HiveX on HiveInterface {
  /// Initializes Hive with the path from [directory].
  Future<void> initFlutter(
    String directory, [
    HiveStorageBackendPreference backendPreference = HiveStorageBackendPreference.native,
  ]) async {
    String? path;

    if (!kIsWeb) {
      path = directory;
    }

    init(
      path,
      backendPreference: backendPreference,
    );
  }
}
