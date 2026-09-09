class UserModel {
  final String uid;
  final String username;
  final String handle;
  final String profilePic;
  final List<String> followers;
  final List<String> following;

  UserModel({
    required this.uid,
    required this.username,
    required this.handle,
    required this.profilePic,
    required this.followers,
    required this.following,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      username: map['username'] ?? '',
      handle: map['handle'] ?? '',
      profilePic: map['profilePic'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }
}