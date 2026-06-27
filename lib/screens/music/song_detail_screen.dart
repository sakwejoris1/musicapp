import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song_model.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({super.key, required this.songId});
  final String songId;
  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  SongModel? _song;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _loadingComments = false;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final music = context.read<MusicProvider>();
    try {
      final cached =
          music.songs.where((s) => s.id == widget.songId).firstOrNull;
      if (cached != null) {
        setState(() {
          _song = cached;
          _loading = false;
        });
      }
      final data = await ApiService().getSong(widget.songId);
      if (mounted) {
        setState(() {
          _song = SongModel.fromJson(data['song'] as Map<String, dynamic>);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final data = await ApiService().getComments(widget.songId);
      if (mounted) {
        setState(() {
          _comments =
              data.map((c) => c as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingComments = false);
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    try {
      final data = await ApiService().addComment(widget.songId, text);
      setState(() =>
          _comments.insert(0, data['comment'] as Map<String, dynamic>));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final music = context.watch<MusicProvider>();

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.dark,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_song == null) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(),
        body: const Center(
            child: Text('Song not found',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final song = _song!;
    final isLiked = music.likedSongIds.contains(song.id);

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: song.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      isLiked ? AppColors.secondary : AppColors.textPrimary,
                ),
                onPressed: () => music.toggleLike(song),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.title,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () =>
                                  context.push('/artist/${song.artistId}'),
                              child: Text(song.artistName,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (song.albumId != null) ...[
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () => context
                                    .push('/album/${song.albumId}'),
                                child: const Text('View Album',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(formatCurrency(song.price),
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                          icon: Icons.headphones_outlined,
                          value: '${song.listenCount}'),
                      _StatChip(
                          icon: Icons.download_outlined,
                          value: '${song.downloadCount}'),
                      _StatChip(
                          icon: Icons.favorite_outline,
                          value: '${song.likeCount}'),
                      _StatChip(
                          icon: Icons.timer_outlined,
                          value: formatDuration(
                              Duration(seconds: song.duration))),
                      _StatChip(
                          icon: Icons.music_note_outlined,
                          value: song.genre),
                      if (song.language != null)
                        _StatChip(
                            icon: Icons.translate_outlined,
                            value: song.language!),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Play / Download buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: song.isPurchased
                              ? () {
                                  context
                                      .read<PlayerProvider>()
                                      .setQueue([song]);
                                  context
                                      .push('/player?songId=${song.id}');
                                }
                              : () => context.push('/payment', extra: {
                                    'type': 'listen',
                                    'itemId': song.id,
                                    'itemTitle': song.title,
                                    'amount': song.price,
                                    'artistId': song.artistId,
                                  }),
                          icon: Icon(song.isPurchased
                              ? Icons.play_arrow_rounded
                              : Icons.lock_outline),
                          label: Text(song.isPurchased
                              ? l.play
                              : '${l.payToListen} • ${formatCurrency(song.price)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: song.isDownloaded
                            ? null
                            : () => context.push('/payment', extra: {
                                  'type': 'download',
                                  'itemId': song.id,
                                  'itemTitle': song.title,
                                  'amount': song.downloadPrice,
                                  'artistId': song.artistId,
                                }),
                        icon: Icon(
                          song.isDownloaded
                              ? Icons.check_circle_outline
                              : Icons.download_outlined,
                          color: song.isDownloaded
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        label: Text(
                          song.isDownloaded
                              ? 'Downloaded'
                              : formatCurrency(song.downloadPrice),
                          style: TextStyle(
                              color: song.isDownloaded
                                  ? AppColors.success
                                  : AppColors.textSecondary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: song.isDownloaded
                                  ? AppColors.success
                                  : AppColors.textSecondary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),

                  if (song.hasVideo) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_circle_outline,
                          color: AppColors.secondary),
                      label: const Text('Watch Video',
                          style: TextStyle(color: AppColors.secondary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],

                  // Credits
                  if (song.producer != null || song.composer != null) ...[
                    const SizedBox(height: 20),
                    const Text('Credits',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    if (song.producer != null)
                      _CreditRow(
                          label: 'Producer', value: song.producer!),
                    if (song.composer != null)
                      _CreditRow(
                          label: 'Composer', value: song.composer!),
                  ],

                  // Lyrics
                  if (song.lyrics != null &&
                      song.lyrics!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Lyrics',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        song.lyrics!,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.7),
                      ),
                    ),
                  ],

                  // Comments
                  const SizedBox(height: 24),
                  const Text('Comments',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _postComment,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingComments)
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2))
                  else if (_comments.isEmpty)
                    const Text('No comments yet',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...(_comments.map((c) => _CommentTile(comment: c))),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary]),
        ),
        child: const Icon(Icons.music_note_rounded,
            size: 80, color: Colors.white),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final Map<String, dynamic> comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkCard,
            child: Text(
              ((comment['userName'] as String?) ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['userName'] as String? ?? 'User',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(DateTime.tryParse(
                              comment['createdAt'] as String? ?? '') ??
                          DateTime.now()),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment['text'] as String? ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
