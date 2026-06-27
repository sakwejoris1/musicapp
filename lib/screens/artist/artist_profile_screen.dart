import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/artist_model.dart';
import '../../models/song_model.dart';
import '../../models/album_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/song_card.dart';
import '../../services/api_service.dart';

class ArtistProfileScreen extends StatefulWidget {
  const ArtistProfileScreen({super.key, required this.artistId});
  final String artistId;
  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  ArtistModel? _artist;
  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final music = context.read<MusicProvider>();
    final artist = await music.getArtist(widget.artistId);
    final songs =
        music.songs.where((s) => s.artistId == widget.artistId).toList();
    List<AlbumModel> albums = [];
    try {
      final data = await ApiService().getAlbums(artistId: widget.artistId);
      albums = data
          .map((a) => AlbumModel.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _artist = artist;
      _songs = songs;
      _albums = albums;
      _loading = false;
    });
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

    if (_artist == null) {
      return Scaffold(
          backgroundColor: AppColors.dark,
          appBar: AppBar(),
          body: const Center(
              child: Text('Artist not found',
                  style: TextStyle(color: AppColors.textSecondary))));
    }

    final artist = _artist!;
    final isFollowing = music.isFollowing(artist.id);

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  artist.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: artist.coverUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.dark.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  // Profile row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: artist.avatarUrl != null
                            ? CachedNetworkImageProvider(artist.avatarUrl!)
                            : null,
                        child: artist.avatarUrl == null
                            ? Text(
                                artist.artistName[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(artist.artistName,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700)),
                                ),
                                if (artist.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded,
                                      color: AppColors.primary, size: 16),
                                ],
                              ],
                            ),
                            Text(artist.fullName,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCol(
                          label: l.songs, value: '${artist.songCount}'),
                      _StatCol(
                          label: l.albums, value: '${artist.albumCount}'),
                      _StatCol(
                          label: l.totalListens,
                          value: _compact(artist.totalListens)),
                      _StatCol(
                          label: 'Followers',
                          value: _compact(artist.followerCount)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              music.toggleFollowArtist(artist.id),
                          icon: Icon(
                            isFollowing
                                ? Icons.person_remove_outlined
                                : Icons.person_add_outlined,
                            size: 18,
                          ),
                          label: Text(isFollowing ? 'Following' : 'Follow'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? AppColors.darkSurface
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                            '/chat/${artist.userId}',
                            extra: {
                              'name': artist.artistName,
                              'avatar': artist.avatarUrl
                            }),
                        icon: const Icon(Icons.message_outlined,
                            color: AppColors.textSecondary, size: 18),
                        label: const Text('Message',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.textSecondary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showSupport(context, artist),
                        icon: const Icon(Icons.volunteer_activism_outlined,
                            color: AppColors.secondary, size: 18),
                        label: Text(l.support,
                            style: const TextStyle(
                                color: AppColors.secondary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.secondary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  if (artist.bio != null && artist.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(artist.bio!,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5)),
                  ],
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tab,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: 'Songs'),
                      Tab(text: 'Albums'),
                      Tab(text: 'About'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _SongsTab(songs: _songs, artistId: artist.id),
            _AlbumsTab(albums: _albums),
            _AboutTab(artist: artist),
          ],
        ),
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _showSupport(BuildContext context, ArtistModel artist) {
    int amount = 500;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Support ${artist.artistName}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 20),
              Text(formatCurrency(amount),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
              Slider(
                value: amount.toDouble(),
                min: 100,
                max: 10000,
                divisions: 99,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => amount = v.round()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/payment', extra: {
                      'type': 'support',
                      'itemId': artist.id,
                      'itemTitle': artist.artistName,
                      'amount': amount,
                      'artistId': artist.id,
                    });
                  },
                  child: Text('Send ${formatCurrency(amount)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongsTab extends StatelessWidget {
  const _SongsTab({required this.songs, required this.artistId});
  final List<SongModel> songs;
  final String artistId;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
          child: Text('No songs yet',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: songs.length,
      itemBuilder: (_, i) => SongCard(
        song: songs[i],
        onPlay: () {
          if (songs[i].isPurchased) {
            context.read<PlayerProvider>().setQueue(songs, startIndex: i);
            context.push('/player?songId=${songs[i].id}');
          }
        },
        onBuy: () => context.push('/payment', extra: {
          'type': 'listen',
          'itemId': songs[i].id,
          'itemTitle': songs[i].title,
          'amount': songs[i].price,
          'artistId': artistId,
        }),
        compact: true,
      ),
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab({required this.albums});
  final List<AlbumModel> albums;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(
          child: Text('No albums yet',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (_, i) {
        final album = albums[i];
        return GestureDetector(
          onTap: () => context.push('/album/${album.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: album.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: album.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity)
                        : Container(
                            color: AppColors.darkSurface,
                            child: const Icon(Icons.album_rounded,
                                color: AppColors.primary, size: 48)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text('${album.songCount} songs',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.artist});
  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (artist.bio != null && artist.bio!.isNotEmpty) ...[
            const Text('Biography',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(artist.bio!,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6)),
            const SizedBox(height: 20),
          ],
          const Text('Contact & Payment',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_android_outlined,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${artist.paymentMethod.replaceAll('_', ' ').toUpperCase()}: ${artist.paymentPhone}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
