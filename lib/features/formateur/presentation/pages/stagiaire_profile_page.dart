import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/stagiaire_profile_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/stagiaire_profile_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

class StagiaireProfilePage extends StatefulWidget {
  final int stagiaireId;

  const StagiaireProfilePage({
    super.key,
    required this.stagiaireId,
  });

  @override
  State<StagiaireProfilePage> createState() => _StagiaireProfilePageState();
}

class _StagiaireProfilePageState extends State<StagiaireProfilePage>
    with SingleTickerProviderStateMixin {
  late final StagiaireProfileRepository _repository;
  late final TabController _tabController;

  StagiaireProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = StagiaireProfileRepository(
      apiClient: ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      ),
    );
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _repository.getProfileById(widget.stagiaireId);
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_profile == null) return;

    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Message à ${_profile!.stagiaire.fullName}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: FormateurTheme.background,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: FormateurTheme.background,
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: FormateurTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                final success = await _repository.sendMessage(
                  widget.stagiaireId,
                  titleController.text,
                  messageController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context, success);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FormateurTheme.accentDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message envoyé avec succès'),
          backgroundColor: FormateurTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: FormateurTheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: FormateurTheme.accentDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('RÉESSAYER'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('Aucune donnée', style: TextStyle(color: FormateurTheme.textSecondary)))
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          _buildPremiumProfileHeader(),
                          _buildSliverTabs(),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildPerformancesTab(),
                          _buildSecurityTab(),
                        ],
                      ),
                    ),
      floatingActionButton: _profile != null ? FloatingActionButton.extended(
        onPressed: _sendMessage,
        backgroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.chat_bubble_rounded, color: FormateurTheme.accent, size: 20),
        label: const Text('CONTACTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ) : null,
    );
  }

  /// Premium Glassmorphism Header (React parity)
  Widget _buildPremiumProfileHeader() {
    final s = _profile!.stagiaire;
    final stats = _profile!.stats;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: FormateurTheme.textPrimary, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Brand color header with pattern
            Container(
              height: 160,
              width: double.infinity,
                color: FormateurTheme.accent,
                // Pattern removed to fix 404 error
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FormateurTheme.accent.withOpacity(0.9),
                      FormateurTheme.accent,
                    ],
                  ),
                ),
              ),
            ),
            // Profile content
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Avatar with verified badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: FormateurTheme.background,
                          backgroundImage: s.image != null && s.image!.isNotEmpty
                              ? NetworkImage(AppConstants.getUserImageUrl(s.image!))
                              : null,
                          child: s.image == null
                              ? Text(s.prenom.isNotEmpty ? s.prenom[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: FormateurTheme.accent))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FormateurTheme.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: FormateurTheme.success.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Name and badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -0.5),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FormateurTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Actif',
                          style: TextStyle(
                            color: FormateurTheme.accentDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Badge display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: FormateurTheme.textPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stats.currentBadge.toUpperCase(), // Keep badge upper for style
                      style: const TextStyle(color: FormateurTheme.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Contact info row
                  if (s.email.isNotEmpty)
                    Text(
                      s.email,
                      style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  if (s.telephone != null && s.telephone!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatPhone(s.telephone!),
                        style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: FormateurTheme.accentDark,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: FormateurTheme.textPrimary,
          unselectedLabelColor: FormateurTheme.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
          tabs: const [
            Tab(text: 'Vue d\'ensemble'),
            Tab(text: 'Performances'),
            Tab(text: 'Sécurité'),
          ],
        ),
      ),
    );
  }

  /// Tab 1: Vue d'ensemble - Stats grid + Formations + Contacts
  Widget _buildOverviewTab() {
    final stats = _profile!.stats;
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 5-card Stats Grid
          _buildStatsGrid(stats),
          const SizedBox(height: 28),

          // Formations Section
          _buildSectionHeader('Formations en cours', Icons.school_rounded, '${_profile!.formations.length}'),
          const SizedBox(height: 12),
          if (_profile!.formations.isEmpty)
            _buildEmptyState(Icons.school_outlined, 'Aucune formation active')
          else
            ..._profile!.formations.map((f) => _buildFormationCard(f)),

          // Contacts Section (Équipe Dédiée)
          if (_profile!.contacts != null && _profile!.contacts!.hasAny) ...[
            const SizedBox(height: 28),
            _buildSectionHeader('Équipe dédiée', Icons.people_alt_rounded, null),
            const SizedBox(height: 12),
            _buildContactsSection(),
          ],
        ],
      ),
    );
  }

  /// Tab 2: Performances - Activity + Quiz History
  Widget _buildPerformancesTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Activity Chart placeholder (mini visualization)
          _buildSectionHeader('Engagement 30 jours', Icons.trending_up_rounded, null),
          const SizedBox(height: 12),
          _buildActivityChart(),
          const SizedBox(height: 28),

          // Recent Activities
          _buildSectionHeader('Activités récentes', Icons.history_rounded, null),
          const SizedBox(height: 12),
          if (_profile!.activity.recentActivities.isEmpty)
            _buildEmptyState(Icons.timeline_rounded, 'Aucune activité récente')
          else
            ..._profile!.activity.recentActivities.take(5).map((a) => _buildActivityItem(a)),

          const SizedBox(height: 28),

          // Quiz History
          _buildSectionHeader('Historique Quiz', Icons.quiz_rounded, '${_profile!.quizHistory.length}'),
          const SizedBox(height: 12),
          if (_profile!.quizHistory.isEmpty)
            _buildEmptyState(Icons.quiz_outlined, 'Aucun quiz effectué')
          else
            ..._profile!.quizHistory.take(6).map((q) => _buildQuizHistoryItem(q)),
        ],
      ),
    );
  }

  /// Tab 3: Security - Profile info + Login History
  Widget _buildSecurityTab() {
    final s = _profile!.stagiaire;
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact Info Cards
          _buildSectionHeader('Coordonnées', Icons.contact_mail_rounded, null),
          const SizedBox(height: 12),
          _buildInfoCard(Icons.alternate_email_rounded, 'Email', s.email),
          if (s.telephone != null && s.telephone!.isNotEmpty)
            _buildInfoCard(Icons.phone_rounded, 'Téléphone', _formatPhone(s.telephone!)),
          _buildInfoCard(Icons.calendar_month_rounded, 'Inscrit le', _formatDateLong(s.dateInscription ?? s.createdAt)),
          if (s.dateDebutFormation != null)
            _buildInfoCard(Icons.rocket_launch_rounded, 'Formation démarrée', _formatDateLong(s.dateDebutFormation!)),
          _buildInfoCard(Icons.login_rounded, 'Dernière connexion', s.lastLogin != null ? _formatDateLong(s.lastLogin!) : 'Jamais'),

          const SizedBox(height: 28),

          // Login History
          _buildSectionHeader('Historique de connexion', Icons.security_rounded, null),
          const SizedBox(height: 12),
          if (_profile!.loginHistory.isEmpty)
            _buildEmptyState(Icons.security_outlined, 'Aucun historique de connexion')
          else
            ..._profile!.loginHistory.take(5).map((l) => _buildLoginHistoryItem(l)),

          const SizedBox(height: 28),

          // Verified Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FormateurTheme.textPrimary, FormateurTheme.textPrimary.withOpacity(0.9)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: FormateurTheme.textPrimary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user_rounded, color: FormateurTheme.accent, size: 40),
                const SizedBox(height: 16),
                const Text('PROFIL VÉRIFIÉ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  'Membre depuis le ${_formatDateLong(s.createdAt)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== COMPONENTS ==========

  /// 5-card stats grid matching React design
  Widget _buildStatsGrid(StagiaireStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(Icons.star_rounded, 'Points', stats.totalPoints.toString(), const Color(0xFFF59E0B)),
        _buildStatCard(Icons.school_rounded, 'Formations', '${stats.formationsCompleted}/${stats.formationsCompleted + stats.formationsInProgress}', const Color(0xFF3B82F6)),
        _buildStatCard(Icons.analytics_rounded, 'Score Moy.', '${(stats.averageScore * 10).toInt()}%', const Color(0xFF10B981)),
        _buildStatCard(Icons.timer_rounded, 'Temps Total', '${(stats.totalTimeMinutes / 60).round()}h', const Color(0xFF8B5CF6)),
        if (_profile!.videoStats != null)
          _buildStatCard(Icons.play_circle_rounded, 'Vidéos', '${_profile!.videoStats!.totalWatched}', const Color(0xFFEC4899)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(value, style: TextStyle(color: FormateurTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String? count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FormateurTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: FormateurTheme.accentDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FormateurTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(count, style: TextStyle(color: FormateurTheme.accentDark, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
      ],
    );
  }

  Widget _buildFormationCard(FormationProgress f) {
    final color = f.isCompleted ? FormateurTheme.success : FormateurTheme.accentDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.category.toUpperCase(), style: TextStyle(color: FormateurTheme.accentDark, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(f.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: FormateurTheme.textPrimary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  f.isCompleted ? 'Validée' : '${f.progress * 10}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: f.progress / 10,
              minHeight: 8,
              backgroundColor: FormateurTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (f.levels != null && f.levels!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: FormateurTheme.border, height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: f.levels!.map((l) => _buildLevelChip(l)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelChip(FormationLevel l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FormateurTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.name, style: const TextStyle(color: FormateurTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text('${l.avgScore.toInt()}%', style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildContactsSection() {
    final contacts = _profile!.contacts!;
    return Column(
      children: [
        if (contacts.formateurs.isNotEmpty)
          _buildContactGroup('Formateurs', contacts.formateurs),
        if (contacts.poleRelation.isNotEmpty)
          _buildContactGroup('Suivi Admin', contacts.poleRelation),
        if (contacts.commercials.isNotEmpty)
          _buildContactGroup('Commerciaux', contacts.commercials),
        if (contacts.partenaire != null)
          _buildContactCard(contacts.partenaire!, 'Partenaire'),
      ],
    );
  }

  Widget _buildContactGroup(String title, List<ContactInfo> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
        ...contacts.map((c) => _buildContactCard(c, null)),
      ],
    );
  }

  Widget _buildContactCard(ContactInfo c, String? role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: FormateurTheme.background,
            backgroundImage: c.image != null && c.image!.isNotEmpty
                ? NetworkImage(AppConstants.getUserImageUrl(c.image!))
                : null,
            child: c.image == null
                ? Text(c.prenom.isNotEmpty ? c.prenom[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w900, color: FormateurTheme.accent))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: FormateurTheme.textPrimary)),
                if (role != null)
                  Text(role.toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (c.email != null)
            IconButton(
              icon: Icon(Icons.email_outlined, color: FormateurTheme.accentDark, size: 20),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (c.telephone != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.phone_outlined, color: FormateurTheme.accentDark, size: 20),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final data = _profile!.activity.last30Days;
    if (data.isEmpty) {
      return _buildEmptyState(Icons.bar_chart_rounded, 'Pas de données d\'activité');
    }

    final maxActions = data.map((d) => d.actions).fold(0, (a, b) => a > b ? a : b);
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.take(14).map((d) {
          final height = maxActions > 0 ? (d.actions / maxActions) * 60 : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: height + 4,
                decoration: BoxDecoration(
                  color: FormateurTheme.accent.withOpacity(d.actions > 0 ? 0.8 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: FormateurTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getActivityIcon(a.type), color: FormateurTheme.accentDark, size: 18),
        ),
        title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: FormateurTheme.textPrimary)),
        subtitle: Text(_formatDateShort(a.timestamp), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w700)),
        trailing: a.score != null
            ? Text('${(a.score! * 10).toInt()}%', style: const TextStyle(color: FormateurTheme.success, fontWeight: FontWeight.w900, fontSize: 14))
            : null,
      ),
    );
  }

  Widget _buildQuizHistoryItem(QuizResult q) {
    // Score color based on score out of 10 (React parity)
    final color = q.score >= 8 ? FormateurTheme.success : q.score >= 5 ? FormateurTheme.orangeAccent : FormateurTheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Category + Title | Score badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.category.toUpperCase(),
                      style: TextStyle(color: FormateurTheme.accentDark, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      q.title.isNotEmpty ? q.title : 'Participation',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: FormateurTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Score badge (percentage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${q.percentage.toInt()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Footer row: Time spent | Date+Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: FormateurTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${(q.timeSpent / 60).floor()}m ${q.timeSpent % 60}s',
                    style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: FormateurTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTimeFull(q.completedAt),
                    style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTimeFull(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FormateurTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: FormateurTheme.accentDark, size: 18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryItem(LoginHistoryEntry l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FormateurTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getPlatformIcon(l.platform), color: FormateurTheme.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l.platform} — ${l.browser}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: FormateurTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('IP: ${l.ipAddress}', style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatDateShort(l.loginAt), style: TextStyle(color: FormateurTheme.accentDark, fontSize: 10, fontWeight: FontWeight.w900)),
              Text(_formatTimeShort(l.loginAt), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: FormateurTheme.border),
          const SizedBox(height: 12),
          Text(message.toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ========== HELPERS ==========

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
    }
    return phone;
  }

  String _formatDateShort(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  String _formatDateLong(String date) {
    try {
      final dt = DateTime.parse(date);
      const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date;
    }
  }

  String _formatTimeShort(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'quiz_completed':
        return Icons.emoji_events_rounded;
      case 'formation_started':
        return Icons.rocket_launch_rounded;
      case 'formation_completed':
        return Icons.check_circle_rounded;
      case 'video_watched':
        return Icons.play_circle_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('win')) return Icons.desktop_windows_rounded;
    if (p.contains('mac')) return Icons.desktop_mac_rounded;
    if (p.contains('ios') || p.contains('iphone') || p.contains('ipad')) return Icons.phone_iphone_rounded;
    if (p.contains('android')) return Icons.phone_android_rounded;
    if (p.contains('linux')) return Icons.computer_rounded;
    return Icons.devices_rounded;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
