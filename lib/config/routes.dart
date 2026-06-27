import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/music/player_screen.dart';
import '../screens/music/song_detail_screen.dart';
import '../screens/music/album_detail_screen.dart';
import '../screens/music/upload_screen.dart';
import '../screens/artist/artist_list_screen.dart';
import '../screens/artist/artist_profile_screen.dart';
import '../screens/artist/artist_dashboard_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/messaging/messages_screen.dart';
import '../screens/messaging/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/library/playlist_detail_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/',
      redirect: (context, state) {
        final authed = auth.isAuthenticated;
        final onAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/';
        if (!authed && !onAuth) return '/login';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/player',
          builder: (_, state) {
            final songId = state.uri.queryParameters['songId'] ?? '';
            return PlayerScreen(songId: songId);
          },
        ),
        GoRoute(
          path: '/song/:id',
          builder: (_, state) => SongDetailScreen(songId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/album/:id',
          builder: (_, state) => AlbumDetailScreen(albumId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/upload', builder: (_, __) => const UploadScreen()),
        GoRoute(path: '/artists', builder: (_, __) => const ArtistListScreen()),
        GoRoute(
          path: '/artist/:id',
          builder: (_, state) => ArtistProfileScreen(artistId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/dashboard', builder: (_, __) => const ArtistDashboardScreen()),
        GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
        GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
        GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        GoRoute(
          path: '/chat/:userId',
          builder: (_, state) {
            final extra = state.extra as Map<String, String>? ?? {};
            return ChatScreen(
              userId: state.pathParameters['userId']!,
              userName: extra['name'] ?? '',
              userAvatar: extra['avatar'],
            );
          },
        ),
        GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
        GoRoute(
          path: '/playlist/:id',
          builder: (_, state) =>
              PlaylistDetailScreen(playlistId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(
          path: '/payment',
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PaymentScreen(
              type: extra['type'] as String? ?? '',
              itemId: extra['itemId'] as String? ?? '',
              itemTitle: extra['itemTitle'] as String? ?? '',
              amount: extra['amount'] as int? ?? 0,
              artistId: extra['artistId'] as String?,
            );
          },
        ),
      ],
    );
