import 'package:hive/hive.dart';

part 'ai_prediction_model.g.dart';

@HiveType(typeId: 10)
class AiPredictionModel {
  @HiveField(0)
  final String date;
  
  @HiveField(1)
  final int prizeType;
  
  @HiveField(2)
  final List<String> predictedNumbers;
  
  @HiveField(3)
  final DateTime generatedAt;

  const AiPredictionModel({
    required this.date,
    required this.prizeType,
    required this.predictedNumbers,
    required this.generatedAt,
  });

  factory AiPredictionModel.fromJson(Map<String, dynamic> json) {
    return AiPredictionModel(
      date: json['date'] as String,
      prizeType: json['prizeType'] as int,
      predictedNumbers: List<String>.from(json['predictedNumbers'] as List),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'prizeType': prizeType,
      'predictedNumbers': predictedNumbers,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  AiPredictionModel copyWith({
    String? date,
    int? prizeType,
    List<String>? predictedNumbers,
    DateTime? generatedAt,
  }) {
    return AiPredictionModel(
      date: date ?? this.date,
      prizeType: prizeType ?? this.prizeType,
      predictedNumbers: predictedNumbers ?? this.predictedNumbers,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiPredictionModel &&
        other.date == date &&
        other.prizeType == prizeType &&
        other.predictedNumbers.toString() == predictedNumbers.toString() &&
        other.generatedAt == generatedAt;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        prizeType.hashCode ^
        predictedNumbers.hashCode ^
        generatedAt.hashCode;
  }
}