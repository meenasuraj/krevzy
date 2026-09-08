enum MediaScanStatus { pending, safe, suspicious, quarantined }

class MediaItem {
  final String id;
  final String ownerId;
  final String storagePath;
  final String mediaType;
  final int sizeBytes;
  final MediaScanStatus scanStatus;

  const MediaItem({
    required this.id,
    required this.ownerId,
    required this.storagePath,
    required this.mediaType,
    required this.sizeBytes,
    required this.scanStatus,
  });
}
