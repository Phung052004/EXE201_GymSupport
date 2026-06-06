import 'package:flutter_test/flutter_test.dart';
import 'package:gym_support/main.dart';

void main() {
  testWidgets('GymSupport app starts', (tester) async {
    await tester.pumpWidget(const GymSupportApp());
    expect(find.byType(GymSupportApp), findsOneWidget);
  });
}
