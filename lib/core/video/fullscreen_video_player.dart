import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Widget pour afficher le lecteur vidéo en mode fullscreen avec zoom
class FullscreenVideoPlayer extends StatefulWidget {
  final YoutubePlayerController controller;
  final Widget playerWidget;

  const FullscreenVideoPlayer({
    super.key,
    required this.controller,
    required this.playerWidget,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late TransformationController _transformationController;
  double _currentScale = 1.0;
  bool _showZoomControls = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Détecte si on est en mode paysage
  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Détecte si on est sur mobile
  bool _isMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 600;
  }

  /// Obtient les dimensions responsives du lecteur vidéo
  Size _getVideoSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = _isLandscape(context);
    final isMobile = _isMobile(context);

    if (!isMobile) {
      // Tablette/Desktop - utiliser fullscreen
      return Size(size.width, size.height);
    }

    if (isLandscape) {
      // Mobile en paysage - fullscreen avec contrainte minimale
      return Size(size.width, size.height);
    } else {
      // Mobile en portrait - taille responsive (16:9 aspect ratio)
      final videoWidth = size.width - 32; // Padding
      final videoHeight = (videoWidth * 9) / 16;
      return Size(videoWidth, videoHeight);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    _currentScale = (_currentScale + 0.1).clamp(1.0, 5.0);
    final offset = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    _transformationController.value =
        Matrix4.identity()
          ..translate(offset.dx, offset.dy)
          ..scale(_currentScale)
          ..translate(-offset.dx, -offset.dy);
    setState(() {});
  }

  void _zoomOut() {
    _currentScale = (_currentScale - 0.1).clamp(1.0, 5.0);
    final offset = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    _transformationController.value =
        Matrix4.identity()
          ..translate(offset.dx, offset.dy)
          ..scale(_currentScale)
          ..translate(-offset.dx, -offset.dy);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _isLandscape(context);
    final isMobile = _isMobile(context);
    final videoSize = _getVideoSize(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body:
          isLandscape || !isMobile
              ? _buildFullscreenPlayer(videoSize)
              : _buildPortraitPlayer(videoSize),
    );
  }

  /// Construit le lecteur en mode fullscreen (paysage ou tablette)
  Widget _buildFullscreenPlayer(Size videoSize) {
    return Stack(
      children: [
        // Lecteur vidéo avec zoom
        InteractiveViewer(
          transformationController: _transformationController,
          panEnabled: _currentScale > 1.0,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          boundaryMargin: const EdgeInsets.all(100),
          onInteractionEnd: (_) {
            setState(() {
              final scale = _transformationController.value.getMaxScaleOnAxis();
              _currentScale = scale;
            });
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 300,
              minHeight: 300,
              maxWidth: videoSize.width,
              maxHeight: videoSize.height,
            ),
            child: Center(child: widget.playerWidget),
          ),
        ),
        _buildZoomControls(),
        _buildVisibilityToggle(),
      ],
    );
  }

  /// Construit le lecteur en mode portrait responsive
  Widget _buildPortraitPlayer(Size videoSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Lecteur vidéo responsive en portrait
          Container(
            width: videoSize.width,
            height: videoSize.height,
            color: Colors.black,
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: _currentScale > 1.0,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 3.0, // Zoom max réduit en portrait
                  boundaryMargin: const EdgeInsets.all(50),
                  onInteractionEnd: (_) {
                    setState(() {
                      final scale =
                          _transformationController.value.getMaxScaleOnAxis();
                      _currentScale = scale;
                    });
                  },
                  child: Center(child: widget.playerWidget),
                ),
                _buildZoomControls(),
                _buildVisibilityToggle(),
              ],
            ),
          ),
          // Espacement supplémentaire en portrait
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Construit les contrôles de zoom
  Widget _buildZoomControls() {
    if (!_showZoomControls) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton zoom in
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _zoomIn,
              tooltip: 'Zoom in',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${(_currentScale * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Bouton zoom out
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: _zoomOut,
              tooltip: 'Zoom out',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            const Divider(height: 1, color: Colors.white30),
            // Bouton reset
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetZoom,
              tooltip: 'Reset zoom',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le bouton de visibilité des contrôles
  Widget _buildVisibilityToggle() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showZoomControls = !_showZoomControls;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            _showZoomControls ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
