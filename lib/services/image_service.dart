import 'dart:io';
import 'package:uploadcare_client/uploadcare_client.dart';

class ImageService {
  static final client = UploadcareClient(
    options: ClientOptions(
      pubKey: 'ef061a3b67c4eee2cc78',
    ),
  );

  static Future<List<String>> uploadImages(List<File> images) async {
    List<String> urls = [];
    
    for (var image in images) {
      try {
        final fileToUpload = await UCFile.fromFile(image);
        
        final uploadedFile = await client.upload.file(fileToUpload);
        
        urls.add(uploadedFile.url);
      } catch (e) {
        print('Error uploading image: $e');
        rethrow;
      }
    }
    
    return urls;
  }
}
