import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_pairs/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 在测试运行前模拟 SharedPreferences 的初始值
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Harmony Pairs launch screen smoke test', (WidgetTester tester) async {
    // 构建我们的应用并触发一帧。
    // 注意：这里使用的是 HarmonyPairsRoot 而不是 MyApp
    await tester.pumpWidget(const HarmonyPairsRoot());

    // 验证应用标题是否存在
    expect(find.text('Harmony Pairs'), findsOneWidget);

    // 验证“Begin”按钮是否存在
    expect(find.text('Begin'), findsOneWidget);

    // 验证默认选中的关卡（根据你的代码默认是 Maestro）
    expect(find.text('Maestro'), findsOneWidget);

    // 验证此时不应该有 "0" 这种计数器文本（之前的错误测试点）
    expect(find.text('0'), findsNothing);
  });
}