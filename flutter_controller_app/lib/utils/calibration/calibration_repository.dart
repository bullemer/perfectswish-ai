/// Calibration repository for Mode C — Isar Persistence.
///
/// Saves and loads calibration profiles indexed by gym name and GPS.

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'calibration_profile.dart';

/// Repository for persisting calibration profiles.
class CalibrationRepository {
  Isar? _isar;

  /// Whether the repository has been initialized.
  bool get isInitialized => _isar != null;

  /// Initialize the Isar database.
  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [CalibrationProfileSchema],
      directory: dir.path,
      name: 'calibration',
    );
  }

  /// Close the database.
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Save a calibration profile.
  ///
  /// If a profile with the same gymName or gpsBucket exists, it will be updated.
  Future<int> save(CalibrationProfile profile) async {
    _ensureInitialized();

    profile.timestamp = DateTime.now();

    return await _isar!.writeTxn(() async {
      return await _isar!.calibrationProfiles.put(profile);
    });
  }

  /// Load profile by gym name.
  Future<CalibrationProfile?> loadByGym(String gymName) async {
    _ensureInitialized();

    return await _isar!.calibrationProfiles
        .where()
        .gymNameEqualTo(gymName)
        .sortByTimestampDesc()
        .findFirst();
  }

  /// Load profile by GPS bucket.
  ///
  /// [latitude] and [longitude] will be rounded to 3 decimal places.
  Future<CalibrationProfile?> loadByGPS(
      double latitude, double longitude) async {
    _ensureInitialized();

    final bucket = CameraSignature.gpsBucket(latitude, longitude);

    return await _isar!.calibrationProfiles
        .where()
        .gpsBucketEqualTo(bucket)
        .sortByTimestampDesc()
        .findFirst();
  }

  /// Load all profiles for a gym name.
  Future<List<CalibrationProfile>> loadAllByGym(String gymName) async {
    _ensureInitialized();

    return await _isar!.calibrationProfiles
        .where()
        .gymNameEqualTo(gymName)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Load the most recent profile.
  Future<CalibrationProfile?> loadMostRecent() async {
    _ensureInitialized();

    return await _isar!.calibrationProfiles
        .where()
        .sortByTimestampDesc()
        .findFirst();
  }

  /// Load profile matching current camera signature.
  ///
  /// Checks gym name or GPS, then validates camera signature.
  Future<CalibrationProfile?> loadMatching({
    String? gymName,
    double? latitude,
    double? longitude,
    required CameraSignature cameraSignature,
  }) async {
    _ensureInitialized();

    CalibrationProfile? profile;

    // Try gym name first
    if (gymName != null) {
      profile = await loadByGym(gymName);
    }

    // Try GPS if no gym profile
    if (profile == null && latitude != null && longitude != null) {
      profile = await loadByGPS(latitude, longitude);
    }

    // Validate camera signature
    if (profile != null && !cameraSignature.matches(profile)) {
      // Camera changed, profile is stale
      return null;
    }

    return profile;
  }

  /// Delete a profile by ID.
  Future<bool> delete(int id) async {
    _ensureInitialized();

    return await _isar!.writeTxn(() async {
      return await _isar!.calibrationProfiles.delete(id);
    });
  }

  /// Delete all profiles for a gym.
  Future<int> deleteByGym(String gymName) async {
    _ensureInitialized();

    return await _isar!.writeTxn(() async {
      return await _isar!.calibrationProfiles
          .where()
          .gymNameEqualTo(gymName)
          .deleteAll();
    });
  }

  /// Get count of all profiles.
  Future<int> count() async {
    _ensureInitialized();
    return await _isar!.calibrationProfiles.count();
  }

  /// List all gym names.
  Future<List<String>> listGymNames() async {
    _ensureInitialized();

    final profiles = await _isar!.calibrationProfiles
        .where()
        .distinctByGymName()
        .findAll();

    return profiles
        .map((p) => p.gymName)
        .whereType<String>()
        .toList();
  }

  void _ensureInitialized() {
    if (_isar == null) {
      throw StateError(
          'CalibrationRepository not initialized. Call init() first.');
    }
  }
}
