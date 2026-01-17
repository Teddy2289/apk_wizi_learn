String normalizeYoutubeUrl(String url) {
  if (url.isEmpty) return url;
  
  // Correction pour les URLs mobiles youtu.be
  if (url.contains('youtu.be/')) {
    final videoId = url.split('youtu.be/').last.split('?').first;
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  // Correction pour les shorts
  if (url.contains('youtube.com/shorts/')) {
    final videoId = url.split('youtube.com/shorts/').last.split('?').first;
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  // Correction pour les live
  if (url.contains('youtube.com/live/')) {
    final videoId = url.split('youtube.com/live/').last.split('?').first;
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  return url;
}
