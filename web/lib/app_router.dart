import 'package:go_router/go_router.dart';
import 'package:web_admin/providers/user_data_provider.dart';
import 'package:web_admin/views/screens/buttons_screen.dart';
import 'package:web_admin/views/screens/colors_screen.dart';
import 'package:web_admin/views/screens/crud_detail_feature_screen.dart';
import 'package:web_admin/views/screens/crud_detail_screen.dart';
import 'package:web_admin/views/screens/create_user_screen.dart';
import 'package:web_admin/views/screens/create_tag_screen.dart';
import 'package:web_admin/views/screens/create_feature_screen.dart';
import 'package:web_admin/views/screens/crud_detail_user_screen.dart';
import 'package:web_admin/views/screens/crud_detail_tag_screen.dart';
import 'package:web_admin/views/screens/crud_screen.dart';
import 'package:web_admin/views/screens/dashboard_screen.dart';
import 'package:web_admin/views/screens/dialogs_screen.dart';
import 'package:web_admin/views/screens/error_screen.dart';
import 'package:web_admin/views/screens/form_screen.dart';
import 'package:web_admin/views/screens/general_ui_screen.dart';
import 'package:web_admin/views/screens/iframe_demo_screen.dart';
import 'package:web_admin/views/screens/login_screen.dart';
import 'package:web_admin/views/screens/logout_screen.dart';
import 'package:web_admin/views/screens/logs_screen.dart';
import 'package:web_admin/views/screens/my_profile_screen.dart';
import 'package:web_admin/views/screens/register_screen.dart';
import 'package:web_admin/views/screens/text_screen.dart';
import 'package:web_admin/views/screens/users_screen.dart';
import 'package:web_admin/views/screens/servers_screen.dart';
import 'package:web_admin/views/screens/tags_screen.dart';
import 'package:web_admin/views/screens/features_flipping_screen.dart';

class RouteUri {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String servers = '/servers';
  static const String tags = '/tags';
  static const String featuresFlipping = '/features-flipping';
  static const String logs = '/logs';
  static const String myProfile = '/my-profile';
  static const String logout = '/logout';
  static const String form = '/form';
  static const String generalUi = '/general-ui';
  static const String colors = '/colors';
  static const String text = '/text';
  static const String buttons = '/buttons';
  static const String dialogs = '/dialogs';
  static const String error404 = '/404';
  static const String login = '/login';
  static const String register = '/register';
  static const String crud = '/crud';
  static const String crudDetail = '/crud-detail';
  static const String createUser = '/create-user';
  static const String createTag = '/create-tag';
  static const String createFeature = '/create-feature';
  static const String crudDetailUser = '/user-detail';
  static const String crudDetailTag = '/tag-detail';
  static const String crudDetailFeature = '/feature-detail';
  static const String iframe = '/iframe';
}

const List<String> unrestrictedRoutes = [
  RouteUri.error404,
  RouteUri.logout,
  RouteUri.login, // Remove this line for actual authentication flow.
  RouteUri.register, // Remove this line for actual authentication flow.
];

const List<String> publicRoutes = [
  // RouteUri.login, // Enable this line for actual authentication flow.
  // RouteUri.register, // Enable this line for actual authentication flow.
];

GoRouter appRouter(UserDataProvider userDataProvider) {
  return GoRouter(
    initialLocation: RouteUri.home,
    errorPageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: const ErrorScreen(),
    ),
    routes: [
      GoRoute(
        path: RouteUri.home,
        redirect: (context, state) => RouteUri.dashboard,
      ),
      GoRoute(
        path: RouteUri.dashboard,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.users,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const UsersScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.servers,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ServersScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.tags,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const TagsScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.featuresFlipping,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const FeaturesFlippingScreen(),
        ),
      ),GoRoute(
        path: RouteUri.logs,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LogsScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.myProfile,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const MyProfileScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.logout,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LogoutScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.login,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RouteUri.createUser,
        pageBuilder: (context, state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: CreateUserScreen(id: state.uri.queryParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: RouteUri.createTag,
        pageBuilder: (context, state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: CreateTagScreen(id: state.uri.queryParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: RouteUri.createFeature,
        pageBuilder: (context, state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: CreateFeatureScreen(id: state.uri.queryParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: RouteUri.crudDetailUser,
        pageBuilder: (context, state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: CrudDetailUserScreen(id: state.uri.queryParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: RouteUri.crudDetailTag,
        pageBuilder: (context, state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: CrudDetailTagScreen(id: state.uri.queryParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: RouteUri.crudDetailFeature,
        pageBuilder: (context, state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: CrudDetailFeatureScreen(id: state.uri.queryParameters['id'] ?? ''),
          );
        },
      ),
    ],
    redirect: (context, state) {
      if (unrestrictedRoutes.contains(state.matchedLocation)) {
        return null;
      } else if (publicRoutes.contains(state.matchedLocation)) {
        // Is public route.
        if (userDataProvider.isUserLoggedIn()) {
          // User is logged in, redirect to home page.
          return RouteUri.home;
        }
      } else {
        // Not public route.
        if (!userDataProvider.isUserLoggedIn()) {
          // User is not logged in, redirect to login page.
          return RouteUri.login;
        }
      }

      return null;
    },
  );
}
