// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:olive_carving/backend_gateway.dart';
import 'package:olive_carving/main.dart';

void main() {
  testWidgets('App boots into splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      const OliveApp(
        backendConfig: BackendConfig(supabaseUrl: '', supabaseAnonKey: ''),
      ),
    );

    expect(find.text('榄雕云艺'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
  });
}
