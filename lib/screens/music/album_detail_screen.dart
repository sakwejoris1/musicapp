import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/album_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/song_card.dart';

class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({super.key, required this.albumId});
  final String albumId;
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  AlbumModel? _album;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<MusicProvider>().getAlbum(widget.albumId);
    setState(() {
      _album = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.dark,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_album == null) {
      return Scaffold(backgroundColor: AppColors.dark, appBar: AppBar(),
          body: const Center(child: Text('Album not found',
              style: TextStyle(color: AppColors.textSecondary))));
    }

    final album = _album!;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(album.title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              background: album.coverUrl != null
                  ? Image.network(album.coverUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
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
                            GestureDetector(
                              onTap: () => context.push('/artist/${album.artistId}'),
                              child: Text(album.artistName,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(height: 4),
                            Text('${album.songCount} songs • ${album.genre}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(formatCurrency(album.price),
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: album.isPurchased
                          ? () {
                              if (album.songs.isNotEmpty) {
                                context.read<PlayerProvider>().setQueue(album.songs);
                              }
                            }
                          : () => context.push('/payment', extra: {
                                'type': 'album',
                                'itemId': album.id,
                                'itemTitle': album.title,
                                'amount': album.price,
                                'artistId': album.artistId,
                              }),
                      icon: Icon(
                          album.isPurchased ? Icons.play_arrow_rounded : Icons.lock_outline),
                      label: Text(album.isPurchased
                          ? l.play
                          : '${l.purchase} • ${formatCurrency(album.price)}'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l.songs,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => SongCard(
                song: album.songs[i],
                onPlay: () {
                  if (album.songs[i].isPurchased) {
                    context.read<PlayerProvider>().setQueue(album.songs, startIndex: i);
                  }
                },
                onBuy: () => context.push('/payment', extra: {
                  'type': 'listen',
                  'itemId': album.songs[i].id,
                  'itemTitle': album.songs[i].title,
                  'amount': album.songs[i].price,
                  'artistId': album.artistId,
                }),
                compact: true,
              ),
              childCount: album.songs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
