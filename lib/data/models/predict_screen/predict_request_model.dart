class PredictRequestModel {
  final String peoplesPrediction;

  const PredictRequestModel({
    required this.peoplesPrediction,
  });

  Map<String, dynamic> toJson() {
    return {
      'peoples_prediction': peoplesPrediction,
    };
  }

  factory PredictRequestModel.fromJson(Map<String, dynamic> json) {
    return PredictRequestModel(
      peoplesPrediction: json['peoples_prediction'] as String,
    );
  }

  @override
  String toString() {
    return 'PredictRequestModel(peoplesPrediction: $peoplesPrediction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictRequestModel &&
        other.peoplesPrediction == peoplesPrediction;
  }

  @override
  int get hashCode => peoplesPrediction.hashCode;
}