import '../../features/vault/models/media_item.dart';

abstract class VaultService {
  Stream<List<MediaItem>> watchMyMedia(String ownerId);
  Future<MediaItem> uploadMedia({
    required String ownerId,
    required String localPath,
    required String mediaType,
  });
  Future<void> deleteMedia(String ownerId, String mediaId);
}
