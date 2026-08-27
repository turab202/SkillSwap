import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/profile/screens/profile_setup_screen.dart';
import 'features/profile/screens/user_profile_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/discover/screens/discover_screen.dart';
import 'features/discover/screens/ai_match_screen.dart';
import 'features/create/screens/create_post_screen.dart';
import 'features/community/screens/community_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/collaborations/screens/collaborations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SkillSwapApp()));
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Swap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/auth': (_) => const AuthScreen(),
        '/profile-setup': (_) => const ProfileSetupScreen(),
        '/home': (_) => const HomeScreen(),
        '/discover': (_) => const DiscoverScreen(),
        '/ai-match': (_) => const AiMatchScreen(),
        '/create': (_) => const CreatePostScreen(),
        '/community': (_) => const CommunityScreen(),
        '/chat-list': (_) => const ChatListScreen(),
        '/chat': (_) => const ChatScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/user-profile': (_) => const UserProfileScreen(),
        '/profile-view': (_) => const UserProfileScreen(),
        '/collaborations': (_) => const CollaborationsScreen(),
      },
    );
  }
}
