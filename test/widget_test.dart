import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // 与 main() 一致：Riverpod 需 ProviderScope 包裹；加载动画常驻，pump 固定时长而非 settle
    await tester.pumpWidget(const ProviderScope(child: WarringStatesApp()));
    await tester.pump(const Duration(seconds: 2));

    // 验证应用成功启动，能找到主界面元素
    expect(find.byType(WarringStatesApp), findsOneWidget);
  });
}
