import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aarogya/core/services/auth_service.dart';

/// Firebase Storage Service — file upload/download for medical reports
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a medical report file (PDF, image, etc.)
  Future<String> uploadReport({
    required File file,
    required String fileName,
  }) async {
    final uid = AuthService().uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _storage.ref().child('reports/$uid/$fileName');
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Upload a profile photo
  Future<String> uploadProfilePhoto({
    required File file,
  }) async {
    final uid = AuthService().uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _storage.ref().child('profile_photos/$uid/avatar.jpg');
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Delete a file from storage
  Future<void> deleteFile(String filePath) async {
    try {
      await _storage.ref(filePath).delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  /// Get download URL for an existing file
  Future<String?> getDownloadUrl(String filePath) async {
    try {
      return await _storage.ref(filePath).getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
