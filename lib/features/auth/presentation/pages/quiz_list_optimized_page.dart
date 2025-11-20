import 'package:flutter/material.dart';
import '../../../core/services/quiz_list_cache_manager.dart';

/// Enhanced quiz list widget with batch caching and efficient list rendering
class QuizListWithBatchCache extends StatefulWidget {
  final String apiBase;
  final String token;
  final void Function(String quizId, QuizBadgeStatus status)? onBadgeTap;

  const QuizListWithBatchCache({
    Key? key,
    required this.apiBase,
    required this.token,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  State<QuizListWithBatchCache> createState() => _QuizListWithBatchCacheState();
}

class _QuizListWithBatchCacheState extends State<QuizListWithBatchCache> {
  late QuizListCacheManager _cacheManager;
  List<QuizWithParticipation> _quizzes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cacheManager = QuizListCacheManager(
      apiBase: widget.apiBase,
      token: widget.token,
    );
    _cacheManager.addListener(_onCacheUpdated);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _cacheManager.removeListener(_onCacheUpdated);
    super.dispose();
  }

  /// Load quizzes with batch fetch (one API call)
  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _quizzes = await _cacheManager.fetchQuizzesBatch();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load quizzes: $e';
      });
    }
  }

  /// Called when cache is updated
  void _onCacheUpdated() {
    if (mounted) {
      setState(() {
        // Update UI with new cache state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadQuizzes, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return const Center(child: Text('No quizzes available'));
    }

    // Efficient list with cached badge statuses
    return ListView.builder(
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return QuizListTile(
          quiz: quiz,
          cacheManager: _cacheManager,
          onBadgeTap: widget.onBadgeTap,
        );
      },
    );
  }
}

/// Individual quiz list tile with cached status badge
class QuizListTile extends StatefulWidget {
  final QuizWithParticipation quiz;
  final QuizListCacheManager cacheManager;
  final void Function(String quizId, QuizBadgeStatus status)? onBadgeTap;

  const QuizListTile({
    Key? key,
    required this.quiz,
    required this.cacheManager,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  State<QuizListTile> createState() => _QuizListTileState();
}

class _QuizListTileState extends State<QuizListTile> {
  late QuizBadgeStatus _badgeStatus;

  @override
  void initState() {
    super.initState();
    _badgeStatus =
        widget.cacheManager.getStatus(widget.quiz.id) ?? QuizBadgeStatus.start;
    widget.cacheManager.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    widget.cacheManager.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    final newStatus = widget.cacheManager.getStatus(widget.quiz.id);
    if (newStatus != _badgeStatus && mounted) {
      setState(() {
        _badgeStatus = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.quiz.titre),
      subtitle: Text(widget.quiz.description ?? 'No description'),
      trailing: QuizStatusBadgeOptimized(
        quizId: widget.quiz.id,
        status: _badgeStatus,
        participation: widget.cacheManager.getParticipation(widget.quiz.id),
        onTap: () {
          widget.onBadgeTap?.call(widget.quiz.id, _badgeStatus);
        },
      ),
    );
  }
}

/// Optimized badge widget (read-only, uses cache state)
class QuizStatusBadgeOptimized extends StatelessWidget {
  final String quizId;
  final QuizBadgeStatus status;
  final QuizParticipation? participation;
  final VoidCallback? onTap;

  const QuizStatusBadgeOptimized({
    Key? key,
    required this.quizId,
    required this.status,
    this.participation,
    this.onTap,
  }) : super(key: key);

  Color _colorForStatus(QuizBadgeStatus s) {
    switch (s) {
      case QuizBadgeStatus.completed:
        return Colors.green.shade600;
      case QuizBadgeStatus.resume:
        return Colors.orange.shade700;
      case QuizBadgeStatus.start:
        return Colors.blue.shade700;
      case QuizBadgeStatus.error:
      case QuizBadgeStatus.loading:
      default:
        return Colors.grey.shade600;
    }
  }

  String _labelForStatus(QuizBadgeStatus s) {
    switch (s) {
      case QuizBadgeStatus.completed:
        return 'Completed';
      case QuizBadgeStatus.resume:
        return 'Resume';
      case QuizBadgeStatus.start:
        return 'Start';
      case QuizBadgeStatus.loading:
        return 'Loading…';
      case QuizBadgeStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _labelForStatus(status);
    final color = _colorForStatus(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == QuizBadgeStatus.loading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            if (status != QuizBadgeStatus.loading)
              Icon(
                status == QuizBadgeStatus.completed
                    ? Icons.check_circle
                    : (status == QuizBadgeStatus.resume
                        ? Icons.play_circle_fill
                        : Icons.play_arrow),
                size: 16,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Integration example for a scrolling quiz list page
class QuizListPage extends StatelessWidget {
  final String apiBase;
  final String token;

  const QuizListPage({Key? key, required this.apiBase, required this.token})
    : super(key: key);

  void _handleBadgeTap(String quizId, QuizBadgeStatus status) {
    // Handle navigation based on status
    switch (status) {
      case QuizBadgeStatus.completed:
        print('Show quiz results for quiz $quizId');
        break;
      case QuizBadgeStatus.resume:
        print('Resume quiz $quizId');
        break;
      case QuizBadgeStatus.start:
        print('Start quiz $quizId');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: QuizListWithBatchCache(
        apiBase: apiBase,
        token: token,
        onBadgeTap: _handleBadgeTap,
      ),
    );
  }
}
