import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/probability_screen/probability_response_model.dart';

abstract class ProbabilityState extends Equatable {
  const ProbabilityState();

  @override
  List<Object?> get props => [];
}

class ProbabilityInitial extends ProbabilityState {}

class ProbabilityLoading extends ProbabilityState {}

class ProbabilityLoaded extends ProbabilityState {
  final ProbabilityResponseModel response;

  const ProbabilityLoaded({required this.response});

  @override
  List<Object?> get props => [response];
}

class ProbabilityError extends ProbabilityState {
  final String message;

  const ProbabilityError({required this.message});

  @override
  List<Object?> get props => [message];
}
