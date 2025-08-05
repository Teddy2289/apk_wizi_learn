import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/avatar_model.dart';

class AvatarRepository {
  final Dio dio;
  AvatarRepository({required this.dio});

  Future<List<Avatar>> getAllAvatars() async {
    final response = await dio.get('/avatars');
    if (response.data == null || response.data['avatars'] == null) {
      return [];
    }
    final List<dynamic> raw = response.data['avatars'];
    return raw.map((e) => Avatar.fromJson(e)).toList();
  }

  Future<List<Avatar>> getUnlockedAvatars() async {
    final response = await dio.get('/my-avatars');
    if (response.data == null || response.data['avatars'] == null) {
      return [];
    }
    final List<dynamic> raw = response.data['avatars'];
    return raw.map((e) => Avatar.fromJson(e, unlocked: true)).toList();
  }

  Future<void> unlockAvatar(int avatarId) async {
    await dio.post('/avatars/$avatarId/unlock');
  }
} 