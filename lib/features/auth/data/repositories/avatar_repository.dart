import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/avatar_model.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

class AvatarRepository {
  final ApiClient apiClient;
  AvatarRepository({required this.apiClient});

  Future<List<Avatar>> getAllAvatars() async {
    final response = await apiClient.get('/avatars');
    if (response.data == null || response.data['avatars'] == null) {
      return [];
    }
    final List<dynamic> raw = response.data['avatars'];
    return raw.map((e) => Avatar.fromJson(e)).toList();
  }

  Future<List<Avatar>> getUnlockedAvatars() async {
    final response = await apiClient.get('/my-avatars');
    if (response.data == null || response.data['avatars'] == null) {
      return [];
    }
    final List<dynamic> raw = response.data['avatars'];
    return raw.map((e) => Avatar.fromJson(e, unlocked: true)).toList();
  }

  Future<void> unlockAvatar(int avatarId) async {
    await apiClient.post('/avatars/$avatarId/unlock');
  }

  Future<bool> uploadUserPhoto(String filePath, String token) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    final response = await apiClient.post(
      AppConstants.updateUserPhotoEndpoint,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        contentType: 'multipart/form-data',
      ),
    );
    return response.data['success'] == true;
  }
}
