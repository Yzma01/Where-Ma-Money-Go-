import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/repositories/saving_repository.dart';

class SavingBloc extends Bloc<SavingEvent, SavingState> {
  final SavingRepository savingRepository;

  SavingBloc({required this.savingRepository}) : super(SavingInitial()) {
    on<LoadSavings>(_onLoadSavings);
    on<AddSaving>(_onAddSaving);
    on<UpdateSaving>(_onUpdateSaving);
    on<DeleteSaving>(_onDeleteSaving);
  }

  Future<void> _onLoadSavings(
    LoadSavings event,
    Emitter<SavingState> emit,
  ) async {
    emit(SavingLoading());
    try {
      final savings = await savingRepository.getSavings();
      emit(SavingLoaded(savings: savings));
    } catch (e) {
      emit(SavingError(message: e.toString()));
    }
  }

  Future<void> _onAddSaving(AddSaving event, Emitter<SavingState> emit) async {
    try {
      await savingRepository.addSaving(event.saving);
      add(LoadSavings());
    } catch (e) {
      emit(SavingError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSaving(
    UpdateSaving event,
    Emitter<SavingState> emit,
  ) async {
    try {
      await savingRepository.updateSaving(event.saving);
      add(LoadSavings());
    } catch (e) {
      emit(SavingError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSaving(
    DeleteSaving event,
    Emitter<SavingState> emit,
  ) async {
    try {
      await savingRepository.deleteSaving(event.id);
      add(LoadSavings());
    } catch (e) {
      emit(SavingError(message: e.toString()));
    }
  }
}
