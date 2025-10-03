class PredictResponseModel {
  final String status;
  final List<RepeatedNumber> repeatedNumbers;
  final List<RepeatedSingleDigit> repeatedSingleDigits;
  final List<PeoplesPrediction> peoplesPredictions;
  final List<RepeatedTwoDigit> repeatedTwoDigits;

  const PredictResponseModel({
    required this.status,
    required this.repeatedNumbers,
    required this.repeatedSingleDigits,
    required this.peoplesPredictions,
    this.repeatedTwoDigits = const [],
  });

  factory PredictResponseModel.fromJson(Map<String, dynamic> json) {
    return PredictResponseModel(
      status: json['status'] as String,
      repeatedNumbers: (json['repeated_numbers'] as List)
          .map((e) => RepeatedNumber.fromJson(e as Map<String, dynamic>))
          .toList(),
      repeatedSingleDigits: (json['repeated_single_digits'] as List)
          .map((e) => RepeatedSingleDigit.fromJson(e as Map<String, dynamic>))
          .toList(),
      peoplesPredictions: (json['peoples_predictions'] as List)
          .map((e) => PeoplesPrediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      repeatedTwoDigits: (json['repeated_two_digits'] as List?)
          ?.map((e) => RepeatedTwoDigit.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'repeated_numbers': repeatedNumbers.map((e) => e.toJson()).toList(),
      'repeated_single_digits': repeatedSingleDigits.map((e) => e.toJson()).toList(),
      'peoples_predictions': peoplesPredictions.map((e) => e.toJson()).toList(),
      'repeated_two_digits': repeatedTwoDigits.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PredictResponseModel(status: $status, repeatedNumbers: $repeatedNumbers, repeatedSingleDigits: $repeatedSingleDigits, peoplesPredictions: $peoplesPredictions, repeatedTwoDigits: $repeatedTwoDigits)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictResponseModel &&
        other.status == status &&
        _listEquals(other.repeatedNumbers, repeatedNumbers) &&
        _listEquals(other.repeatedSingleDigits, repeatedSingleDigits) &&
        _listEquals(other.peoplesPredictions, peoplesPredictions) &&
        _listEquals(other.repeatedTwoDigits, repeatedTwoDigits);
  }

  @override
  int get hashCode {
    return status.hashCode ^
        repeatedNumbers.hashCode ^
        repeatedSingleDigits.hashCode ^
        peoplesPredictions.hashCode ^
        repeatedTwoDigits.hashCode;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class RepeatedNumber {
  final String number;
  final int count;

  const RepeatedNumber({
    required this.number,
    required this.count,
  });

  factory RepeatedNumber.fromJson(Map<String, dynamic> json) {
    return RepeatedNumber(
      number: json['number'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'count': count,
    };
  }

  @override
  String toString() {
    return 'RepeatedNumber(number: $number, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepeatedNumber &&
        other.number == number &&
        other.count == count;
  }

  @override
  int get hashCode {
    return number.hashCode ^ count.hashCode;
  }
}

class RepeatedSingleDigit {
  final String digit;
  final int count;

  const RepeatedSingleDigit({
    required this.digit,
    required this.count,
  });

  factory RepeatedSingleDigit.fromJson(Map<String, dynamic> json) {
    return RepeatedSingleDigit(
      digit: json['digit'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'digit': digit,
      'count': count,
    };
  }

  @override
  String toString() {
    return 'RepeatedSingleDigit(digit: $digit, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepeatedSingleDigit &&
        other.digit == digit &&
        other.count == count;
  }

  @override
  int get hashCode {
    return digit.hashCode ^ count.hashCode;
  }
}

class PeoplesPrediction {
  final String digit;
  final int count;

  const PeoplesPrediction({
    required this.digit,
    required this.count,
  });

  factory PeoplesPrediction.fromJson(Map<String, dynamic> json) {
    return PeoplesPrediction(
      digit: json['digit'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'digit': digit,
      'count': count,
    };
  }

  @override
  String toString() {
    return 'PeoplesPrediction(digit: $digit, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeoplesPrediction &&
        other.digit == digit &&
        other.count == count;
  }

  @override
  int get hashCode {
    return digit.hashCode ^ count.hashCode;
  }
}

class RepeatedTwoDigit {
  final String digits;
  final int count;

  const RepeatedTwoDigit({
    required this.digits,
    required this.count,
  });

  factory RepeatedTwoDigit.fromJson(Map<String, dynamic> json) {
    return RepeatedTwoDigit(
      digits: json['digits'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'digits': digits,
      'count': count,
    };
  }

  @override
  String toString() {
    return 'RepeatedTwoDigit(digits: $digits, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepeatedTwoDigit &&
        other.digits == digits &&
        other.count == count;
  }

  @override
  int get hashCode {
    return digits.hashCode ^ count.hashCode;
  }
}
