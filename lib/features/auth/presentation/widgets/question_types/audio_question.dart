import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class AudioQuestion extends StatefulWidget {
  final Question question;
  final Function(dynamic) onAnswer;
  final bool showFeedback;

  const AudioQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.showFeedback,
  });

  @override
  State<AudioQuestion> createState() => _AudioQuestionState();
}

class _AudioQuestionState extends State<AudioQuestion> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isMuted = false;
  final double _volume = 1.0;
  String? _selectedAnswer;
  bool _audioError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<AudioPlayerException>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      final mediaUrl = widget.question.mediaUrl;
      if (mediaUrl == null || mediaUrl.isEmpty) {
        throw Exception('Aucune URL audio fournie');
      }

      // Corrige l'URL pour qu'elle soit complète
      final fullAudioUrl = AppConstants.getAudioStreamUrl(mediaUrl);
      debugPrint('🟣 Audio full URL = $fullAudioUrl');

      await _audioPlayer.setSource(UrlSource(fullAudioUrl));
    } catch (e) {
      debugPrint('Erreur lors du chargement audio: $e');
      if (mounted) {
        setState(() {
          _audioError = true;
        });
      }
    }
  }

  void _setupAudioListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });


  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioError = true;
        });
      }
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioError = true;
        });
      }
    }
  }

  void _toggleMute() {
    final newMuteState = !_isMuted;
    _audioPlayer.setVolume(newMuteState ? 0.0 : _volume);
    if (mounted) {
      setState(() {
        _isMuted = newMuteState;
      });
    }
  }

  void _handleAnswer(String answerId) {
    if (widget.showFeedback) return;

    final selected = widget.question.answers.firstWhere(
          (a) => a.id.toString() == answerId,
      orElse: () => Answer(id: "-1", text: '', correct: false),
    );

    // Envoyer un format cohérent avec ce que le serveur attend
    widget.onAnswer({
      'id': selected.id,
      'text': selected.text,
      'isCorrect': selected.correct
    });

    if (mounted) {
      setState(() {
        _selectedAnswer = answerId;
      });
    }
  }
  bool _isCorrectAnswer(String answerId) {
    if (!widget.showFeedback) return false;

    final correctAnswer = widget.question.answers.firstWhere(
          (a) => a.correct == true,
      orElse: () => Answer(id: "-1", text: '', correct: false),
    );

    return answerId == correctAnswer.id.toString();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _errorSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Audio Player
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        // Play/Pause Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                              ),
                              onPressed: _toggleMute,
                            ),
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 28,
                              ),
                              onPressed: _playPause,
                            ),
                            IconButton(
                              icon: const Icon(Icons.stop),
                              onPressed: _stop,
                            ),
                          ],
                        ),
                        // Progress Bar
                        Slider(
                          value: _position.inSeconds.toDouble(),
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) async {
                            try {
                              await _audioPlayer.seek(
                                Duration(seconds: value.toInt()),
                              );
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _audioError = true;
                                });
                              }
                            }
                          },
                        ),
                        // Time Indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position)),
                              Text(_formatDuration(_duration - _position)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Error Message
            if (_audioError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Erreur lors du chargement de l\'audio. Veuillez réessayer.',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Answer Options
            Column(
              children: widget.question.answers.map((answer) {
                final isSelected = _selectedAnswer == answer.id.toString();
                final isCorrect = _isCorrectAnswer(answer.id.toString());

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: widget.showFeedback
                          ? isCorrect
                          ? Colors.green
                          : isSelected
                          ? Colors.red
                          : Colors.grey[300]!
                          : isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(answer.text),
                    value: answer.id.toString(),
                    groupValue: _selectedAnswer,
                    onChanged: widget.showFeedback
                        ? null
                        : (value) => _handleAnswer(value!),
                    secondary: widget.showFeedback
                        ? Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: isCorrect ? Colors.green : Colors.red,
                    )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}