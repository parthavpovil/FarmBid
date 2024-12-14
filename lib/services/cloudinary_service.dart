import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final cloudinary = CloudinaryPublic(
    'dhgfdjfb8',           // Your cloud name
    'farmbid',  // The preset name you just created
    cache: false,
  );

  /// Uploads an image file to Cloudinary and returns the URL
  static Future<String> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'auction_images',
          resourceType: CloudinaryResourceType.Image,
          tags: ['auction_app', 'user_upload'],
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
} 