import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/song_card.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/mini_player.dart';
import '../../models/song_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadHome();
      context.read<ShopProvider>().loadProducts();

      context.read<PlayerProvider>().addListener(_onPlayerChange);
    });
  }

  @override
  void dispose() {
    context.read<PlayerProvider>().removeListener(_onPlayerChange);
    super.dispose();
  }

  void _onPlayerChange() {
    final player = context.read<PlayerProvider>();
    final song = player.paymentRequiredSong;
    if (song != null) {
      player.clearPaymentRequired();
      _buyContent(context, song);
    }
  }

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0: break;
      case 1: context.push('/artists'); break;
      case 2: context.push('/shop'); break;
      case 3: context.push('/messages'); break;
      case 4: context.push('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Column(
        children: [
          Expanded(child: _buildBody(context, l, auth)),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: l.home),
          BottomNavigationBarItem(icon: const Icon(Icons.people_outline), label: l.artists),
          BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), label: l.shop),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: l.messages),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: l.profile),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l, AuthProvider auth) {
    final music = context.watch<MusicProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          backgroundColor: AppColors.dark,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Chuyassi',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
              onPressed: () => showSearch(context: context, delegate: _MusicSearch()),
            ),
            if (auth.isArtist)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => context.push('/upload'),
              ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _GreetingBanner(user: auth.user?.fullName ?? ''),
          ),
        ),
        if (!(auth.user?.hasActiveSubscription ?? false))
          SliverToBoxAdapter(
            child: _SubscriptionBanner(onTap: () => context.push('/subscription')),
          ),
        if (music.loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else ...[
          _SectionHeader(title: l.trending, onMore: () {}),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: music.trendingSongs.length,
                itemBuilder: (_, i) => SongCard(
                  song: music.trendingSongs[i],
                  onPlay: () => _playSong(context, music.trendingSongs, i),
                  onBuy: () => _buyContent(context, music.trendingSongs[i]),
                ),
              ),
            ),
          ),
          _SectionHeader(title: l.topArtists, onMore: () => context.push('/artists')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: music.artists.length,
                itemBuilder: (_, i) => ArtistCard(
                  artist: music.artists[i],
                  onTap: () => context.push('/artist/${music.artists[i].id}'),
                ),
              ),
            ),
          ),
          _SectionHeader(title: l.newReleases, onMore: () {}),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => SongCard(
                song: music.songs[i],
                onPlay: () => _playSong(context, music.songs, i),
                onBuy: () => _buyContent(context, music.songs[i]),
                compact: true,
              ),
              childCount: music.songs.length.clamp(0, 20),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }

  void _playSong(BuildContext context, List<SongModel> queue, int index) {
    context.read<PlayerProvider>().setQueue(queue, startIndex: index);
  }

  void _buyContent(BuildContext context, SongModel song) {
    context.push('/payment', extra: {
      'type': 'listen',
      'itemId': song.id,
      'itemTitle': song.title,
      'amount': song.price,
      'artistId': song.artistId,
    });
  }
}

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({required this.user});
  final String user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '🌅 Good Morning' : hour < 18 ? '☀️ Good Afternoon' : '🌙 Good Evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(user.isNotEmpty ? user.split(' ').first : 'Listener',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Go Premium',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text('150 FCFA/day • 3,000 FCFA/month',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: onMore,
              child: const Text('See all',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicSearch extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkCard),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.textSecondary),
        ),
      );

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    context.read<MusicProvider>().search(query);
    return _SearchResults(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length > 2) {
      context.read<MusicProvider>().search(query);
      return _SearchResults(query: query);
    }
    return const Center(
      child: Text('Type to search...', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final results = music.searchResults;
    if (results.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => SongCard(
        song: results[i],
        onPlay: () {},
        compact: true,
      ),
    );
  }
}
