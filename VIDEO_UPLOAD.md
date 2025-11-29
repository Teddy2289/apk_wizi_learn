Flutter video upload + playback

1) Dependencies (pubspec.yaml):

- http: ^0.13.0
- video_player: ^2.5.0

2) Usage

Upload:
```dart
final service = VideoUploadService(apiBase: 'https://your-backend.com/api', token: 'JWT_TOKEN');
final resp = await service.uploadVideo(file, titre: 'Mon tuto');
if (resp.statusCode == 201) print('Uploaded');
```

Playback:
```dart
ServerVideoPlayer(url: 'https://your-backend/storage/videos/filename.mp4')
```

Notes:
- Ensure CORS / authentication works for your environment.
- For large uploads prefer background upload packages or chunking if mobile network is unreliable.
