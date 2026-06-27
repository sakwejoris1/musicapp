import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/artist_model.dart';

class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artist, required this.onTap});
  final ArtistModel artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.darkCard,
              backgroundImage: artist.avatarUrl != null
                  ? CachedNetworkImageProvider(artist.avatarUrl!)
                  : null,
              child: artist.avatarUrl == null
                  ? Text(
                      artist.artistName.isNotEmpty
                          ? artist.artistName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 28,
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
                  fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${artist.songCount} songs',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
