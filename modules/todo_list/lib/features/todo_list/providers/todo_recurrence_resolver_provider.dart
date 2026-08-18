import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/recurrence_date_calculator.dart';
import '../services/todo_recurrence_resolver.dart';

/// 注入循环日期计算引擎。
final recurrenceDateCalculatorProvider =
    Provider<RecurrenceDateCalculator>((ref) => const RecurrenceDateCalculator());

/// 注入多规则合并解析器。
final todoRecurrenceResolverProvider =
    Provider<TodoRecurrenceResolver>((ref) {
  return TodoRecurrenceResolver(
    calculator: ref.watch(recurrenceDateCalculatorProvider),
  );
});