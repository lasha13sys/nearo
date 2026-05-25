import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoRepository {
  final bool firebaseReady;
  final FirebaseStorage? _storage;

  ProfilePhotoRepository({required this.firebaseReady})
      : _storage = firebaseReady ? FirebaseStorage.instance : null;

  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile image,
  }) async {
    if (!firebaseReady || _storage == null || uid == 'demo-user' || uid.startsWith('demo-')) {
      return image.path;
    }

    final extension = _extensionFor(image.name);
    final ref = _storage.ref('users/$uid/profile.$extension');
    final bytes = await image.readAsBytes();
    final metadata = SettableMetadata(contentType: _contentTypeFor(extension));
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _extensionFor(String name) {
    final value = name.toLowerCase();
    if (value.endsWith('.png')) return 'png';
    if (value.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
