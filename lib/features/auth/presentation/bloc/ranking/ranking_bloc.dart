import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/ranking.dart';
import '../../../data/repositories/ranking_repository.dart';

// Events
abstract class RankingEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetGlobalRanking extends RankingEvent {}

class GetMyRanking extends RankingEvent {}

// States
abstract class RankingState extends Equatable {
  @override
  List<Object> get props => [];
}

class RankingInitial extends RankingState {}

class RankingLoading extends RankingState {}

class RankingLoaded extends RankingState {
  final List<Ranking> rankings;
  final Ranking? myRanking;

  RankingLoaded({required this.rankings, this.myRanking});

  @override
  List<Object> get props => [rankings, myRanking ?? ''];
}

class RankingError extends RankingState {
  final String message;

  RankingError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class RankingBloc extends Bloc<RankingEvent, RankingState> {
  final RankingRepository repository;

  RankingBloc({required this.repository}) : super(RankingInitial()) {
    on<GetGlobalRanking>(_onGetGlobalRanking);
    on<GetMyRanking>(_onGetMyRanking);
  }

  Future<void> _onGetGlobalRanking(
    GetGlobalRanking event,
    Emitter<RankingState> emit,
  ) async {
    emit(RankingLoading());
    final result = await repository.getGlobalRanking();
    result.fold(
      (failure) => emit(RankingError('Erreur lors du chargement du classement')),
      (rankings) => emit(RankingLoaded(rankings: rankings)),
    );
  }

  Future<void> _onGetMyRanking(
    GetMyRanking event,
    Emitter<RankingState> emit,
  ) async {
    emit(RankingLoading());
    final result = await repository.getMyRanking();
    result.fold(
      (failure) => emit(RankingError('Erreur lors du chargement de votre classement')),
      (myRanking) {
        if (state is RankingLoaded) {
          final currentState = state as RankingLoaded;
          emit(RankingLoaded(
            rankings: currentState.rankings,
            myRanking: myRanking,
          ));
        } else {
          emit(RankingLoaded(rankings: [], myRanking: myRanking));
        }
      },
    );
  }
} 