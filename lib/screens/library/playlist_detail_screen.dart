import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/song_card.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});
  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final playlist =
        context.watch<PlaylistProvider>().getById(playlistId);

    if (playlist == null) {
      return Scaffold(
          backgroundColor: AppColors.dark,
          appBar: AppBar(),
          body: const Center(
              child: Text('Playlist not found',
                  style: TextStyle(color: AppColors.textSecondary))));
    }

    final totalDuration = playlist.totalDuration;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(playlist.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              background: playlist.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.primary,
                          AppColors.secondary
                        ]),
                      ),
                      child: const Icon(Icons.queue_music_rounded,
                          size: 72, color: Colors.white),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${playlist.songCount} songs • ${_formatDur(totalDuration)}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                            if (playlist.description != null) ...[
                              const SizedBox(height: 4),
                              Text(playlist.description!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      if (playlist.songs.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<PlayerProvider>()
                                .setQueue(playlist.songs);
                            context.push(
                                '/player?songId=${playlist.songs.first.id}');
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (playlist.songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_off_rounded,
                        size: 56, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text('No songs in this playlist',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final song = playlist.songs[i];
                  return Dismissible(
                    key: Key(song.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      child: const Icon(Icons.remove_circle_outline,
                          color: AppColors.secondary),
                    ),
                    onDismissed: (_) => context
                        .read<PlaylistProvider>()
                        .removeSong(playlistId, song.id),
                    child: SongCard(
                      song: song,
                      onPlay: () {
                        context
                            .read<PlayerProvider>()
                            .setQueue(playlist.songs, startIndex: i);
                        context.push('/player?songId=${song.id}');
                      },
                      onBuy: () {},
                      compact: true,
                    ),
                  );
                },
                childCount: playlist.songs.length,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
