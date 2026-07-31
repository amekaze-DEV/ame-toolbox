/// 一条计算记录。
class Calculation {
  const Calculation({
    required this.expression,
    required this.result,
    this.timestamp,
  });

  final String expression;
  final String result;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'timestamp': timestamp?.toIso8601String(),
      };

  factory Calculation.fromJson(Map<String, dynamic> json) => Calculation(
        expression: json['expression'] as String,
        result: json['result'] as String,
        timestamp: json['timestamp'] == null
            ? null
            : DateTime.tryParse(json['timestamp'] as String),
      );
}
