import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/song_model.dart';
import '../utils/helpers.dart';

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.song,
    required this.onPlay,
    this.onBuy,
    this.compact = false,
  });

  final SongModel song;
  final VoidCallback onPlay;
  final VoidCallback? onBuy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactSongCard(song: song, onPlay: onPlay, onBuy: onBuy);
    return _FullSongCard(song: song, onPlay: onPlay, onBuy: onBuy);
  }
}

class _FullSongCard extends StatelessWidget {
  const _FullSongCard({required this.song, required this.onPlay, this.onBuy});
  final SongModel song;
  final VoidCallback onPlay;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1,
              child: song.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(song.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        song.isPurchased
                            ? '✓ Owned'
                            : formatCurrency(song.price),
                        style: TextStyle(
                          color: song.isPurchased
                              ? AppColors.success
                              : AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: song.isPurchased ? onPlay : onBuy,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          song.isPurchased
                              ? Icons.play_arrow_rounded
                              : Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.darkSurface,
        child: const Icon(Icons.music_note, color: AppColors.textSecondary, size: 40),
      );
}

class _CompactSongCard extends StatelessWidget {
  const _CompactSongCard({required this.song, required this.onPlay, this.onBuy});
  final SongModel song;
  final VoidCallback onPlay;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: song.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: song.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.darkSurface,
                    child: const Icon(Icons.music_note,
                        color: AppColors.textSecondary, size: 20),
                  ),
                )
              : Container(
                  color: AppColors.darkSurface,
                  child: const Icon(Icons.music_note,
                      color: AppColors.textSecondary, size: 20),
                ),
        ),
      ),
      title: Text(song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14)),
      subtitle: Text(
        '${song.artistName} • ${formatDuration(Duration(seconds: song.duration))}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            song.isPurchased ? '✓' : formatCurrency(song.price),
            style: TextStyle(
              color: song.isPurchased ? AppColors.success : AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: song.isPurchased ? onPlay : onBuy,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: song.isPurchased
                    ? AppColors.primary
                    : AppColors.darkSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                song.isPurchased
                    ? Icons.play_arrow_rounded
                    : Icons.lock_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
