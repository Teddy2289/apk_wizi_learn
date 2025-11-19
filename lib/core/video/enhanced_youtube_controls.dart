import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Contrôles YouTube personnalisés avec meilleure visibilité
class EnhancedYoutubeControls extends StatefulWidget {
  final YoutubePlayerController controller;
  final Color primaryColor;

  const EnhancedYoutubeControls({
    super.key,
    required this.controller,
    required this.primaryColor,
  });

  @override
  State<EnhancedYoutubeControls> createState() =>
      _EnhancedYoutubeControlsState();
}

class _EnhancedYoutubeControlsState extends State<EnhancedYoutubeControls> {
  bool _showControls = true;
  late Duration _position;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _position = Duration.zero;
    _duration = Duration.zero;
    widget.controller.addListener(_updateState);
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {
      _position = widget.controller.value.position;
      // Durée estimée si disponible
      try {
        _duration = Duration(milliseconds: 600000); // 10 minutes par défaut
      } catch (e) {
        _duration = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Barre de progression
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                        elevation: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: _position.inSeconds.toDouble().clamp(
                            0,
                            _duration.inSeconds.toDouble(),
                          ),
                      max: _duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        widget.controller.seekTo(
                          Duration(seconds: value.toInt()),
                        );
                      },
                      activeColor: widget.primaryColor,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contrôles principaux
            if (_showControls)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouton reculer
                    _buildControlButton(
                      icon: Icons.replay_10,
                      label: '10s',
                      onPressed: () {
                        final newPosition = _position - const Duration(seconds: 10);
                        widget.controller.seekTo(
                          newPosition.inSeconds < 0
                              ? Duration.zero
                              : newPosition,
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    // Bouton play/pause (PRINCIPAL)
                    _buildPlayButton(),
                    const SizedBox(width: 24),
                    // Bouton avancer
                    _buildControlButton(
                      icon: Icons.forward_10,
                      label: '10s',
                      onPressed: () {
                        final newPosition = _position + const Duration(seconds: 10);
                        widget.controller.seekTo(
                          newPosition.inSeconds > _duration.inSeconds
                              ? _duration
                              : newPosition,
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Bouton play/pause agrandis avec meilleur contraste
  Widget _buildPlayButton() {
    return Container(
      decoration: BoxDecoration(
        color: widget.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.controller.play,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              widget.controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }

  /// Boutons de contrôle (reculer/avancer)
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
