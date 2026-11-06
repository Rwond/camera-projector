import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/core/api_client.dart';
import 'package:swvertex_camera_projector/core/token_storage.dart';
import 'package:swvertex_camera_projector/features/auth/auth_service.dart';
import 'package:swvertex_camera_projector/features/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders the email/password fields and the login button', (tester) async {
    final authService = AuthService(ApiClient(const TokenStorage()), const TokenStorage());

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: authService, onLoggedIn: () {}),
      ),
    );

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
