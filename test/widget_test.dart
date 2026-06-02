import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login screen when no stored session exists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initialize();

    await tester.pumpWidget(const PharmacyLoginApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Pharmacy WMS'), findsNWidgets(2));
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
