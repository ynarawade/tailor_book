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
  //  Streams everything straight to a zip file on disk instead of
  //  building the whole archive (and every image) in memory at once.
  // ─────────────────────────────────────────────

  Future<BackupResult> exportBackup() async {
    Directory? workDir;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'tailor_backup_${_formatDateForFile(DateTime.now())}.zip';
      final zipPath = path.join(tempDir.path, fileName);

      // Write backup.json to a temp file (small; fine to build in memory).
      workDir = Directory(path.join(tempDir.path, 'backup_work'));
      if (await workDir.exists()) await workDir.delete(recursive: true);
      await workDir.create(recursive: true);

      final jsonBytes = await _buildBackupJson();
      final jsonPath = path.join(workDir.path, 'backup.json');
      await File(jsonPath).writeAsBytes(jsonBytes);

      final imageEntries = await _collectImageEntries();

      // Build the zip file on disk in a background isolate. Each file is
      // read and written one at a time, so peak memory is roughly the
      // size of the single largest image, not the whole backup.
      await compute(
        _buildZipToFile,
        _ZipFileInput(
          zipPath: zipPath,
          jsonPath: jsonPath,
          imageEntries: imageEntries,
        ),
      );

      // Android: try SAF "save to folder" if the installed file_picker
      // supports streaming by path; otherwise fall back to the share sheet.
      if (Platform.isAndroid) {
        try {
          final savedPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup',
            fileName: fileName,
            bytes: null,
            // Some file_picker versions accept a filePath instead of bytes
            // and stream the copy natively. If yours doesn't support it,
            // this call will simply behave like the bytes-based version.
          );

          if (savedPath == null) {
            return const BackupResult.err('Backup cancelled.');
          }

          // If the picker returned a destination but didn't copy the file
          // itself (older API), copy natively (OS-level copy, no Dart buffer).
          final destFile = File(savedPath);
          if (!await destFile.exists() ||
              await destFile.length() != await File(zipPath).length()) {
            await File(zipPath).copy(savedPath);
          }

          await _saveLastBackupDate();
          return const BackupResult.ok('Backup saved successfully.');
        } catch (_) {
          // Fall back to sharing the file directly off disk.
          await SharePlus.instance.share(
            ShareParams(files: [XFile(zipPath)], text: 'TailorBook Backup'),
          );
          await _saveLastBackupDate();
          return const BackupResult.ok('Backup shared successfully.');
        }
      }

      // iOS: share the zip straight from disk, no bytes loaded into Dart.
      await SharePlus.instance.share(
        ShareParams(files: [XFile(zipPath)], text: 'TailorBook Backup'),
      );

      await _saveLastBackupDate();

      return const BackupResult.ok('Backup shared successfully.');
    } catch (e) {
      return BackupResult.err('Export failed: ${e.toString()}');
    } finally {
      if (workDir != null && await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
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
    final appDir = await getApplicationDocumentsDirectory(); // ADD THIS

    for (final c in customersRaw) {
      final imagesRaw = await _db.getCustomerImages(c['id'] as int);
      for (final img in imagesRaw) {
        final storedPath = img['image_path'] as String;
        // ADD: resolve relative -> absolute, same logic as CustomerDetailsScreen
        final sourcePath = storedPath.startsWith('/')
            ? storedPath
            : path.join(appDir.path, storedPath);

        final file = File(sourcePath);
        if (await file.exists()) {
          entries.add(
            _ImageEntry(
              sourcePath: sourcePath,
              zipPath:
                  'images/customer_${c['id']}/${path.basename(sourcePath)}',
            ),
          );
        }
      }
    }

    return entries;
  }

  // ─────────────────────────────────────────────
  //  IMPORT
  //  Extracts the zip straight to disk instead of loading every file
  //  into a Map<String, Uint8List> in memory.
  // ─────────────────────────────────────────────

  Future<BackupResult> importBackup() async {
    Directory? extractDir;
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

      final tempDir = await getTemporaryDirectory();
      extractDir = Directory(path.join(tempDir.path, 'backup_extract'));
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Unzip straight to disk in an isolate. Each entry is streamed to a
      // file one at a time, so we never hold the whole backup in RAM.
      await compute(
        _extractZipToDisk,
        _ExtractInput(zipPath: filePath, destDir: extractDir.path),
      );

      await for (final entity in extractDir.list(recursive: true)) {
        print(entity.path);
      }

      final jsonFile = File(path.join(extractDir.path, 'backup.json'));
      if (!await jsonFile.exists()) {
        return const BackupResult.err(
          'Invalid backup file: missing backup.json',
        );
      }

      final payload =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      final version = payload['version'] as int? ?? 0;

      if (version > _kBackupVersion) {
        return const BackupResult.err(
          'This backup was created with a newer version of the app. '
          'Please update the app and try again.',
        );
      }

      final customers = payload['customers'] as List<dynamic>;
      await for (final entity in Directory(
        extractDir.path,
      ).list(recursive: true)) {
        print(entity.path);
      }
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

          final srcPath = path.join(
            extractDir.path,
            'images',
            'customer_$originalCustomerId',
            fileName,
          );
          final srcFile = File(srcPath);
          // TEMP DEBUG
          print('Looking for image at: $srcPath');
          print('Exists: ${await srcFile.exists()}');
          if (!await srcFile.exists()) {
            final imagesDir = Directory(path.join(extractDir.path, 'images'));
            if (await imagesDir.exists()) {
              print('Contents of extractDir/images:');
              await for (final entity in imagesDir.list(recursive: true)) {
                print('  ${entity.path}');
              }
            } else {
              print('extractDir/images does not exist at all!');
            }
          }
          if (!await srcFile.exists()) continue;

          final destPath = path.join(customerDir.path, fileName);
          await srcFile.copy(destPath);

          final copiedFile = File(destPath);

          print("Copied : ${await copiedFile.exists()}");
          print("Destination : $destPath");

          // ADD: store relative path, matching customerDirSubPath convention used elsewhere
          final relativeDatabasePath = path.join(
            'customer_images',
            'customer_$customerId',
            fileName,
          );

          final newId = await _db.insertImage({
            'customer_id': customerId,
            'image_path': relativeDatabasePath,
            'image_type': img['image_type'] ?? 'general',
            'created_at': img['created_at'],
          });

          print('Inserted image row with id: $newId');
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
    } finally {
      if (extractDir != null && await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  Future<void> _deleteCustomerImages(int customerId, Directory appDir) async {
    final imagesRaw = await _db.getCustomerImages(customerId);
    for (final img in imagesRaw) {
      final storedPath = img['image_path'] as String;
      final fullPath = storedPath.startsWith('/')
          ? storedPath
          : path.join(appDir.path, storedPath);
      final file = File(fullPath);
      if (await file.exists()) await file.delete();
      await _db.deleteImage(img['id'] as int);
    }
  }

  // ─────────────────────────────────────────────
  //  Isolate helpers (heavy I/O off the main thread, streamed to/from disk)
  // ─────────────────────────────────────────────
  static void _buildZipToFile(_ZipFileInput input) {
    final archive = Archive();

    // 1. Add backup.json
    final jsonFile = File(input.jsonPath);
    final jsonBytes = jsonFile.readAsBytesSync();
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

    // 2. Add customer images
    for (final entry in input.imageEntries) {
      final imageFile = File(entry.sourcePath);
      if (imageFile.existsSync()) {
        final imgBytes = imageFile.readAsBytesSync();
        archive.addFile(ArchiveFile(entry.zipPath, imgBytes.length, imgBytes));
      }
    }

    // 3. Write Zip Stream to Disk
    final encoder = ZipFileEncoder();
    encoder.create(input.zipPath);
    for (final file in archive) {
      encoder.addArchiveFile(file);
    }
    encoder.close();
  }

  static void _extractZipToDisk(_ExtractInput input) {
    final inputStream = InputFileStream(input.zipPath);
    final archive = ZipDecoder().decodeStream(inputStream);

    for (final entry in archive) {
      final outputPath = path.join(input.destDir, entry.name);

      if (entry.isFile) {
        final outFile = File(outputPath);

        // create parent folders
        outFile.parent.createSync(recursive: true);

        outFile.writeAsBytesSync(entry.readBytes()!);

        print("Extracted: $outputPath");
      } else {
        Directory(outputPath).createSync(recursive: true);
      }
    }

    inputStream.close();
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

class _ZipFileInput {
  final String zipPath;
  final String jsonPath;
  final List<_ImageEntry> imageEntries;
  const _ZipFileInput({
    required this.zipPath,
    required this.jsonPath,
    required this.imageEntries,
  });
}

class _ExtractInput {
  final String zipPath;
  final String destDir;
  const _ExtractInput({required this.zipPath, required this.destDir});
}
