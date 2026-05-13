import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HighLowScoreEntry {
  final String id;
  final String handleName;
  final String? avatarPath;
  final double score;
  final DateTime createdAt;

  const HighLowScoreEntry({
    required this.id,
    required this.handleName,
    required this.avatarPath,
    required this.score,
    required this.createdAt,
  });

  factory HighLowScoreEntry.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];

    return HighLowScoreEntry(
      id: json['id'].toString(),
      handleName: json['handle_name'].toString(),
      avatarPath: json['avatar_path'] as String?,
      score: rawScore is num
          ? rawScore.toDouble()
          : double.tryParse(rawScore.toString()) ?? 0,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class HighLowRankingService {
  static const String gameType = 'high_low';
  static const String scoresTable = 'scores';
  static const String avatarBucket = 'avatars';

  final SupabaseClient _client;

  HighLowRankingService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<HighLowScoreEntry>> fetchRanking({int limit = 10}) async {
    final response = await _client
        .from(scoresTable)
        .select('id, handle_name, avatar_path, score, game_type, created_at')
        .eq('game_type', gameType)
        .order('score', ascending: false)
        .order('created_at', ascending: true)
        .limit(limit);

    return response
        .map<HighLowScoreEntry>(
          (row) => HighLowScoreEntry.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<String> uploadAvatar(XFile avatar) async {
    final bytes = await avatar.readAsBytes();
    final extension = _extensionForFileName(avatar.name);
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(1 << 32);
    final path = 'high_low/${now}_$suffix.$extension';

    await _client.storage
        .from(avatarBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(extension),
            upsert: false,
          ),
        );

    return path;
  }

//supabaseのscoreテーブルにデータを送る
  Future<void> submitScore({
    required String handleName,
    required double score,
    String? avatarPath,
  }) async {
    await _client.from(scoresTable).insert({
      'handle_name': handleName,
      'avatar_path': avatarPath,
      'score': score,
      'game_type': gameType,
    });
  }

  String avatarUrl(String avatarPath) {
    return _client.storage.from(avatarBucket).getPublicUrl(avatarPath);
  }

  String _extensionForFileName(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last;
    if (extension == 'png' || extension == 'webp' || extension == 'gif') {
      return extension;
    }
    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
