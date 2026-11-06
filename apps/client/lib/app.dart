import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/devices/devices_service.dart';
import 'features/home/home_screen.dart';

class SwvertexApp extends StatefulWidget {
  const SwvertexApp({super.key});

  @override
  State<SwvertexApp> createState() => _SwvertexAppState();
}

class _SwvertexAppState extends State<SwvertexApp> {
  final _tokenStorage = const TokenStorage();
  late final _api = ApiClient(_tokenStorage);
  late final _authService = AuthService(_api, _tokenStorage);
  late final _devicesService = DevicesService(_api);

  late Future<bool> _loggedInFuture = _authService.isLoggedIn();

  void _refreshAuthState() {
    setState(() => _loggedInFuture = _authService.isLoggedIn());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWVERTEX CAMERA PROJECTOR',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: FutureBuilder<bool>(
        future: _loggedInFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return HomeScreen(
              authService: _authService,
              devicesService: _devicesService,
              onLoggedOut: _refreshAuthState,
            );
          }
          return LoginScreen(authService: _authService, onLoggedIn: _refreshAuthState);
        },
      ),
    );
  }
}
