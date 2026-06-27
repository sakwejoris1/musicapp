import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/player_provider.dart';
import '../../providers/music_provider.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.songId});
  final String songId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();
    final song = player.currentSong;
    final l = AppLocalizations.of(context);

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(title: Text(l.play)),
        body: const Center(
            child: Text('No song playing',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final isLiked = music.likedSongIds.contains(song.id);

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.35),
              AppColors.dark,
              AppColors.dark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(song: song, onOptions: () => _showOptions(context, song, l)),
              const SizedBox(height: 8),
              _AlbumArt(coverUrl: song.coverUrl, isPlaying: player.isPlaying),
              const SizedBox(height: 20),
              _SongInfo(
                title: song.title,
                artistName: song.artistName,
                isLiked: isLiked,
                onLike: () => music.toggleLike(song),
              ),
              const SizedBox(height: 16),
              _SeekBar(player: player),
              const SizedBox(height: 8),
              _Controls(player: player),
              const SizedBox(height: 12),
              _SecondaryActions(song: song, player: player),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tab,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'QUEUE'),
                        Tab(text: 'LYRICS'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _QueueTab(player: player),
                          _LyricsTab(lyrics: song.lyrics),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, song, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_outlined,
                  color: AppColors.textSecondary),
              title: Text(l.download,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.push('/payment', extra: {
                  'type': 'download',
                  'itemId': song.id,
                  'itemTitle': song.title,
                  'amount': song.downloadPrice,
                  'artistId': song.artistId,
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_outlined,
                  color: AppColors.textSecondary),
              title: Text(l.dedication,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showDedication(context, song.artistId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppColors.textSecondary),
              title: const Text('Share',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline,
                  color: AppColors.textSecondary),
              title: const Text('Song Info',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.push('/song/${song.id}');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDedication(BuildContext context, String artistId) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send Dedication',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Write your message...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isNotEmpty) {
                    await ApiService().sendDedication(artistId, ctrl.text.trim());
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.song, required this.onOptions});
  final dynamic song;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary, size: 32),
            onPressed: () => context.pop(),
          ),
          Column(
            children: [
              const Text('NOW PLAYING',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1.5)),
              Text(song.genre,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          IconButton(
            icon:
                const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onPressed: onOptions,
          ),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatefulWidget {
  const _AlbumArt({required this.coverUrl, required this.isPlaying});
  final String? coverUrl;
  final bool isPlaying;

  @override
  State<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<_AlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.isPlaying) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AlbumArt old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 48,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: widget.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary]),
        ),
        child: const Icon(Icons.music_note_rounded,
            size: 90, color: Colors.white),
      );
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({
    required this.title,
    required this.artistName,
    required this.isLiked,
    required this.onLike,
  });
  final String title;
  final String artistName;
  final bool isLiked;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(artistName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? AppColors.secondary : AppColors.textSecondary,
              size: 26,
            ),
            onPressed: onLike,
          ),
        ],
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.darkSurface,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: player.progress.clamp(0.0, 1.0),
              onChanged: (v) => player.seekTo(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(player.position),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(formatDuration(player.duration),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final shuffleActive = player.shuffle;
    final repeatMode = player.repeatMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color:
                  shuffleActive ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            onPressed: player.toggleShuffle,
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded,
                color: AppColors.textPrimary, size: 36),
            onPressed: player.skipPrevious,
          ),
          GestureDetector(
            onTap: player.togglePlay,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                player.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded,
                color: AppColors.textPrimary, size: 36),
            onPressed: player.skipNext,
          ),
          IconButton(
            icon: Icon(
              repeatMode == PlayerRepeatMode.repeatOne
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: repeatMode != PlayerRepeatMode.off
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 22,
            ),
            onPressed: player.toggleRepeat,
          ),
        ],
      ),
    );
  }
}

class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({required this.song, required this.player});
  final dynamic song;
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionBtn(
            icon: Icons.add_to_queue_outlined,
            label: 'Queue',
            onTap: () => player.addToQueue(song),
          ),
          _ActionBtn(
            icon: Icons.playlist_add_outlined,
            label: 'Playlist',
            onTap: () {},
          ),
          _ActionBtn(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    if (player.queue.isEmpty) {
      return const Center(
          child: Text('Queue is empty',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: player.queue.length,
      itemBuilder: (_, i) {
        final s = player.queue[i];
        final isCurrent = i == player.queueIndex;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: s.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: s.coverUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.darkSurface,
                      child: const Icon(Icons.music_note,
                          color: AppColors.primary, size: 18)),
            ),
          ),
          title: Text(
            s.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.normal,
                fontSize: 13),
          ),
          subtitle: Text(s.artistName,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          trailing: isCurrent
              ? const Icon(Icons.equalizer_rounded,
                  color: AppColors.primary, size: 18)
              : null,
          onTap: () => player.setQueue(player.queue, startIndex: i),
        );
      },
    );
  }
}

class _LyricsTab extends StatelessWidget {
  const _LyricsTab({this.lyrics});
  final String? lyrics;

  @override
  Widget build(BuildContext context) {
    if (lyrics == null || lyrics!.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined,
                color: AppColors.textSecondary, size: 48),
            SizedBox(height: 12),
            Text('No lyrics available',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        lyrics!,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 15, height: 1.8),
        textAlign: TextAlign.center,
      ),
    );
  }
}
