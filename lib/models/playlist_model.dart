import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? coverUrl;
  final List<SongModel> songs;
  final bool isPublic;
  final DateTime createdAt;

  const PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverUrl,
    required this.songs,
    required this.isPublic,
    required this.createdAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        coverUrl: json['coverUrl'] as String?,
        songs: (json['songs'] as List? ?? [])
            .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
            .toList(),
        isPublic: json['isPublic'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'coverUrl': coverUrl,
        'songs': songs.map((s) => s.toJson()).toList(),
        'isPublic': isPublic,
        'createdAt': createdAt.toIso8601String(),
      };

  PlaylistModel copyWith({
    String? name,
    String? description,
    String? coverUrl,
    List<SongModel>? songs,
    bool? isPublic,
  }) =>
      PlaylistModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        songs: songs ?? this.songs,
        isPublic: isPublic ?? this.isPublic,
        createdAt: createdAt,
      );

  int get songCount => songs.length;

  Duration get totalDuration => songs.fold(
        Duration.zero,
        (acc, s) => acc + Duration(seconds: s.duration),
      );
}
