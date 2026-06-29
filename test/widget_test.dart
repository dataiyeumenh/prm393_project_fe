import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_project_fe/main.dart';

void main() {
  testWidgets('App boots and renders the login screen', (tester) async {
    await tester.pumpWidget(const PawFuelApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('WELCOME\nBACK.'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}