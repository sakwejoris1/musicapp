import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/song_card.dart';
import '../../services/api_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<SongModel> _downloads = [];
  List<Map<String, dynamic>> _history = [];
  bool _loadingDownloads = true;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadPlaylists();
    _loadDownloads();
    _loadHistory();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    await context.read<PlaylistProvider>().load();
  }

  Future<void> _loadDownloads() async {
    try {
      final data = await ApiService().getDownloads();
      if (mounted) {
        setState(() {
          _downloads = data
              .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
              .toList();
          _loadingDownloads = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDownloads = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiService().getHistory();
      if (mounted) {
        setState(() {
          _history = data.map((h) => h as Map<String, dynamic>).toList();
          _loadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(l.library),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Playlist',
            onPressed: () => _showCreatePlaylist(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l.playlists),
            Tab(text: l.downloads),
            Tab(text: l.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PlaylistsTab(onCreatePlaylist: () => _showCreatePlaylist(context)),
          _DownloadsTab(
              downloads: _downloads, loading: _loadingDownloads),
          _HistoryTab(history: _history, loading: _loadingHistory),
        ],
      ),
    );
  }

  void _showCreatePlaylist(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isPublic = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Playlist',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: isPublic,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setS(() => isPublic = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('Make public',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    final playlist =
                        await context.read<PlaylistProvider>().createPlaylist(
                              name: name,
                              description: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              isPublic: isPublic,
                            );
                    if (playlist != null && context.mounted) {
                      context.push('/playlist/${playlist.id}');
                    }
                  },
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({required this.onCreatePlaylist});
  final VoidCallback onCreatePlaylist;

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistProvider>().playlists;
    final loading = context.watch<PlaylistProvider>().loading;

    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('No playlists yet',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Playlist'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: playlists.length,
      itemBuilder: (_, i) => _PlaylistTile(playlist: playlists[i]),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist});
  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/playlist/${playlist.id}'),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          image: playlist.coverUrl != null
              ? DecorationImage(
                  image: CachedNetworkImageProvider(playlist.coverUrl!),
                  fit: BoxFit.cover)
              : null,
        ),
        child: playlist.coverUrl == null
            ? const Icon(Icons.queue_music_rounded,
                color: AppColors.primary, size: 28)
            : null,
      ),
      title: Text(playlist.name,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${playlist.songCount} songs • ${playlist.isPublic ? "Public" : "Private"}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
        onPressed: () => _showOptions(context),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final provider = context.read<PlaylistProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded,
                color: AppColors.textSecondary),
            title: const Text('Play',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              if (playlist.songs.isNotEmpty) {
                context.read<PlayerProvider>().setQueue(playlist.songs);
                context.push('/player?songId=${playlist.songs.first.id}');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: AppColors.secondary),
            title: const Text('Delete',
                style: TextStyle(color: AppColors.secondary)),
            onTap: () async {
              Navigator.pop(context);
              await provider.deletePlaylist(playlist.id);
            },
          ),
        ],
      ),
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab(
      {required this.downloads, required this.loading});
  final List<SongModel> downloads;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (downloads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_done_outlined,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No downloads yet',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (_, i) => SongCard(
        song: downloads[i],
        onPlay: () {
          context
              .read<PlayerProvider>()
              .setQueue(downloads, startIndex: i);
          context.push('/player?songId=${downloads[i].id}');
        },
        onBuy: () {},
        compact: true,
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.history, required this.loading});
  final List<Map<String, dynamic>> history;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No listening history',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (_, i) {
        final entry = history[i];
        final song = SongModel.fromJson(
            entry['song'] as Map<String, dynamic>);
        final playedAt = DateTime.tryParse(
                entry['playedAt'] as String? ?? '') ??
            DateTime.now();
        return ListTile(
          onTap: () {
            context.read<PlayerProvider>().setQueue([song]);
            context.push('/player?songId=${song.id}');
          },
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(8),
              image: song.coverUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(song.coverUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: song.coverUrl == null
                ? const Icon(Icons.music_note_rounded,
                    color: AppColors.primary)
                : null,
          ),
          title: Text(song.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500)),
          subtitle: Text(
            '${song.artistName} • ${timeAgo(playedAt)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.play_arrow_rounded,
              color: AppColors.textSecondary, size: 20),
        );
      },
    );
  }
}
