import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// NOTE: Do NOT name your class ImagePicker — that name belongs to the package.
// We call this ImageCompressUtil to make its purpose clear.

class ImageCompressUtil {
  // Call this after the user picks an image.
  // It saves a permanent compressed copy and returns that file.
  // Returns null if compression fails.
  static Future<XFile?> compressAndSave(XFile pickedImage) async {
    // Step 1: Get a permanent folder inside the app's documents directory.
    // Unlike cache, this folder is NOT cleared by the OS automatically.
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'customer_images'));

    // Create the folder if it doesn't exist yet
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // Step 2: Build a unique filename using timestamp
    // e.g. customer_images/img_1718123456789.jpg
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(imagesDir.path, fileName);

    // Step 3: Log original size so you can see the difference
    final originalBytes = await pickedImage.readAsBytes();
    final originalKB = originalBytes.length / 1024;
    if (kDebugMode) {
      print('Original size: ${originalKB.toStringAsFixed(1)} KB');
    }

    // Step 4: Compress and save to targetPath
    // quality: 75 = good balance between quality and size
    // minWidth/minHeight: cap resolution so measurement photos stay readable
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      pickedImage.path, // source: the temp file from image_picker
      targetPath, // destination: permanent file in app documents
      quality: 75,
      minWidth: 1024,
      minHeight: 1024,
    );

    // Step 5: Log compressed size
    if (result != null && kDebugMode) {
      final compressedBytes = await result.readAsBytes();
      final compressedKB = compressedBytes.length / 1024;
      print('Compressed size: ${compressedKB.toStringAsFixed(1)} KB');
      print(
        'Saved ${((1 - compressedKB / originalKB) * 100).toStringAsFixed(0)}% space',
      );
    }

    return result; // null if compression failed
  }

  // Call this to compress a list of picked images (e.g. from pickMultiImage)
  static Future<List<XFile>> compressAll(List<XFile> pickedImages) async {
    final List<XFile> compressed = [];

    for (final img in pickedImages) {
      final result = await compressAndSave(img);
      if (result != null) {
        compressed.add(result);
      }
    }

    return compressed;
  }
}
