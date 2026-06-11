import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WarringStatesApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 验证应用成功启动，能找到主界面元素
    expect(find.byType(WarringStatesApp), findsOneWidget);
  });
}
