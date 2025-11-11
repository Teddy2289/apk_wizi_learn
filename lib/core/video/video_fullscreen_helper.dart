import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Utility helpers to lock/unlock orientation when a video enters fullscreen.
///
/// Usage:
/// - Call `VideoFullscreenHelper.enterLandscape()` when entering fullscreen.
/// - Call `VideoFullscreenHelper.exitLandscape()` when leaving fullscreen.
///
/// You can also wrap a widget with [FullscreenOrientationHandler] and call
/// its `enterFullscreen` / `exitFullscreen` methods from your player controls.
class VideoFullscreenHelper {
  /// Lock device to landscape orientations and hide system UI overlays.
  static Future<void> enterLandscape() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {
      // best-effort: not all platforms support orientation locks
    }
  }

  /// Restore portrait orientation and system UI overlays.
  static Future<void> exitLandscape() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // ignore
    }
  }
}

/// A small helper widget that provides callbacks to enter/exit fullscreen.
/// This doesn't include a video player; it's a convenience wrapper to call
/// the orientation helpers from your UI.
class FullscreenOrientationHandler extends StatefulWidget {
  final Widget child;

  const FullscreenOrientationHandler({Key? key, required this.child})
      : super(key: key);

  @override
  FullscreenOrientationHandlerState createState() =>
      FullscreenOrientationHandlerState();
}

class FullscreenOrientationHandlerState
    extends State<FullscreenOrientationHandler> {
  bool _isFullscreen = false;

  Future<void> enterFullscreen() async {
    if (_isFullscreen) return;
    _isFullscreen = true;
    await VideoFullscreenHelper.enterLandscape();
  }

  Future<void> exitFullscreen() async {
    if (!_isFullscreen) return;
    _isFullscreen = false;
    await VideoFullscreenHelper.exitLandscape();
  }

  @override
  void dispose() {
    // Ensure we unlock on dispose
    VideoFullscreenHelper.exitLandscape();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
