import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

const _kBackupVersion = 1;
const _kLastBackupKey = 'last_backup_date';
const _kBackupExtension = 'zip';

/// Result wrapper so UI can show success / error without try-catching everywhere.
class BackupResult {
  final bool success;
  final String message;

  const BackupResult.ok(this.message) : success = true;
  const BackupResult.err(this.message) : success = false;
}

class BackupService {
  final DatabaseHelper _db = DatabaseHelper();

  // ─────────────────────────────────────────────
  //  Last backup date (stored in SharedPreferences)
  // ─────────────────────────────────────────────

  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastBackupKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _saveLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackupKey, DateTime.now().toIso8601String());
  }

  // ─────────────────────────────────────────────
  //  EXPORT
  // ─────────────────────────────────────────────

  Future<BackupResult> exportBackup() async {
    try {
      final jsonBytes = await _buildBackupJson();
      final imageEntries = await _collectImageEntries();

      final zipBytes = await compute(
        _buildZip,
        _ZipInput(jsonBytes: jsonBytes, imageEntries: imageEntries),
      );

      final fileName =
          'tailor_backup_${_formatDateForFile(DateTime.now())}.zip';

      // Android
      if (Platform.isAndroid) {
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          bytes: zipBytes,
        );

        if (outputFile == null) {
          return const BackupResult.err('Backup cancelled.');
        }

        await _saveLastBackupDate();

        return const BackupResult.ok('Backup saved successfully.');
      }

      // iOS
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileName));

      await tempFile.writeAsBytes(zipBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(tempFile.path)], text: 'TailorBook Backup'),
      );

      await _saveLastBackupDate();

      return const BackupResult.ok('Backup shared successfully.');
    } catch (e) {
      return BackupResult.err('Export failed: ${e.toString()}');
    }
  }

  Future<Uint8List> _buildBackupJson() async {
    final customersRaw = await _db.getAllCustomers();
    final List<Map<String, dynamic>> customersWithImages = [];

    for (final c in customersRaw) {
      final imagesRaw = await _db.getCustomerImages(c['id'] as int);
      final images = imagesRaw.map((img) {
        return {
          'image_type': img['image_type'],
          'created_at': img['created_at'],
          // Store only the filename; we rebuild the path on import
          'file_name': path.basename(img['image_path'] as String),
          // Keep original path so we can read the file during zip
          '_source_path': img['image_path'],
        };
      }).toList();

      customersWithImages.add({
        'id': c['id'],
        'name': c['name'],
        'mobile_number': c['mobile_number'],
        'created_at': c['created_at'],
        'images': images,
      });
    }

    final payload = {
      'version': _kBackupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'customers': customersWithImages,
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  Future<List<_ImageEntry>> _collectImageEntries() async {
    final customersRaw = await _db.getAllCustomers();
    final entries = <_ImageEntry>[];

    for (final c in customersRaw) {
      final imagesRaw = await _db.getCustomerImages(c['id'] as int);
      for (final img in imagesRaw) {
        final sourcePath = img['image_path'] as String;
        final file = File(sourcePath);
        if (await file.exists()) {
          entries.add(
            _ImageEntry(
              sourcePath: sourcePath,
              // zip path: images/customer_<id>/<filename>
              zipPath:
                  'images/customer_${c['id']}/${path.basename(sourcePath)}',
            ),
          );
        }
      }
    }

    return entries;
  }

  // Future<BackupResult> _saveToDownloadsAndroid(
  //   File tempFile,
  //   String fileName,
  // ) async {
  //   // Android 10 and below need WRITE_EXTERNAL_STORAGE
  //   if (await _needsStoragePermission()) {
  //     final status = await Permission.storage.request();
  //     if (!status.isGranted) {
  //       return const BackupResult.err(
  //         'Storage permission denied. Cannot save to Downloads.',
  //       );
  //     }
  //   }

  //   final downloadsPath = '/storage/emulated/0/Download/$fileName';
  //   await tempFile.copy(downloadsPath);
  //   await _saveLastBackupDate();
  //   return BackupResult.ok('Backup saved to Downloads/$fileName');
  // }

  // Future<bool> _needsStoragePermission() async {
  //   // Android 11+ (API 30+) doesn't need WRITE_EXTERNAL_STORAGE for Downloads
  //   // We check via permission_handler; if status is not applicable, skip.
  //   final status = await Permission.storage.status;
  //   return status != PermissionStatus.permanentlyDenied &&
  //       !Platform.isIOS &&
  //       (await _androidSdkVersion()) <= 29;
  // }

  // Future<int> _androidSdkVersion() async {
  //   // Defaults to a high number (safe) if we can't determine
  //   try {
  //     final result = await Process.run('getprop', ['ro.build.version.sdk']);
  //     return int.tryParse(result.stdout.toString().trim()) ?? 30;
  //   } catch (_) {
  //     return 30;
  //   }
  // }

  // ─────────────────────────────────────────────
  //  IMPORT
  // ─────────────────────────────────────────────

  // Replace only the importBackup() method in backup_service.dart
  // The rest of the file stays exactly the same.

  Future<BackupResult> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
        dialogTitle: 'Select a .zip file',
      );

      if (result == null || result.files.single.path == null) {
        return const BackupResult.err('No file selected.');
      }

      final filePath = result.files.single.path!;

      // On iOS with FileType.any, validate extension ourselves
      if (!filePath.toLowerCase().endsWith('.$_kBackupExtension')) {
        return BackupResult.err(
          'Invalid file type. Please select a .$_kBackupExtension file.',
        );
      }

      final backupFile = File(filePath);
      final zipBytes = await backupFile.readAsBytes();

      // Unzip in isolate
      final extracted = await compute(_extractZip, zipBytes);

      // Parse JSON
      final jsonRaw = extracted['backup.json'];
      if (jsonRaw == null) {
        return const BackupResult.err(
          'Invalid backup file: missing backup.json',
        );
      }

      final payload = jsonDecode(utf8.decode(jsonRaw)) as Map<String, dynamic>;
      final version = payload['version'] as int? ?? 0;

      if (version > _kBackupVersion) {
        return const BackupResult.err(
          'This backup was created with a newer version of the app. '
          'Please update the app and try again.',
        );
      }

      final customers = payload['customers'] as List<dynamic>;

      final appDir = await getApplicationDocumentsDirectory();
      int restored = 0;
      int overwritten = 0;

      for (final raw in customers) {
        final c = raw as Map<String, dynamic>;
        final mobile = c['mobile_number'] as String;
        final images = c['images'] as List<dynamic>;

        final existing = await _db.getCustomerByMobile(mobile);
        int customerId;

        if (existing != null) {
          customerId = existing['id'] as int;
          await _db.updateCustomer(customerId, {
            'name': c['name'],
            'mobile_number': mobile,
          });
          await _deleteCustomerImages(customerId, appDir);
          overwritten++;
        } else {
          customerId = await _db.insertCustomer({
            'name': c['name'],
            'mobile_number': mobile,
            'created_at': c['created_at'],
          });
          restored++;
        }

        final customerDir = Directory(
          path.join(appDir.path, 'customer_images', 'customer_$customerId'),
        );
        if (!await customerDir.exists()) {
          await customerDir.create(recursive: true);
        }

        for (final imgRaw in images) {
          final img = imgRaw as Map<String, dynamic>;
          final originalCustomerId = c['id'];
          final fileName = img['file_name'] as String;
          final zipKey = 'images/customer_$originalCustomerId/$fileName';
          final fileBytes = extracted[zipKey];

          if (fileBytes == null) continue;

          final destPath = path.join(customerDir.path, fileName);
          await File(destPath).writeAsBytes(fileBytes);

          await _db.insertImage({
            'customer_id': customerId,
            'image_path': destPath,
            'image_type': img['image_type'] ?? 'general',
            'created_at': img['created_at'],
          });
        }
      }

      final summary = StringBuffer('Restore complete! ');
      if (restored > 0) summary.write('$restored new customer(s) added. ');
      if (overwritten > 0) {
        summary.write('$overwritten customer(s) overwritten.');
      }

      return BackupResult.ok(summary.toString().trim());
    } catch (e) {
      return BackupResult.err('Import failed: ${e.toString()}');
    }
  }

  Future<void> _deleteCustomerImages(int customerId, Directory appDir) async {
    final imagesRaw = await _db.getCustomerImages(customerId);
    for (final img in imagesRaw) {
      final file = File(img['image_path'] as String);
      if (await file.exists()) await file.delete();
      await _db.deleteImage(img['id'] as int);
    }
  }

  // ─────────────────────────────────────────────
  //  Isolate helpers (heavy I/O off the main thread)
  // ─────────────────────────────────────────────

  static Uint8List _buildZip(_ZipInput input) {
    final encoder = ZipEncoder();
    final archive = Archive();

    // Add backup.json
    archive.addFile(
      ArchiveFile('backup.json', input.jsonBytes.length, input.jsonBytes),
    );

    // Add image files
    for (final entry in input.imageEntries) {
      final bytes = File(entry.sourcePath).readAsBytesSync();
      archive.addFile(ArchiveFile(entry.zipPath, bytes.length, bytes));
    }

    return Uint8List.fromList(encoder.encode(archive));
  }

  static Map<String, Uint8List> _extractZip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final result = <String, Uint8List>{};

    for (final file in archive) {
      if (!file.isFile) continue;
      result[file.name] = Uint8List.fromList(file.content as List<int>);
    }

    return result;
  }

  // ─────────────────────────────────────────────
  //  Utility
  // ─────────────────────────────────────────────

  String _formatDateForFile(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '${d}_${m}_$y';
  }
}

// ─── Data classes for isolate communication ───────────────────────────────────

class _ImageEntry {
  final String sourcePath;
  final String zipPath;
  const _ImageEntry({required this.sourcePath, required this.zipPath});
}

class _ZipInput {
  final Uint8List jsonBytes;
  final List<_ImageEntry> imageEntries;
  const _ZipInput({required this.jsonBytes, required this.imageEntries});
}
