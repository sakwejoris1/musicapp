import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/music_provider.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});
  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<MusicProvider>().loadHome());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final music = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(title: Text(l.artists)),
      body: music.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 20,
                childAspectRatio: 0.75,
              ),
              itemCount: music.artists.length,
              itemBuilder: (_, i) {
                final artist = music.artists[i];
                return GestureDetector(
                  onTap: () => context.push('/artist/${artist.id}'),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: artist.avatarUrl != null
                            ? NetworkImage(artist.avatarUrl!)
                            : null,
                        child: artist.avatarUrl == null
                            ? Text(
                                artist.artistName.isNotEmpty
                                    ? artist.artistName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                      Text(
                        '${artist.songCount} songs',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
