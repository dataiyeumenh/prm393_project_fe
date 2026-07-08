import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_project_fe/main.dart';
import 'package:prm393_project_fe/state/cart_state.dart';

void main() {
  testWidgets('App boots and renders the login screen', (tester) async {
    final cart = CartState();
    await tester.pumpWidget(PawFuelApp(cartState: cart));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đăng nhập'), findsWidgets);
  });
}