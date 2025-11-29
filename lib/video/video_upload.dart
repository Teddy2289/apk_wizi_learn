// Sample Flutter helper for video upload
import 'dart:io';
import 'package:http/http.dart' as http;

class VideoUploadService {
  final String apiBase;
  final String token;

  VideoUploadService({required this.apiBase, required this.token});

  Future<http.Response> uploadVideo(
    File file, {
    String? titre,
    String? description,
  }) async {
    final uri = Uri.parse('$apiBase/medias/upload-video');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('video', file.path));
    if (titre != null) request.fields['titre'] = titre;
    if (description != null) request.fields['description'] = description;

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    return resp;
  }
}
