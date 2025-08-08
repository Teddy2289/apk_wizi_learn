import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/avatar_model.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

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

  Future<bool> uploadUserPhoto(String filePath, String token) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    final response = await dio.post(
      AppConstants.baseUrl + AppConstants.updateUserPhotoEndpoint,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + token,
          'Accept': 'application/json',
        },
      ),
    );
    return response.data['success'] == true;
  }
}
